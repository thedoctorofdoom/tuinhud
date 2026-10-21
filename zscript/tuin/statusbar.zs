// Ported from Tuin-Doom-Enhanced modern_hud.h (GPL-3.0).
// All positions are Tuin's 320x200 coordinates; they only reach the screen via
// DockGroup/MapPos/MapFlags/GlyphSize (and DrawLabel/DrawRect/DrawArt).
// Scale (tuin_hud_scale) and layout (tuin_hud_layout) are applied there.

class TuinStatusBar : DoomStatusBar
{
	const COL_WHITE = 0xffedf3f3;
	const COL_MUTED = 0xff9aafb7;
	const COL_BLUE = 0xff6ed6dc;
	const COL_GREEN = 0xff83edb0;
	const COL_BACK = 0xc0142028;
	const COL_BAR = 0xff344650;
	const COL_STATS_BACK = 0xb010141a;
	const COL_HEALTH_OK = 0xffeead72;
	const COL_HEALTH_LOW = 0xffff5d4c;

	int hudStyle;
	int hudFace;
	int hudLayout;
	double hudScale;

	//----------------------------------------------------------------------
	// Docking / scale / layout helpers (Tuin modern_hud.h rules)
	//----------------------------------------------------------------------

	int DockGroup(double tuinX)
	{
		return tuinX < 136 ? 0 : tuinX < 202 ? 1 : 2;
	}

	double GroupAnchor(int group)
	{
		return group == 0 ? 8 : group == 1 ? 160 : 312;
	}

	double GroupDest(int group)
	{
		if (hudLayout == 1) return group == 0 ? 18 : group == 1 ? 160 : 242;
		return GroupAnchor(group);
	}

	double MapX(int group, double x)
	{
		return GroupDest(group) + (x - GroupAnchor(group)) * hudScale;
	}

	// Tuin y after scale/layout, in 320x200 space (bottom-panel content only).
	double MapY(double y)
	{
		return hudLayout == 2 ? 38 + (y - 140) * hudScale : 195 + (y - 195) * hudScale;
	}

	// Converts a position in Tuin 320x200 space into an offset from the group's dock edge.
	Vector2 Place(int group, double x, double y, bool isFixed)
	{
		double ox = group == 0 ? 0 : group == 1 ? -160 : -320;
		if (isFixed) return (x + ox, y);
		if (hudLayout == 1) ox = -160;
		return (x + ox, hudLayout == 2 ? y : y - 200);
	}

	// isFixed = top-docked, unscaled element (stats box, timer).
	Vector2 MapPos(int group, double x, double y, bool isFixed)
	{
		if (isFixed) return Place(group, x, y, true);
		return Place(group, MapX(group, x), MapY(y), false);
	}

	int MapFlags(int group, bool isFixed)
	{
		if (isFixed || hudLayout == 2)
			return group == 0 ? DI_SCREEN_LEFT_TOP : group == 1 ? DI_SCREEN_CENTER_TOP : DI_SCREEN_RIGHT_TOP;
		if (hudLayout == 1) return DI_SCREEN_CENTER_BOTTOM;
		return group == 0 ? DI_SCREEN_LEFT_BOTTOM : group == 1 ? DI_SCREEN_CENTER_BOTTOM : DI_SCREEN_RIGHT_BOTTOM;
	}

	double GlyphSize(int size, bool isFixed = false)
	{
		return isFixed ? size : max(1, int(floor(size * hudScale + 0.5)));
	}

	double ScaleLen(double v, bool isFixed)
	{
		return isFixed ? v : max(1.0, v * hudScale);
	}

	void DrawLabel(String s, double x, double y, int size, Color c, bool isFixed = false)
	{
		int g = DockGroup(x);
		double lx = x;
		double ly = y;
		if (!isFixed)
		{
			lx = floor(MapX(g, x) + 0.5);
			ly = floor(MapY(y) + 0.5);
			if (y >= 176 && y <= 177) ly = max(ly, floor(MapY(167) + 0.5) + 6);
			else if (y == 188) ly = min(ly, floor(MapY(195) + 0.5) - 5);
			if (hudScale < 0.7)
			{
				if (s == "HEALTH") s = "HP";
				else if (s == "ARMOR") s = "AR";
			}
		}
		Vector2 p = Place(g, lx, ly, isFixed);
		TuinPixelFont.DrawText(self, s, p.x, p.y, GlyphSize(size, isFixed), c, MapFlags(g, isFixed));
	}

