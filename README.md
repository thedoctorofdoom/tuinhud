# Tuin HUD for UZDoom

A ZScript-only add-on for **UZDoom 5.x** that recreates the modern HUD and animated event notices from [Tuin Doom Enhanced](https://github.com/tuin-boop/Tuin-Doom-Enhanced), a custom Doom engine based on Duct-Tape DOOM.

## Requirements

- UZDoom **5.0 or newer** (scripts declare ZScript version 4.14)
- A supported IWAD: Doom, Doom II, Final Doom, or Freedoom

## Installation and load order

Load Tuin HUD **last** in your `-file` list. It sets the status bar class, so it replaces any status bar defined by a gameplay mod. When multiple mods touch MAPINFO, the last loaded mod wins.

```text
uzdoom -iwad DOOM2.WAD -file <your gameplay mods> tuin-hud.pk3
```

## HUD options

Open **Options → Tuin HUD Options** to configure the HUD.

### Styles

| Style | Description |
| ----- | ----------- |
| **Classic** | Stock Doom status bar / fullscreen HUD, plus Tuin’s top-right Kills / Secrets / Items counters. |
| **Modern compact** | Translucent panels for health (with bar; turns red at 25 HP or less; a second thin bar shows overheal above 100), armor (with bar), ammo (current/max), key icons above the ammo panel, and top-right Kills / Secrets / Items counters (completed categories turn green). Drawn with Tuin’s 3×5 pixel lettering. |
| **Modern tactical** | Same as modern compact, plus a level timer in the top-left. |

### Face, size, and layout

- **Face:** Hidden, Left, or Center (Doomguy’s live mugshot).
- **Size:** 50–100%. Each panel shrinks toward its own screen corner. Below 70%, labels shorten to **HP** / **AR**.
- **Layout:** Bottom corners, Bottom centered, or Top corners. Panels dock to screen edges on widescreen displays.

### Screen size (screenblocks)

Modern styles draw in fullscreen mode (screen size **11**). At screen size **10**, the classic status bar is shown because the engine reserves space for it. At **12** (no HUD), the HUD is hidden but event notices still appear.

## Event notices

Animated messages slide in on the right in Doom’s font. Up to five notices stack at once; additional events queue. Boss kills and perfect clears jump the queue.

**Pickup and progression:** keycards and skull keys; secrets found; Soulsphere, Megasphere, Invulnerability, Berserk, Partial Invisibility, Radiation Suit, Computer Map, Light Amplification Visor; first-time pickup of each weapon (remembered across levels and saves); killing a Cyberdemon or Spider Mastermind; all kills, all secrets, all items, and 100% complete (once per level—empty categories never award); secret exit and perfect clear (shown on the intermission screen).

**Combat achievements** (can be disabled separately): close call (survive below 10 health then escape danger); three kills in one attack; three barrel-blast kills; killing a tough demon with fists; 100% clear with no damage taken. Repeatable combat notices use a **20-second** cooldown.

Notices follow game time (they pause with the game), and are hidden on the automap and in menus.

## Console variables

| CVar | Values | Default | Description |
| ---- | ------ | ------- | ----------- |
| `tuin_hud_style` | 0 / 1 / 2 | 1 | HUD style: Classic, Modern compact, Modern tactical |
| `tuin_hud_face` | 0 / 1 / 2 | 1 | Face: Hidden, Left, Center |
| `tuin_hud_scale` | 50–100 | 100 | HUD size percentage |
| `tuin_hud_layout` | 0 / 1 / 2 | 0 | Layout: Bottom corners, Bottom centered, Top corners |
| `tuin_notices` | on / off | on | Master switch for event notices |
| `tuin_notice_combat` | on / off | on | Combat achievement notices |
| `tuin_debug_preview` | on / off | off | At map start, queue one of every notice; on any level exit, show both exit notices (testing) |

Menu options mirror these CVars where applicable.

## Compatibility

Works with Doom, Doom II, Final Doom, and Freedoom.

Gameplay mods with custom weapons, ammo, and keys are supported in a generic way: the ammo panel shows the current weapon’s primary ammo (or the weapon name for melee), keys use each key’s own icon, and custom weapons get a generic first-pickup notice using their in-game name. Mod-specific readouts (for example Project Brutality magazine counts or equipment) are **not** shown.

The secret-exit and perfect-clear notices are drawn by a replacement single-player intermission screen, because UZDoom offers add-ons no other way to draw during the intermission. When Tuin HUD loads last, it therefore also replaces a gameplay mod's own intermission screen (Project Brutality defines one). Co-op and deathmatch intermissions are left alone and do not show exit notices.

**Heretic, Hexen, and Strife are not supported.**

## Differences from Tuin Doom

Known gaps compared to Tuin Doom Enhanced:

- Notice text does not rotate during its entrance (UZDoom’s 2D text drawing cannot rotate text). The entrance uses slide, scale pulse, shake, and flicker only.
- Soulsphere and Megasphere notices use a pickup heuristic and may occasionally miss; items that respawn (deathmatch, `-respawn`) never trigger them.
- The weapon wheel, Toasty, FPS display, and Tuin’s engine features (lighting, destruction, Fluid Weapons) are not part of this add-on.

## Credits and license

HUD design, pixel font, layout, and notice texts are from **Tuin Doom Enhanced** by [tuin-boop](https://github.com/tuin-boop/Tuin-Doom-Enhanced) (GPL-3.0). Tuin Doom builds on **Duct-Tape DOOM** by Robert Heidenreich ([duct-tape-doom](https://github.com/robongrui/duct-tape-doom)) and the DOOM source by id Software.

This add-on is a port of GPL-3.0 code and is licensed under **GPL-3.0**; see [LICENSE](LICENSE). Doom graphics (font, face, key icons) are read from your IWAD and are not included in the pk3.
