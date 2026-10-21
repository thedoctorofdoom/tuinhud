// Ported from Tuin-Doom-Enhanced notice_catalog.h, GPL-3.0.

enum ETuinNotice
{
	TN_CYBER,
	TN_SPIDER,
	TN_SECRET,
	TN_SOUL,
	TN_MEGA,
	TN_INVULN,
	TN_BERSERK,
	TN_INVIS,
	TN_RADSUIT,
	TN_ALLMAP,
	TN_VISOR,
	TN_WEAPON,
	TN_CLOSE,
	TN_CHAIN,
	TN_MULTI,
	TN_FISTS,
	TN_PERFECT,
	TN_EXIT,
	TN_KILLS,
	TN_SECRETS,
	TN_ITEMS,
	TN_COMPLETE,
	TN_COUNT
}

class TuinNoticeCatalogData
{
	static const String TitleVariant0[] =
	{
		"TITAN DOWN",
		"MASTERMIND ELIMINATED",
		"SECRET FOUND",
		"SOUL SURGE",
		"MEGA SURGE",
		"UNTOUCHABLE",
		"RIP AND TEAR",
		"INTO THE SHADOWS",
		"HAZARD PROTECTION",
		"SECTOR MAPPED",
		"LIGHT UP THE DARK",
		"NEW FIREPOWER",
		"CLOSE CALL",
		"CHAIN REACTION",
		"ONE SHOT, MANY DEMONS",
		"FISTS OF FURY",
		"PERFECT CLEAR",
		"SECRET EXIT FOUND",
		"ALL ENEMIES KILLED",
		"ALL SECRETS FOUND",
		"ALL ITEMS COLLECTED",
		"100% COMPLETE"
	};

	static const String TitleVariant1[] =
	{
		"HELL HAS LOST A GIANT",
		"THE WEB GOES SILENT",
		"HIDDEN IN PLAIN SIGHT",
		"SOULS RESTORED",
		"READY FOR ANYTHING",
		"NOT TODAY, HELL",
		"FISTS OF WRATH",
		"NOW YOU SEE ME",
		"TOXICITY CONTAINED",
		"THE BIG PICTURE",
		"NIGHT VISION",
		"ARSENAL EXPANDED",
		"STILL BREATHING",
		"EXPLOSIVE DOMINOES",
		"THREE FOR ONE",
		"HANDS ON DESTRUCTION",
		"UNTOUCHED. UNSTOPPABLE.",
		"THE ROAD LESS TRAVELLED",
		"AREA SECURED",
		"NOTHING LEFT HIDDEN",
		"NOTHING LEFT BEHIND",
		"TOTAL DOMINATION"
	};

	static const String TitleVariant2[] =
	{
		"CYBERDEMON TERMINATED",
		"BRAIN DEAD",
		"YOU FOUND THEIR SECRET",
		"A SECOND WIND",
		"POWER OVERWHELMING",
		"DEATH CAN WAIT",
		"UNLEASH THE RAGE",
		"GHOST IN THE CROSSFIRE",
		"SUIT UP",
		"LAYOUT REVEALED",
		"NOTHING IN THE SHADOWS",
		"LOCKED AND LOADED",
		"DEATH MISSED",
		"BARRELS OF TROUBLE",
		"CROWD CONTROL",
		"KNUCKLE JUSTICE",
		"FLAWLESS EXTERMINATION",
		"OFF THE BEATEN PATH",
		"NO DEMONS LEFT",
		"EVERY SECRET UNCOVERED",
		"EVERY ITEM CLAIMED",
		"EVERYTHING. DONE."
	};

	static const String SubtitleText[] =
	{
		"CYBERDEMON ELIMINATED",
		"SPIDER MASTERMIND SLAIN",
		"NOTHING STAYS HIDDEN",
		"SOULSPHERE ACQUIRED",
		"MEGASPHERE ACQUIRED",
		"INVULNERABILITY - MAKE IT COUNT",
		"BERSERK ACQUIRED",
		"PARTIAL INVISIBILITY",
		"RADIATION SUIT - WATCH THE CLOCK",
		"COMPUTER MAP ACQUIRED",
		"LIGHT AMPLIFICATION VISOR",
		"WEAPON ACQUIRED",
		"SURVIVED BELOW 10 HEALTH",
		"THREE KILLS FROM BARREL BLASTS",
		"THREE KILLS IN ONE ATTACK",
		"TOUGH DEMON - BARE HANDS",
		"100% CLEAR - NO DAMAGE TAKEN",
		"A HIDDEN JOURNEY BEGINS",
		"EVERY ENEMY ELIMINATED",
		"YOU KNOW THIS PLACE",
		"EVERY PICKUP COUNTS",
		"ALL KILLS / SECRETS / ITEMS"
	};

	static const int StyleTable[] =
	{
		2, 3, 0, 1, 1, 1, 2, 3, 0, 3, 1, 0, 1, 2, 2, 2, 1, 3, 0, 0, 0, 1
	};

	static const Name TintTable[] =
	{
		'TuinRed',
		'TuinViolet',
		'TuinViolet',
		'TuinBlue',
		'TuinGold',
		'TuinGold',
		'TuinRed',
		'TuinViolet',
		'TuinGreen',
		'TuinCyan',
		'TuinGreen',
		'TuinGold',
		'TuinOrange',
		'TuinOrange',
		'TuinGold',
		'TuinRed',
		'TuinGold',
		'TuinViolet',
		'TuinRed',
		'TuinViolet',
		'TuinGreen',
		'TuinGold'
	};

