# Local Test Guide\n\nThis project is currently developed on the `development` branch.\n\n## Runtime\n\nUse Godot 4.6.x. The project is intentionally kept on GDScript and does not require the .NET build.\n\nRun the project and check the Godot Output panel.\n\n## Expected first pass\n\n1. Hero spawns on the left.\n2. Old Hunter is visible near the middle.\n3. Cultist approaches from the right.\n4. A/D or arrow keys move the Hero.\n5. Space jumps.\n6. J / left mouse attacks.\n7. K / Shift dodges.\n8. E near the Old Hunter opens the first memory.\n9. F3 toggles the debug overlay.\n\n## Important log markers\n\n```text\n[NEREIS][BOOT]\n[NEREIS][STATE]\n[NEREIS][COMBAT]\n[NEREIS][HERO]\n[NEREIS][NPC]\n[NEREIS][STORY]\n[NEREIS][DEBUG]\n```\n\nFor a bug report, send the complete Output section from the first `[NEREIS][BOOT]` message through the error.\n\n## First memory acceptance\n\nAfter walking close to the Old Hunter and pressing E:\n\n```text\n[NEREIS][NPC] Old Hunter interaction requested\n[NEREIS][STORY] Old Hunter interaction accepted\n[NEREIS][STORY] First memory unlocked; hero_memory=1\n[NEREIS][STORY] First memory event displayed\n```\n\nThe debug overlay should then show:\n\n```text\nMemory: 1\nHumanity: 100\n```\n\n## Combat acceptance\n\nWhen the Hero attacks the Cultist in range:\n\n```text\n[NEREIS][COMBAT] Hero attack started; hitbox active\n[NEREIS][COMBAT] Hero -> Cultist damage=34 hp=66\n```\n\nWhen the Cultist attacks:\n\n```text\n[NEREIS][COMBAT] Cultist attack started; hitbox active\n[NEREIS][COMBAT] Cultist -> Hero damage=12 hp=88\n```\n\nA dodge should produce an invulnerability log. Attacks during that window should be ignored.\n\n## Current limitation\n\nThe maintainer environment does not currently have a Godot executable and cannot reach the official download host, so runtime verification is intentionally delegated to the local Godot 4.6.x environment. Code-level review and repository consistency checks are still performed before each iteration.\n

## Mini Boss acceptance

After reaching the far right of the slice, the Ashen Knight should begin a visible windup before attacking.

Expected log:

```text
[NEREIS][BOSS] Ashen Knight initialized; hp=240
[NEREIS][BOSS] Ashen Knight attack telegraph
[NEREIS][COMBAT] Ashen Knight heavy attack released; damage=24
```

The Hero should be able to damage the Ashen Knight through the same Hitbox/Hurtbox system used by the Cultist.


## Vertical Slice 001 completion

The full acceptance route is:

```text
Awakening
  -> Old Hunter
  -> First Memory
  -> Checkpoint
  -> Cultist
  -> Ash Gate
  -> Ashen Knight
  -> First Choice
  -> Exit
```

After the exit is reached:

```text
[NEREIS][WORLD] Vertical Slice 001 complete
```

The debug overlay should show:

```text
Boss Defeated: true
Slice Complete: true
```

## Save / load acceptance

Save is automatic when a meaningful world-state change occurs:

- first memory unlocked
- checkpoint activated
- Ash Gate opened
- Ashen Knight defeated
- first choice resolved
- Vertical Slice completed

On the next launch the state should be restored from user://nereis_hero_save.json.

For clean repeated testing:

F9 = delete save + reset world + reload current scene
F3 = toggle debug overlay

Expected startup log with a saved run:

[NEREIS][SAVE] Game loaded; ...

Expected startup log for a clean run:

[NEREIS][SAVE] No save file; starting new run
