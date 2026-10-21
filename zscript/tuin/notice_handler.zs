// Play-scope notice detection and queue, ported from Tuin-Doom-Enhanced
// p_notices.c / key_notice.h / completion_notices.h (GPL-3.0).

class TuinNotice play
{
	String title, subtitle;
	Name tint;
	int style, priority;
	int startTic;	// level.maptime when it became visible; -1 while queued
	int playerNum;
}

// Rides along in the player's inventory so first-weapon discovery and variant
// cycling survive level changes (event handlers are recreated per level).
class TuinNoticeMemory : Inventory
{
	Array<Name> seen;
	int variants[TN_COUNT + 1];	// last slot cycles key pickups

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
	}
}

// Per-player, per-level detection state. Serialized with the handler.
class TuinNoticeProgress play
{
	const POWER_COUNT = 5;

	bool seeded;
	Array<Name> seenKeys;
	bool powerHeld[POWER_COUNT];
	int powerTics[POWER_COUNT];
	int secretCount;

	bool closeCallArmed;
	int lastDamage;
	int awardTic[4];	// combat slots: close, chain, multi, fists; maptime + 1, 0 = never

	int groupTic, groupKills, chainTic, chainKills;
	Actor group;
}

class TuinNoticeHandler : EventHandler
{
	const NOTICE_LIFETIME = 112;
	const MAX_VISIBLE = 5;
	const CLOSE_CALL_DELAY = 35 * 5;
	const CLOSE_CALL_EXPIRY = 35 * 20;
	const CLOSE_CALL_RANGE = 1024;
	const COMBAT_COOLDOWN = 35 * 20;
	const PICKUP_SLACK = 32;

	const SLOT_CLOSE = 0;
	const SLOT_CHAIN = 1;
	const SLOT_MULTI = 2;
	const SLOT_FISTS = 3;

	static const Name PowerNames[] =
	{
		'PowerInvulnerable', 'PowerStrength', 'PowerInvisibility', 'PowerIronFeet', 'PowerLightAmp'
	};
	static const int PowerKinds[] =
	{
		TN_INVULN, TN_BERSERK, TN_INVIS, TN_RADSUIT, TN_VISOR
	};

	Array<TuinNotice> notices;
	bool tookDamage[MAXPLAYERS];

	TuinNoticeProgress pstate[MAXPLAYERS];
	int fallbackVariants[TN_COUNT + 1];
	bool baselined;
	int completionAwarded;
	bool allmapSeen;
	bool levelEnding;

	// ---- queue --------------------------------------------------------

	void Push(int playerNum, String title, String subtitle, Name tint, int style, int priority)
	{
		if (!UserFlag(playerNum, 'tuin_notices'))
			return;
		let n = new("TuinNotice");
		n.title = title;
		n.subtitle = subtitle;
		n.tint = tint;
		n.style = style;
		n.priority = priority;
		n.startTic = -1;
		n.playerNum = playerNum;
		notices.Push(n);
	}

	bool KindAllowed(int playerNum, int kind, bool ignoreCombatFilter)
	{
		if (kind < 0 || kind >= TN_COUNT || !UserFlag(playerNum, 'tuin_notices'))
			return false;
		return ignoreCombatFilter || !TuinNoticeCatalog.IsCombat(kind) || UserFlag(playerNum, 'tuin_notice_combat');
	}

	void PushKind(int playerNum, int kind, bool ignoreCombatFilter = false)
	{
		if (!KindAllowed(playerNum, kind, ignoreCombatFilter))
			return;
		int variant = NextVariant(playerNum, kind);
		Push(playerNum, TuinNoticeCatalog.Title(kind, variant), TuinNoticeCatalog.Subtitle(kind),
			TuinNoticeCatalog.TintName(kind), TuinNoticeCatalog.Style(kind), TuinNoticeCatalog.Priority(kind));
	}

