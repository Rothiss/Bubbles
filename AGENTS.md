# AGENTS.md

## Project

Bubbles is a World of Warcraft addon for Turtle WoW (Vanilla 1.12, Interface `11200`) that displays available rested-XP "bubbles", the number of active tents, and the estimated time until 150% rested XP.

## Architecture

Single-file addon, no external libraries.

- `Bubbles.toc` - addon manifest. `## Interface: 11200`, version, loads `Bubbles.lua`.
- `Bubbles.lua` - all logic and UI, structured top to bottom:
  - Constants (`TENT_RATE`, `RESTED_CAP`, `MAX_BUBBLES`, `THRESHOLD`)
  - Frame `Bubbles` (name, size, position, strata, fontstring label)
  - Helpers: `BubbleCount(rested, max)`, `FormatTime(secs)`
  - `Refresh()` - reads player state and updates the label text
  - `OnUpdate` - 1s throttle; recomputes tent count and remaining rest time
  - `OnEvent` (`PLAYER_ENTERING_WORLD`, `PLAYER_XP_UPDATE`, `PLAYER_UPDATE_RESTING`) - calls `Refresh()`
  - Drag handlers (`OnMouseDown`/`OnMouseUp`) using the `self` argument
  - Tooltip (`OnEnter`/`OnLeave`)
  - Slash commands `/bubbles`, `/b` (`reset`)
- `README.md` - user documentation.
- `ui.png` - screenshot referenced by the README.

## Conventions

- Vanilla 1.12 API only; do not use Retail/Classic-only functions.
- No external libraries or embedded frameworks.
- Do not add comments. (Existing attribution comments in `Bubbles.lua` are preserved.)
- Use WoW color codes in display strings: `|cfff58cba` (pink accent), `|cffffffff` (white), `|cffaaaaaa` (grey).
- Keep mutable state in `local` upvalues; do not leak globals. Handlers use `self` rather than the legacy `this`.
- Keep computation pure where possible (`BubbleCount`, `FormatTime`) so it stays testable and readable.
- Named global frames/fontstrings should be avoided; only the frame itself is named (`Bubbles`).

## Testing

There is no build, lint, or test tooling; addons run inside the WoW client.

- Syntax check: `luac -p Bubbles.lua`
- In game: copy the folder to `Interface/AddOns/Bubbles`, then `/reload`.
- Verify at normal level and at max level (where `UnitXPMax` is `0`).
- Commands: `/bubbles` (or `/b`) lists commands, `/b reset` recenters the frame.

## Gotchas

- `UnitXPMax("player")` returns `0` (or `nil`) at max level; all division by `m` must be guarded.
- `GetXPExhaustion()` can return `nil` or `-1`; treat both as no rested XP.
- `time` must never be `nil` before the first `OnUpdate` tick, or tooltip concatenation errors; it is initialized to `"0:00"`.
- Tooltip refresh reads live values on `OnEnter` rather than relying on stale upvalues.
- Keep the `.toc` `## Version` and the load message in `Bubbles.lua` in sync.