	void DrawRect(double x, double y, double w, double h, Color c, bool isFixed = false)
	{
		int g = DockGroup(x);
		Vector2 p = MapPos(g, x, y, isFixed);
		Fill(c, p.x, p.y, ScaleLen(w, isFixed), ScaleLen(h, isFixed), MapFlags(g, isFixed));
	}

	// Texture fitted (up or down, aspect kept) into a w x h box, top-left at the given Tuin position.
	void DrawArt(TextureID tex, double x, double y, double w, double h, bool isFixed = false)
	{
		if (!tex.IsValid()) return;
		int g = DockGroup(x);
		Vector2 p = MapPos(g, x, y, isFixed);
		DrawTexture(tex, p, MapFlags(g, isFixed) | DI_ITEM_LEFT_TOP | DI_FORCESCALE, 1.0, (ScaleLen(w, isFixed), ScaleLen(h, isFixed)));
	}

	//----------------------------------------------------------------------
	// Draw
	//----------------------------------------------------------------------

	override void Draw(int state, double TicFrac)
	{
		hudStyle = ReadCVarInt("tuin_hud_style", 1);
		hudFace = ReadCVarInt("tuin_hud_face", 1);
		hudLayout = clamp(ReadCVarInt("tuin_hud_layout", 0), 0, 2);
		hudScale = clamp(ReadCVarInt("tuin_hud_scale", 100), 50, 100) / 100.0;

		if (state == HUD_None || state == HUD_AltHud || !CPlayer || !CPlayer.mo)
		{
			Super.Draw(state, TicFrac);
			return;
		}

		if (automapactive)
		{
			// Tuin hides its HUD in the automap; keep only the engine's automap output.
			Super.Draw(hudStyle != 0 && state == HUD_Fullscreen ? HUD_None : state, TicFrac);
			return;
		}

		if (hudStyle != 0 && state == HUD_Fullscreen)
		{
			// Skip the stock fullscreen HUD but keep crosshair etc.
			Super.Draw(HUD_None, TicFrac);
			BeginHUD(1, false, 320, 200);
			DrawModernHUD(hudStyle == 2);
			DrawStatsBox();
			if (hudStyle == 2) DrawTimer();
			DrawFace();
			return;
		}

		Super.Draw(state, TicFrac);
		BeginHUD(1, false, 320, 200);
		DrawStatsBox();
	}

	int ReadCVarInt(String name, int def)
	{
		CVar cv = CVar.GetCVar(name, CPlayer);
		return cv ? cv.GetInt() : def;
	}

	//----------------------------------------------------------------------
	// Fixed top elements
	//----------------------------------------------------------------------

	void DrawStatsBox()
	{
		DrawRect(222, 1, 93, 24, COL_STATS_BACK, true);
		DrawStatRow(0, "KILLS", level.killed_monsters, level.total_monsters);
		DrawStatRow(1, "SECRETS", level.found_secrets, level.total_secrets);
		DrawStatRow(2, "ITEMS", level.found_items, level.total_items);
	}

	void DrawStatRow(int row, String name, int count, int total)
	{
		String value = String.Format("%s %d/%d", name, count, total);
		Color c = (total > 0 && count >= total) ? COL_GREEN : COL_WHITE;
		DrawLabel(value, 312 - value.Length() * 4, 4 + row * 7, 1, c, true);
	}

	void DrawTimer()
	{
		int sec = level.maptime / 35;
		DrawLabel(String.Format("%02d-%02d", sec / 60, sec % 60), 12, 4, 1, COL_WHITE, true);
	}

	//----------------------------------------------------------------------
	// Modern HUD
	//----------------------------------------------------------------------

	Color HealthColor()
	{
		return CPlayer.health <= 25 ? COL_HEALTH_LOW : COL_HEALTH_OK;
	}

