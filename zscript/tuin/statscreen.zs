// Ported from Tuin-Doom-Enhanced p_notices.c (GPL-3.0).

// Carries level-exit notices from the unloading level to the intermission.
// A static handler outlives the level transition; it is cleared when the next level loads.
class TuinExitRelay : StaticEventHandler
{
	Array<String> titles;
	Array<String> subtitles;
	Array<Name> tints;
	Array<int> styles;
	Array<int> priorities;
	Array<int> playerNums;

	void Add(int playerNum, String title, String subtitle, Name tint, int style, int priority)
	{
		titles.Push(title);
		subtitles.Push(subtitle);
		tints.Push(tint);
		styles.Push(style);
		priorities.Push(priority);
		playerNums.Push(playerNum);
	}

	void ClearAll()
	{
		titles.Clear();
		subtitles.Clear();
		tints.Clear();
		styles.Clear();
		priorities.Clear();
		playerNums.Clear();
	}

	override void WorldLoaded(WorldEvent e)
	{
		ClearAll();
	}

	// Fills order with indices of the player's pending notices, highest priority first (stable).
	clearscope void Collect(int playerNum, in out Array<int> order)
	{
		order.Clear();
		for (int i = 0; i < playerNums.Size(); i++)
		{
			if (playerNums[i] != playerNum)
				continue;
			int at = 0;
			while (at < order.Size() && priorities[order[at]] >= priorities[i])
				at++;
			order.Insert(at, i);
		}
	}
}

class TuinStatusScreen : DoomStatusScreen
{
	const NOTICE_LIFETIME = 112;

	override void Draw(double smoothratio)
	{
		Super.Draw(smoothratio);
		DrawExitNotices(smoothratio);
	}

	void DrawExitNotices(double frac)
	{
		if (menuactive != Menu.Off || consoleplayer < 0 || consoleplayer >= MAXPLAYERS)
			return;
		CVar cv = CVar.GetCVar('tuin_notices', players[consoleplayer]);
		if (cv != null && cv.GetInt() == 0)
			return;
		if (bcnt >= NOTICE_LIFETIME)
			return;

		let relay = TuinExitRelay(StaticEventHandler.Find('TuinExitRelay'));
		if (relay == null)
			return;

		Array<int> order;
		relay.Collect(consoleplayer, order);
		int count = order.Size();
		if (count == 0)
			return;

		double t = (bcnt + clamp(frac, 0.0, 1.0)) / 35.0;
		for (int i = 0; i < count; i++)
		{
			int k = order[i];
			double centerY = 94.0 - (count - 1) * 14.0 + i * 28.0;
			TuinNoticeDraw.DrawNotice(relay.titles[k], relay.subtitles[k], relay.tints[k], relay.styles[k], t, centerY);
		}
	}
}
