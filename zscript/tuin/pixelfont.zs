// Ported from Tuin-Doom-Enhanced modern_hud.h (GPL-3.0).
// 3x5 pixel lettering drawn with run-merged Fill() calls.

class TuinPixelFont ui abstract
{
	const ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-/";

	// 15 chars per glyph: 5 rows (top to bottom) of 3 columns, '1' = lit.
	static String GlyphBits(int index)
	{
		static const String glyphs[] = {
			"111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001",
			"111100111001111", "111100111101111", "111001010010010", "111101111101111", "111101111001111",
			"010101111101101", "110101110101110", "111100100100111", "110101101101110", "111100110100111",
			"111100110100100", "111100101101111", "101101111101101", "111010010010111", "001001001101111",
			"101101110101101", "100100100100111", "101111111101101", "110101101101101", "111101101101111",
			"111101111100100", "111101101111001", "110101110101101", "111100111001111", "111010010010010",
			"101101101101111", "101101101101010", "101101111111101", "101101010101101", "101101010010010",
			"111001010100111", "000000111000000", "001001010100100"
		};
		return glyphs[index];
	}

	// Index of a character in ALPHABET, or -1 (lowercase, space, non-ASCII...).
	static int GlyphIndex(String text, int pos)
	{
		int c = text.ByteAt(pos);
		if (c < 33 || c > 126) return -1;
		String alphabet = ALPHABET;
		return alphabet.IndexOf(text.Mid(pos, 1));
	}

	// x/y are in the coordinate space implied by flags (e.g. DI_SCREEN_* anchoring).
	static void DrawText(BaseStatusBar sb, String text, double x, double y, double pixelSize, Color col, int flags)
	{
		int len = text.Length();
		for (int i = 0; i < len; i++)
		{
			int g = GlyphIndex(text, i);
			if (g >= 0)
			{
				String bits = GlyphBits(g);
				for (int row = 0; row < 5; row++)
				{
					int runStart = -1;
					for (int colIdx = 0; colIdx <= 3; colIdx++)
					{
						bool lit = colIdx < 3 && bits.ByteAt(row * 3 + colIdx) == 0x31;
						if (lit)
						{
							if (runStart < 0) runStart = colIdx;
						}
						else if (runStart >= 0)
						{
							sb.Fill(col, x + runStart * pixelSize, y + row * pixelSize,
								(colIdx - runStart) * pixelSize, pixelSize, flags);
							runStart = -1;
						}
					}
				}
			}
			x += 4 * pixelSize;
		}
	}

	static double TextWidth(String text, double pixelSize)
	{
		return text.Length() * 4 * pixelSize;
	}
}
