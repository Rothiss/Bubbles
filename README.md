## Bubbles

Addon that displays available rested XP bubbles, how many tents are actively providing them and the remaining time until 150% rested XP.

## Features

- Live rested XP "bubble" counter.
- Active tent count when two or more tents are stacked.
- Estimated time until full (150%) rested XP.
- Hover tooltip with rested, remaining and percentage detail.
- Draggable frame; its position, scale and font size are remembered between sessions.
- Type `/bubbles` or `/b` to list all available commands.

## Install

1. Copy the `Bubbles` folder into `Interface/AddOns/`.
2. Restart the client or type `/reload`.

## Commands

```
/bubbles          List all commands
/b                Alias for /bubbles
/b reset          Reset the frame to the center of the screen
/b scale <0.5-2>  Set the frame scale
/b font <8-24>    Set the font size
```

## Tooltip

```           
Rested              Total rested XP
Rested+             Rested XP from next level
Still               XP needed to level up
Percent             XP in percent of current level
Time to full rest   Remaining time until 150% rested XP
Status              Additional tent(s) count
```

## Compatibility

- Turtle WoW (World of Warcraft 1.12), Interface `11200`.

## Changelog

- **Unreleased** - Remember frame position, scale and font size (`/b scale`, `/b font`); smoother tent detection; clamp negative values; max-level early-out; localization scaffold.

- **1.3** - Code cleanup and bug fixes: guard max-level (no XP) math, prevent tooltip errors before the first update, remove global leaks, and avoid redundant label updates.
- **1.2** - Added `/bubbles` and `/b` commands.
- **1.1** - Maintenance release.
- **1.0** - First stable release.
- **0.1** - Initial version.

## Credits

- Tent-resting rate based on [PizzaWorldBuffs](https://github.com/Pizzahawaiii/PizzaWorldBuffs).
- Rested bubble formula from the [Turtle WoW forums](https://forum.turtle-wow.org/viewtopic.php?p=65081#p65081).

![alt text](ui.png "bubbles ui")