	// colorIndex 0 blue / 1 yellow / 2 red; negative = non-vanilla key named by tag.
	void PushKey(int playerNum, int colorIndex, bool skull, String tag)
	{
		if (!UserFlag(playerNum, 'tuin_notices'))
			return;
		int variant = NextVariant(playerNum, TN_COUNT);
		String title = colorIndex >= 0 ? TuinNoticeCatalog.KeyTitle(colorIndex, skull) : TuinNoticeCatalog.GenericKeyTitle(tag);
		Name tint = colorIndex >= 0 ? TuinNoticeCatalog.KeyTintName(colorIndex) : 'TuinGold';
		Push(playerNum, title, TuinNoticeCatalog.KeySubtitle(variant), tint, 0, 0);
	}

	// vanillaIndex as returned by TuinNoticeCatalog.VanillaWeaponIndex, or -1 to name it by tag.
	void PushWeapon(int playerNum, int vanillaIndex, String tag)
	{
		if (!UserFlag(playerNum, 'tuin_notices'))
			return;
		int variant = NextVariant(playerNum, TN_WEAPON);
		String weaponName = tag.MakeUpper();
		Name tint = 'TuinGold';
		if (vanillaIndex >= 0)
		{
			weaponName = TuinNoticeCatalog.VanillaWeaponName(vanillaIndex);
			tint = TuinNoticeCatalog.WeaponTintName(vanillaIndex);
		}
		Push(playerNum, TuinNoticeCatalog.WeaponTitle(weaponName, variant),
			TuinNoticeCatalog.WeaponSubtitle(vanillaIndex == 6, variant), tint,
			TuinNoticeCatalog.Style(TN_WEAPON), TuinNoticeCatalog.Priority(TN_WEAPON));
	}

	// Per player: started notices first in their existing order, then queued
	// ones by priority (stable); expired ones dropped; first MAX_VISIBLE start.
	void UpdateQueue()
	{
		if (notices.Size() == 0)
			return;

		Array<int> owners;
		for (int i = 0; i < notices.Size(); i++)
		{
			int p = notices[i].playerNum;
			if (owners.Find(p) == owners.Size())
				owners.Push(p);
		}

		Array<TuinNotice> ordered;
		foreach (p : owners)
		{
			if (p < 0 || p >= MAXPLAYERS || !playeringame[p])
				continue;

			int blockStart = ordered.Size();
			Array<TuinNotice> queued;
			foreach (n : notices)
			{
				if (n.playerNum != p)
					continue;
				if (n.startTic >= 0)
				{
					if (level.maptime - n.startTic < NOTICE_LIFETIME)
						ordered.Push(n);
					continue;
				}
				int at = 0;
				while (at < queued.Size() && queued[at].priority >= n.priority)
					at++;
				queued.Insert(at, n);
			}
			foreach (n : queued)
				ordered.Push(n);

			int visible = min(MAX_VISIBLE, ordered.Size() - blockStart);
			for (int k = 0; k < visible; k++)
			{
				if (ordered[blockStart + k].startTic < 0)
					ordered[blockStart + k].startTic = level.maptime;
			}
		}
		notices.Copy(ordered);
	}

	// ---- helpers ------------------------------------------------------

	bool UserFlag(int playerNum, Name cvarName)
	{
		if (playerNum < 0 || playerNum >= MAXPLAYERS)
			return false;
		CVar cv = CVar.GetCVar(cvarName, players[playerNum]);
		return cv == null || cv.GetInt() != 0;
	}

	TuinNoticeProgress StateOf(int playerNum)
	{
		if (pstate[playerNum] == null)
			pstate[playerNum] = new("TuinNoticeProgress");
		return pstate[playerNum];
	}

	TuinNoticeMemory MemoryOf(int playerNum)
	{
		let pmo = players[playerNum].mo;
		if (pmo == null)
			return null;
		let mem = TuinNoticeMemory(pmo.FindInventory("TuinNoticeMemory"));
		if (mem == null)
			mem = TuinNoticeMemory(pmo.GiveInventoryType("TuinNoticeMemory"));
		return mem;
	}