	void DrawBar(double x, int value, Color c)
	{
		DrawRect(x, 190, 32, 2, COL_BAR);
		int w = clamp(value, 0, 100) * 32 / 100;
		if (w > 0) DrawRect(x, 190, w, 2, c);
		if (value > 100) DrawRect(x, 193, min(value - 100, 100) * 32 / 100, 1, c);
	}

	void DrawModernHUD(bool tactical)
	{
		double hx = 12;
		double ax = tactical ? 76 : 88;
		if (hudFace == 1)
		{
			hx = 46;
			ax = 92;
		}

		DrawRect(hx - 4, 164, tactical ? 42 : 40, 31, COL_BACK);
		DrawRect(ax - 4, 164, 40, 31, COL_BACK);
		DrawRect(252, 164, 60, 31, COL_BACK);

		int health = CPlayer.health;
		int armor = GetArmorAmount();
		Color hc = HealthColor();

		DrawLabel("HEALTH", hx, 167, 1, COL_MUTED);
		DrawLabel(String.Format("%d", max(0, health)), hx, 176, 2, hc);
		DrawLabel("ARMOR", ax, 167, 1, COL_MUTED);
		DrawLabel(String.Format("%d", max(0, armor)), ax, 176, 2, COL_BLUE);
		DrawBar(hx, health, hc);
		DrawBar(ax, armor, COL_BLUE);

		DrawAmmoPanel();
		DrawKeyGrid();
	}

	void DrawAmmoPanel()
	{
		DrawLabel("AMMO", 256, 167, 1, COL_MUTED);

		Ammo a1, a2;
		int c1, c2;
		[a1, a2, c1, c2] = GetCurrentAmmo();
		if (a1)
		{
			DrawLabel(String.Format("%d", c1), 256, 176, 2, COL_WHITE);
			DrawLabel(String.Format("/%d", a1.MaxAmount), 282, 188, 1, COL_MUTED);
			return;
		}

		Weapon w = CPlayer.ReadyWeapon;
		if (!w) return;
		String label;
		if (w is "Chainsaw") label = "SAW";
		else if (w is "Fist") label = "FIST";
		else label = FontSafeTag(w.GetTag(), 14);
		DrawLabel(label, 256, 177, 1, COL_WHITE);
	}

	// Uppercase, drop characters the pixel font cannot draw (spaces too), cap length.
	String FontSafeTag(String tag, int maxLen)
	{
		tag = tag.MakeUpper();
		String result = "";
		int len = tag.Length();
		for (int i = 0; i < len && int(result.Length()) < maxLen; i++)
		{
			if (TuinPixelFont.GlyphIndex(tag, i) >= 0) result = result .. tag.Mid(i, 1);
		}
		return result;
	}

	// Slot of the six classic keys (matches Tuin's STKEYS0-5 order), else -1.
	int KeySlot(Inventory it)
	{
		if (it is "BlueCard") return 0;
		if (it is "YellowCard") return 1;
		if (it is "RedCard") return 2;
		if (it is "BlueSkull") return 3;
		if (it is "YellowSkull") return 4;
		if (it is "RedSkull") return 5;
		return -1;
	}

	void DrawKeyGrid()
	{
		Array<Inventory> slots;
		slots.Resize(6);
		for (Inventory it = CPlayer.mo.Inv; it; it = it.Inv)
		{
			if (!(it is "Key") || !it.Icon.IsValid()) continue;
			int s = KeySlot(it);
			if (s >= 0 && !slots[s]) slots[s] = it;
			else slots.Push(it);
		}

		int count = min(slots.Size(), 18);
		for (int i = 0; i < count; i++)
		{
			if (!slots[i]) continue;
			DrawArt(slots[i].Icon, 256 + (i % 3) * 18, 151 - (i / 3) * 9, 14, 8);
		}
	}

	void DrawFace()
	{
		if (hudFace == 0) return;
		double x = hudFace == 2 ? 146 : 10;
		DrawRect(x - 2, 157, 32, 38, COL_BACK);
		DrawRect(x - 2, 157, 32, 1, HealthColor());
		DrawArt(GetMugShot(5), x, 161, 28, 32);
	}
}