	static const String VanillaWeaponNames[] =
	{
		"FISTS",
		"PISTOL",
		"SHOTGUN",
		"CHAINGUN",
		"ROCKET LAUNCHER",
		"PLASMA RIFLE",
		"BFG 9000",
		"CHAINSAW",
		"SUPER SHOTGUN"
	};

	static const Name WeaponTintTable[] =
	{
		'TuinRed',
		'TuinGold',
		'TuinOrange',
		'TuinGold',
		'TuinRed',
		'TuinBlue',
		'TuinGreen',
		'TuinOrange',
		'TuinOrange'
	};

	static const String BfgSubtitleVariants[] =
	{
		"BIG GUN. BIG PROBLEMS.",
		"LET HELL TURN GREEN",
		"MAKE EVERY CELL COUNT"
	};

	static const String KeySubtitleVariants[] =
	{
		"A NEW PATH OPENS",
		"ACCESS GRANTED",
		"ANOTHER DOOR AWAITS"
	};
}

class TuinNoticeCatalog abstract
{
	clearscope static String Title(int kind, int variant)
	{
		if (kind < 0 || kind >= TN_COUNT)
			return "";
		if (variant < 0 || variant > 2)
			return "";
		if (variant == 0)
			return TuinNoticeCatalogData.TitleVariant0[kind];
		if (variant == 1)
			return TuinNoticeCatalogData.TitleVariant1[kind];
		return TuinNoticeCatalogData.TitleVariant2[kind];
	}

	clearscope static String Subtitle(int kind)
	{
		if (kind < 0 || kind >= TN_COUNT)
			return "";
		return TuinNoticeCatalogData.SubtitleText[kind];
	}

	clearscope static Name TintName(int kind)
	{
		if (kind < 0 || kind >= TN_COUNT)
			return 'TuinGold';
		return TuinNoticeCatalogData.TintTable[kind];
	}

	clearscope static int Style(int kind)
	{
		if (kind < 0 || kind >= TN_COUNT)
			return 0;
		return TuinNoticeCatalogData.StyleTable[kind];
	}

	clearscope static int Priority(int kind)
	{
		if (kind == TN_CYBER || kind == TN_SPIDER || kind == TN_PERFECT)
			return 2;
		if (kind == TN_EXIT)
			return 1;
		return 0;
	}

	clearscope static bool IsCombat(int kind)
	{
		return kind >= TN_CLOSE && kind <= TN_PERFECT;
	}

	clearscope static int VanillaWeaponIndex(class<Weapon> cls)
	{
		for (int pass = 0; pass < 2; pass++)
		{
			class<Weapon> w = pass == 0 ? cls : (class<Weapon>)(Actor.GetReplacee(cls));
			if (pass == 1 && w == null)
				break;
			if (w is "Fist")
				return 0;
			if (w is "Pistol")
				return 1;
			if (w is "Shotgun")
				return 2;
			if (w is "Chaingun")
				return 3;
			if (w is "RocketLauncher")
				return 4;
			if (w is "PlasmaRifle")
				return 5;
			if (w is "BFG9000")
				return 6;
			if (w is "Chainsaw")
				return 7;
			if (w is "SuperShotgun")
				return 8;
		}
		return -1;
	}

	clearscope static String VanillaWeaponName(int index)
	{
		if (index < 0 || index >= 9)
			return "";
		return TuinNoticeCatalogData.VanillaWeaponNames[index];
	}

	clearscope static Name WeaponTintName(int index)
	{
		if (index < 0 || index >= 9)
			return 'TuinGold';
		return TuinNoticeCatalogData.WeaponTintTable[index];
	}

	clearscope static String WeaponTitle(String weaponName, int variant)
	{
		if (variant < 0 || variant > 2)
			return "";
		if (variant == 0)
			return weaponName .. " ACQUIRED";
		if (variant == 1)
			return "NEW WEAPON: " .. weaponName;
		return weaponName .. " READY";
	}

	clearscope static String WeaponSubtitle(bool isBfg, int variant)
	{
		if (variant < 0 || variant > 2)
			return "";
		if (isBfg)
			return TuinNoticeCatalogData.BfgSubtitleVariants[variant];
		return Title(TN_WEAPON, variant);
	}

	clearscope static String KeyTitle(int colorIndex, bool skull)
	{
		String colorName;
		switch (colorIndex)
		{
		case 0: colorName = "BLUE"; break;
		case 1: colorName = "YELLOW"; break;
		case 2: colorName = "RED"; break;
		default: return "";
		}
		if (skull)
			return colorName .. " SKULL KEY ACQUIRED";
		return colorName .. " KEYCARD ACQUIRED";
	}

	clearscope static String KeySubtitle(int variant)
	{
		if (variant < 0 || variant > 2)
			return "";
		return TuinNoticeCatalogData.KeySubtitleVariants[variant];
	}

	clearscope static Name KeyTintName(int colorIndex)
	{
		switch (colorIndex)
		{
		case 0: return 'TuinBlue';
		case 1: return 'TuinGold';
		case 2: return 'TuinRed';
		default: return 'TuinGold';
		}
	}

	clearscope static String GenericKeyTitle(String tag)
	{
		return tag.MakeUpper() .. " ACQUIRED";
	}
}