	int NextVariant(int playerNum, int slot)
	{
		let mem = MemoryOf(playerNum);
		int variant;
		if (mem != null)
		{
			variant = mem.variants[slot] % 3;
			mem.variants[slot]++;
		}
		else
		{
			variant = fallbackVariants[slot] % 3;
			fallbackVariants[slot]++;
		}
		return variant;
	}

	// True if cls is baseName or a subclass, or replaces it (so mods that
	// swap out vanilla actors still match).
	static bool ClassIsOrReplaces(class<Actor> cls, class<Actor> baseCls)
	{
		if (cls == null || baseCls == null)
			return false;
		if (cls is baseCls)
			return true;
		class<Actor> replacee = Actor.GetReplacee(cls);
		return replacee != null && replacee is baseCls;
	}

	// Returns the colour index (0 blue, 1 yellow, 2 red) or -1 for a non-vanilla key.
	static int KeyColorIndex(class<Actor> cls, out bool skull)
	{
		skull = false;
		if (ClassIsOrReplaces(cls, "BlueCard")) return 0;
		if (ClassIsOrReplaces(cls, "YellowCard")) return 1;
		if (ClassIsOrReplaces(cls, "RedCard")) return 2;
		skull = true;
		if (ClassIsOrReplaces(cls, "BlueSkull")) return 0;
		if (ClassIsOrReplaces(cls, "YellowSkull")) return 1;
		if (ClassIsOrReplaces(cls, "RedSkull")) return 2;
		skull = false;
		return -1;
	}

