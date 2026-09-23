# Project Deadlight — House 1 Graybox V1.2

Godot 4.7.2-compatible prototype of Deadlight's first suburban tutorial house.

## Current playable slice

- Main menu and basic new-character setup
- Exactly 1 Primary stat + 3 Secondary stats
- Lightweight top-down 3D movement
- Elapsed run time (not a countdown)
- Compact starter street and abandoned House 1
- Three entry approaches:
  - Strength • Moderate: bust the front door
  - Agility • Moderate: climb through the window
  - Unlocked side door: no check, no XP
- Abandoned-house scenery interactions that usually give no loot/XP
- Rare/simple resource scavenging: Wooden Planks and Scrap
- Newspaper lore discovery XP
- Optional hidden cache for Perception builds
- Non-lethal nail/bleeding tutorial hazard
- Bandage consumable tutorial
- Character XP and Shelter XP awarded together
- Tutorial protection: House 1 cannot kill the first character
- House 1 completion state after treatment and leaving the house

## Controls

- `W` / `Up`: move forward in the direction the character is facing
- `A` / `Left` and `D` / `Right`: smoothly turn the character and follow camera
- `S` / `Down`: smoothly turn the character and camera around 180 degrees
- `Shift`: sprint while moving forward
- `E`: interact
- `I`: backpack
- `B`: use bandage

The camera follows behind the character continuously; movement is not snapped to north/south/east/west.

## Intentionally not implemented yet

Full basement shelter, save/load, Heat, faction reputation, serious combat, extraction, Deadlight exposure demonstration, Houses 2–4, final art, animation, audio, full inventory, shelter upgrade web, progression balancing, and external feedback/email delivery.

This project targets **Godot 4.7.2 stable**.
