# Project Deadlight

A **Trio-minds Digital / Code3Builder** Godot 4 project: a top-down 3D survival/extraction RPG built around shelter preparation, risky scavenging runs, consequences, progression, extraction, and permanent character loss.

## Current GitHub baseline

The repository currently contains the **House 1 Graybox V1.2** playable slice and supporting smoke tests.

Implemented in the current baseline:

- Main menu and new-character setup.
- Exactly **1 Primary + 3 Secondary** stats.
- Lightweight top-down 3D movement.
- Character-facing controls rather than fixed world-axis movement.
- Smooth follow camera positioned behind/above the character.
- `W` moves forward, `A`/`D` smoothly turn, and `S` performs a smooth 180-degree turn instead of walking backward.
- Elapsed run timer rather than a global countdown.
- Compact suburban starter street and abandoned House 1.
- Three House 1 entry approaches:
  - Strength · Moderate front-door check.
  - Agility · Moderate window-entry check.
  - Unlocked side door with no check / no XP.
- Rare/simple scavenging resources such as Wooden Planks and Scrap.
- Newspaper lore discovery XP.
- Optional hidden cache for Perception builds.
- Non-lethal nail/bleeding tutorial hazard.
- Bandage tutorial.
- Character XP and Shelter XP awarded together.
- Tutorial protection so House 1 cannot kill the first character.
- House 1 completion state after treatment and leaving the house.
- Automated smoke-test coverage for the camera and House 1 slice.

## Locked core direction

Deadlight's core loop is:

**Shelter prep → leave shelter → loot / steal / survive → manage Heat and Deadlight exposure → extract or fail → return carried loot to the shelter.**

A failed/dead character permanently loses carried/equipped run loot, while shelter inventory persists.

The first suburban block is both the tutorial and a permanent development testbed. The broader game direction includes:

- shelter loadout, customization, and upgrades;
- Heat, reputation, trespassing, theft, and action consequences;
- extraction routes and run failure;
- Deadlight exposure and sunrise/time pressure;
- combat and threat-scaled XP;
- persistent Shelter Level plus per-character Character Level;
- additional houses and neighborhood interactions;
- multiple shelter/biome contexts such as suburban, dense-city, and forest environments;
- deeper inventory, equipment, crafting, progression, animation, audio, art, and world simulation.

## Controls

- `W` / `Up`: move forward in the direction the character is facing.
- `A` / `Left`: smoothly turn left.
- `D` / `Right`: smoothly turn right.
- `S` / `Down`: smoothly turn the character and camera around 180 degrees.
- `Shift`: sprint while moving forward.
- `E`: interact.
- `I`: backpack.
- `B`: use bandage.

The camera follows continuously and does not snap to north/south/east/west headings.

## Current implementation boundary

The current GitHub baseline is still an early playable graybox. Full shelter gameplay, save/load, Heat, faction reputation, serious combat, final extraction systems, full Deadlight exposure demonstration, Houses 2–4, final art, animation, audio, full inventory, shelter upgrades, and final progression balancing remain future work.

Target engine: **Godot 4.7.2 stable**.