	// Nearest player whose body could have just touched the (now picked-up) thing.
	int NearestToucher(Actor thing)
	{
		int best = -1;
		double bestDist = 0;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;
			let pmo = players[i].mo;
			if (pmo == null || pmo.health <= 0)
				continue;
			double dist = thing.Distance2D(pmo);
			if (dist > thing.radius + pmo.radius + PICKUP_SLACK)
				continue;
			if (thing.pos.z >= pmo.pos.z + pmo.height || thing.pos.z + thing.height <= pmo.pos.z)
				continue;
			if (best < 0 || dist < bestDist)
			{
				best = i;
				bestDist = dist;
			}
		}
		return best;
	}

	// ---- events -------------------------------------------------------

	override void WorldLoaded(WorldEvent e)
	{
		levelEnding = false;
		if (e.IsSaveGame || gamestate == GS_TITLELEVEL)
			return;
		if (!UserFlag(consoleplayer, 'tuin_debug_preview'))
			return;

		for (int kind = TN_CYBER; kind < TN_COUNT; kind++)
			PushKind(consoleplayer, kind, true);
		PushKey(consoleplayer, 0, false, "");
		PushWeapon(consoleplayer, 6, "");
	}

	override void WorldUnloaded(WorldEvent e)
	{
		levelEnding = true;
		// EXIT-NOTICES
		// Static handlers also get an empty NextMap when a new game or save replaces
		// the level; only a real exit through ChangeLevel carries the next map name.
		if (e.NextMap == "" || e.IsSaveGame || gamestate == GS_TITLELEVEL)
			return;
		let relay = TuinExitRelay(StaticEventHandler.Find('TuinExitRelay'));
		if (relay == null)
			return;
		relay.ClearAll();

		bool secretExit = level.NextSecretMap != "" && e.NextMap ~== level.NextSecretMap
			&& !(e.NextMap ~== level.NextMap);

		int kills, items, secrets;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;
			kills += players[i].killcount;
			items += players[i].itemcount;
			secrets += players[i].secretcount;
		}
		bool anyTotal = level.total_monsters + level.total_items + level.total_secrets > 0;
		bool complete = anyTotal && kills >= level.total_monsters
			&& items >= level.total_items && secrets >= level.total_secrets;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;
			bool preview = UserFlag(i, 'tuin_debug_preview');
			bool perfect = complete && players[i].mo != null && players[i].health > 0 && !tookDamage[i];
			if (preview || perfect)
				SendExit(relay, i, TN_PERFECT);
			if (preview || secretExit)
				SendExit(relay, i, TN_EXIT);
		}
	}

	void SendExit(TuinExitRelay relay, int playerNum, int kind)
	{
		if (!KindAllowed(playerNum, kind, UserFlag(playerNum, 'tuin_debug_preview')))
			return;
		relay.Add(playerNum, TuinNoticeCatalog.Title(kind, NextVariant(playerNum, kind)), TuinNoticeCatalog.Subtitle(kind),
			TuinNoticeCatalog.TintName(kind), TuinNoticeCatalog.Style(kind), TuinNoticeCatalog.Priority(kind));
	}

	override void PlayerEntered(PlayerEvent e)
	{
		StateOf(e.PlayerNumber).seeded = false;
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		StateOf(e.PlayerNumber).seeded = false;
	}

	override void WorldThingDestroyed(WorldEvent e)
	{
		let thing = e.Thing;
		if (levelEnding || gamestate != GS_LEVEL || !(thing is "Inventory"))
			return;

		int kind;
		class<Actor> cls = thing.GetClass();
		if (ClassIsOrReplaces(cls, "Soulsphere"))
			kind = TN_SOUL;
		else if (ClassIsOrReplaces(cls, "Megasphere"))
			kind = TN_MEGA;
		else
			return;

		int taker = NearestToucher(thing);
		if (taker >= 0)
			PushKind(taker, kind);
	}

	// Fires once per death with the real source and inflictor, before Die()
	// runs. WorldThingDied has no source, and Die() only overwrites target
	// when a source exists, so it can misattribute scripted deaths.
	override void WorldThingDamaged(WorldEvent e)
	{
		let target = e.Thing;
		if (target == null)
			return;

		if (target.player != null)
		{
			if (target.player.mo == target && e.Damage > 0)
				OnPlayerDamaged(target, e.DamageSource);
			return;
		}
		if (target.health <= 0)
			OnKill(target, e.Inflictor, e.DamageSource);
	}

	void OnPlayerDamaged(Actor victim, Actor source)
	{
		int pnum = victim.PlayerNumber();
		let pr = StateOf(pnum);
		tookDamage[pnum] = true;
		pr.lastDamage = level.maptime;
		pr.closeCallArmed = victim.health > 0 && victim.health < 10
			&& source != null && source != victim && source.bCountKill;
	}

	bool AwardCombat(int playerNum, int slot, int kind)
	{
		if (!UserFlag(playerNum, 'tuin_notice_combat'))
			return false;
		let pr = StateOf(playerNum);
		int last = pr.awardTic[slot];
		if (last != 0 && level.maptime - last < COMBAT_COOLDOWN)
			return false;
		pr.awardTic[slot] = level.maptime + 1;
		PushKind(playerNum, kind);
		return true;
	}

	void OnKill(Actor target, Actor inflictor, Actor source)
	{
		if (source == null || source.player == null || !target.CountsAsKill())
			return;
		int pnum = source.PlayerNumber();
		let pr = StateOf(pnum);

		class<Actor> cls = target.GetClass();
		if (ClassIsOrReplaces(cls, "Cyberdemon"))
			PushKind(pnum, TN_CYBER);
		if (ClassIsOrReplaces(cls, "SpiderMastermind"))
			PushKind(pnum, TN_SPIDER);

		// Hitscan and melee hits are inflicted by a per-hit puff, not the attacker.
		bool viaPuff = inflictor != null && inflictor.bIsPuff && inflictor.target == source;

		let weap = source.player.ReadyWeapon;
		bool meleeWeapon = weap != null && (ClassIsOrReplaces(weap.GetClass(), "Fist")
			|| (weap.bMeleeWeapon && !ClassIsOrReplaces(weap.GetClass(), "Chainsaw")));
		if ((inflictor == source || viaPuff) && meleeWeapon && target.SpawnHealth() >= 150)
			AwardCombat(pnum, SLOT_FISTS, TN_FISTS);

		// A volley or blast resolves within one tic; group by attack, not by time window.
		Actor groupKey = viaPuff ? source : inflictor;
		if (pr.groupTic != level.maptime || pr.group != groupKey)
		{
			pr.groupTic = level.maptime;
			pr.group = groupKey;
			pr.groupKills = 0;
		}
		if (++pr.groupKills == 3)
			AwardCombat(pnum, SLOT_MULTI, TN_MULTI);

		if (inflictor != null && ClassIsOrReplaces(inflictor.GetClass(), "ExplosiveBarrel"))
		{
			if (pr.chainTic != level.maptime)
			{
				pr.chainTic = level.maptime;
				pr.chainKills = 0;
			}
			if (++pr.chainKills == 3)
				AwardCombat(pnum, SLOT_CHAIN, TN_CHAIN);
		}
	}

	// ---- per-tick detection ----------------------------------------------

	override void WorldTick()
	{
		if (gamestate == GS_TITLELEVEL)
			return;

		// Completion first so a same-tic ALL SECRETS can suppress the plain secret notice.
		int earned = UpdateCompletion();

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || players[i].mo == null)
				continue;
			let pr = StateOf(i);
			if (!pr.seeded)
			{
				SeedPlayer(i);
				continue;
			}
			TickKeys(i);
			TickWeapons(i);
			TickPowerups(i);
			TickSecrets(i, earned);
			TickCloseCall(i);
		}

		TickAllmap();

		for (int n = 0; n < 4; n++)
		{
			if (!(earned & (1 << n)))
				continue;
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				if (playeringame[i])
					PushKind(i, TN_KILLS + n);
			}
		}

		baselined = true;
		UpdateQueue();
	}

	void SeedPlayer(int i)
	{
		let pr = StateOf(i);
		let pmo = players[i].mo;
		pr.seeded = true;
		pr.secretCount = players[i].secretcount;

		pr.seenKeys.Clear();
		for (Inventory it = pmo.Inv; it != null; it = it.Inv)
		{
			if (it is "Key")
				pr.seenKeys.Push(it.GetClassName());
		}

		for (int k = 0; k < TuinNoticeProgress.POWER_COUNT; k++)
		{
			let pw = Powerup(pmo.FindInventory(PowerNames[k], true));
			pr.powerHeld[k] = pw != null;
			pr.powerTics[k] = pw != null ? pw.EffectTics : 0;
		}

		// Weapons held at level start never announce, but stay remembered.
		let mem = MemoryOf(i);
		if (mem == null)
			return;
		for (Inventory it = pmo.Inv; it != null; it = it.Inv)
		{
			if (it is "Weapon" && mem.seen.Find(it.GetClassName()) == mem.seen.Size())
				mem.seen.Push(it.GetClassName());
		}
	}

	void TickKeys(int i)
	{
		let pr = StateOf(i);
		for (Inventory it = players[i].mo.Inv; it != null; it = it.Inv)
		{
			if (!(it is "Key") || pr.seenKeys.Find(it.GetClassName()) != pr.seenKeys.Size())
				continue;
			pr.seenKeys.Push(it.GetClassName());

			bool skull;
			int color = KeyColorIndex(it.GetClass(), skull);
			PushKey(i, color, skull, it.GetTag());
		}
	}

	void TickWeapons(int i)
	{
		let mem = MemoryOf(i);
		if (mem == null)
			return;
		for (Inventory it = players[i].mo.Inv; it != null; it = it.Inv)
		{
			let w = Weapon(it);
			if (w == null || w.bPowered_Up || mem.seen.Find(w.GetClassName()) != mem.seen.Size())
				continue;
			mem.seen.Push(w.GetClassName());
			PushWeapon(i, TuinNoticeCatalog.VanillaWeaponIndex((class<Weapon>)(w.GetClass())), w.GetTag());
		}
	}

	void TickPowerups(int i)
	{
		let pr = StateOf(i);
		let pmo = players[i].mo;
		for (int k = 0; k < TuinNoticeProgress.POWER_COUNT; k++)
		{
			let pw = Powerup(pmo.FindInventory(PowerNames[k], true));
			bool held = pw != null;
			int tics = held ? pw.EffectTics : 0;

			bool gained = false;
			if (held && !pr.powerHeld[k])
				gained = true;
			else if (held && PowerKinds[k] == TN_BERSERK)
				gained = tics < pr.powerTics[k];	// berserk counts up; re-pickup resets it
			else if (held)
				gained = tics > pr.powerTics[k];

			pr.powerHeld[k] = held;
			pr.powerTics[k] = tics;
			if (gained)
				PushKind(i, PowerKinds[k]);
		}
	}

	void TickSecrets(int i, int earned)
	{
		let pr = StateOf(i);
		int count = players[i].secretcount;
		bool found = count > pr.secretCount;
		pr.secretCount = count;
		if (found && !(earned & 2))
			PushKind(i, TN_SECRET);
	}

	void TickCloseCall(int i)
	{
		let pr = StateOf(i);
		if (!pr.closeCallArmed)
			return;
		let pmo = players[i].mo;
		if (pmo.health <= 0 || level.maptime - pr.lastDamage > CLOSE_CALL_EXPIRY)
		{
			pr.closeCallArmed = false;
			return;
		}
		if (level.maptime - pr.lastDamage < CLOSE_CALL_DELAY || level.maptime % 35)
			return;

		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (mo.health > 0 && mo.bCountKill && mo.target == pmo
				&& mo.Distance2D(pmo) < CLOSE_CALL_RANGE && mo.CheckSight(pmo))
				return;
		}
		pr.closeCallArmed = false;
		AwardCombat(i, SLOT_CLOSE, TN_CLOSE);
	}

	void TickAllmap()
	{
		if (!baselined || !level.allmap)
		{
			allmapSeen = level.allmap;
			return;
		}
		if (allmapSeen)
			return;
		allmapSeen = true;

		// The map item lingers for a tic after pickup, so the toucher can still be found.
		int taker = -1;
		let it = ThinkerIterator.Create("Inventory");
		Inventory item;
		while (taker < 0 && (item = Inventory(it.Next())))
		{
			if (item.Owner == null && ClassIsOrReplaces(item.GetClass(), "Allmap"))
				taker = NearestToucher(item);
		}

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (playeringame[i] && (taker < 0 || taker == i))
				PushKind(i, TN_ALLMAP);
		}
	}

	// Bitmask of newly earned awards: 1 kills, 2 secrets, 4 items, 8 everything.
	// The first call only records a baseline so nothing already complete announces.
	int UpdateCompletion()
	{
		int kills, secrets, items;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;
			kills += players[i].killcount;
			secrets += players[i].secretcount;
			items += players[i].itemcount;
		}

		int complete = 0;
		bool any = false, all = true;
		if (level.total_monsters > 0)
		{
			any = true;
			if (kills >= level.total_monsters) complete |= 1; else all = false;
		}
		if (level.total_secrets > 0)
		{
			any = true;
			if (secrets >= level.total_secrets) complete |= 2; else all = false;
		}
		if (level.total_items > 0)
		{
			any = true;
			if (items >= level.total_items) complete |= 4; else all = false;
		}
		if (any && all)
			complete |= 8;

		int result = baselined ? complete & ~completionAwarded : 0;
		completionAwarded |= complete;
		return result;
	}
}
