// Ported from Tuin-Doom-Enhanced key_notice.h (GPL-3.0).
// UI-scope drawing of animated event notices (the rotation is not ported).

class TuinNoticeDraw ui abstract
{
	const BOX_HEIGHT = 28;
	const RAD = 57.29577951308232;	// ZScript trig takes degrees; Tuin's takes radians

	static Color TintColor(Name tint)
	{
		if (tint == 'TuinRed') return Color(255, 0xFF, 0x76, 0x66);
		if (tint == 'TuinViolet') return Color(255, 0xB7, 0xA0, 0xFF);
		if (tint == 'TuinBlue') return Color(255, 0x81, 0x9C, 0xFF);
		if (tint == 'TuinGreen') return Color(255, 0x83, 0xED, 0xB0);
		if (tint == 'TuinCyan') return Color(255, 0x81, 0xDD, 0xFF);
		if (tint == 'TuinOrange') return Color(255, 0xFF, 0xB0, 0x78);
		return Color(255, 0xFF, 0xDB, 0x64);
	}

	// A filled rectangle given in virtual units, converted to real pixels (at least 1 px).
	static void FillVirtual(Color col, double alpha, double vx, double vy, double vw, double vh, double rx, double ry)
	{
		int x0 = int(floor(vx * rx + 0.5));
		int y0 = int(floor(vy * ry + 0.5));
		int w = max(1, int(floor((vx + vw) * rx + 0.5)) - x0);
		int h = max(1, int(floor((vy + vh) * ry + 0.5)) - y0);
		Screen.Dim(col, alpha, x0, y0, w, h);
	}

	// t is seconds since the notice started; centerY is in Doom's 200-line space.
	static void DrawNotice(String title, String subtitle, Name tint, int style, double t, double centerY)
	{
		double sw = Screen.GetWidth();
		double sh = Screen.GetHeight();
		if (sw <= 0 || sh <= 0)
			return;

		// 200 rows tall; width is chosen so one virtual column is 1/1.2 of a row (Doom's tall pixels).
		double vh = 200;
		double vw = 240.0 * sw / sh;
		double rx = sw / vw;
		double ry = sh / vh;

		Font fnt = SmallFont;
		int titleW = fnt.StringWidth(title);
		int subW = fnt.StringWidth(subtitle);
		int width = max(titleW, subW) + 8;

		double enter = clamp(t / 0.42, 0.0, 1.0);
		double exitF = clamp((t - 2.55) / 0.65, 0.0, 1.0);
		double inv = 1.0 - enter;
		double ease = 1.0 - inv * inv * inv;
		double fade = enter * (1.0 - exitF * exitF);

		double scale = 1.0 + 0.06 * sin(enter * 180.0);
		if (style == 1)
			scale += 0.025 * sin(t * 12.0 * RAD) * exp(-t * 2.0);

		double cx = vw - 8.0 - (width + 1) / 2 + 42.0 * (1.0 - ease) + 14.0 * exitF;
		double cy = centerY - 3.0 * sin(enter * 180.0);
		if (style == 2 && t < 0.28)
		{
			double k = 1.0 - t / 0.28;
			cx += sin(t * 90.0 * RAD) * 2.0 * k;
			cy += cos(t * 70.0 * RAD) * k;
		}
		if (style == 3 && t < 0.3)
			fade *= 0.65 + 0.35 * abs(sin(t * 55.0 * RAD));

		if (fade <= 0)
			return;

		// Box-local (width x 28) to virtual space, scaling about the box center.
		double hw = width * 0.5;
		double hh = BOX_HEIGHT * 0.5;
		double ox = cx - hw * scale;
		double oy = cy - hh * scale;

		double tx = ox + ((width - titleW) / 2) * scale;
		Screen.DrawText(fnt, Font.FindFontColor(tint), tx, oy + 2.0 * scale, title,
			DTA_VirtualWidthF, vw, DTA_VirtualHeightF, vh, DTA_KeepRatio, true,
			DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, fade);
		double sx = ox + ((width - subW) / 2) * scale;
		Screen.DrawText(fnt, Font.FindFontColor('TuinSubtitle'), sx, oy + 17.0 * scale, subtitle,
			DTA_VirtualWidthF, vw, DTA_VirtualHeightF, vh, DTA_KeepRatio, true,
			DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, fade);

		int mid = width / 2;
		int line = int(26.0 * ease);
		FillVirtual(TintColor(tint), (144.0 / 255.0) * fade,
			ox + (mid - line) * scale, oy + 13.0 * scale, (2 * line + 1) * scale, scale, rx, ry);
		if (t < 0.65)
		{
			int hx = mid - line + int(2.0 * line * clamp(t / 0.65, 0.0, 1.0));
			FillVirtual(Color(255, 255, 255, 255), fade, ox + hx * scale, oy + 13.0 * scale, scale, scale, rx, ry);
		}
	}
}

class TuinNoticeRenderer : EventHandler
{
	override void RenderOverlay(RenderEvent e)
	{
		if (gamestate != GS_LEVEL || automapactive || menuactive != Menu.Off)
			return;
		if (consoleplayer < 0 || consoleplayer >= MAXPLAYERS)
			return;
		CVar cv = CVar.GetCVar('tuin_notices', players[consoleplayer]);
		if (cv != null && cv.GetInt() == 0)
			return;

		let handler = TuinNoticeHandler(EventHandler.Find('TuinNoticeHandler'));
		if (handler == null)
			return;

		Array<TuinNotice> visible;
		foreach (n : handler.notices)
		{
			if (n.playerNum == consoleplayer && n.startTic >= 0)
				visible.Push(n);
		}
		int count = visible.Size();
		if (count == 0)
			return;

		double frac = paused ? 0.0 : e.FracTic;
		for (int i = 0; i < count; i++)
		{
			let n = visible[i];
			double t = (level.maptime - n.startTic + frac) / 35.0;
			double centerY = 94.0 - (count - 1) * 14.0 + i * 28.0;
			TuinNoticeDraw.DrawNotice(n.title, n.subtitle, n.tint, n.style, t, centerY);
		}
	}
}
