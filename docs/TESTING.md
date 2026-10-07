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


## Combat feel acceptance

The Hero has a 100-point stamina pool. Attacks consume 12 stamina; dodges consume 28. Stamina regenerates after a short recovery delay.

Taking damage causes a brief HURT state with knockback. During this state movement and attacks are temporarily disabled.

The F3 overlay exposes current stamina for local balancing.

## Content expansion acceptance

### Pale Hound
- Appears around x=1180 before the Cultist.
- Uses the shared Hitbox/Hurtbox system.
- Its pounce deals 18 damage.
- It respawns after Hero death.

### Weapon upgrade
- After the first memory is unlocked, talk to the Old Hunter again.
- The first upgrade changes weapon level from 1 to 2.
- Hero attack damage changes from 34 to 44.
- The upgrade is saved automatically.

### Boss HUD
- The Ashen Knight health bar appears when the Hero is within range.
- It disappears after the Boss is defeated.
- F3 debug also reports weapon level and current attack damage.
## Branch route acceptance

After completing Vertical Slice 001, the selected route is persisted.

Church choice:
- `WorldState.selected_route = church`
- game loads `scenes/routes/church_path.tscn`
- Amnesiac Youth can be interacted with using E
- Church Ledger route memory can be examined

Lullaby choice:
- `WorldState.selected_route = lullaby`
- game loads `scenes/routes/lullaby_path.tscn`
- Traveling Merchant can be interacted with using E
- Broken Bell route memory can be examined

Route memory is saved and should remain consumed after restarting the game.
## Ashen Knight Phase 2

At 120 HP or lower, the Ashen Knight enters Phase 2 exactly once.

Expected log:

[NEREIS][BOSS] Ashen Knight entered Phase 2

Phase 2 changes:
- movement pressure increases
- attack cooldown becomes shorter
- heavy attack damage increases from 24 to 32
- boss visual tint changes
## Village / Interior acceptance

After a route is completed, the game enters Village Hub.

Village Hub:
- current location becomes `village`
- the village checkpoint is active
- E on THE TAVERN opens the Tavern Interior
- E on THE CHURCH opens the Church Interior

Interior:
- current location becomes `tavern` or `church`
- an interior checkpoint becomes active
- route-dependent NPC dialogue remains available
- EXIT returns to Village Hub
- quitting and relaunching should resume in the same interior

Expected location log markers:

[NEREIS][WORLD] Current location=village
[NEREIS][WORLD] Current location=tavern
[NEREIS][WORLD] Current location=church
## Location resume acceptance

Quit and relaunch from each persisted location:

- `route_church` -> Church route scene
- `route_lullaby` -> Lullaby route scene
- `village` -> Village Hub
- `tavern` -> Tavern Interior
- `church` -> Church Interior

F3 debug should show the same `Location` value after relaunch.
F9 must still erase all state and restart from the main Vertical Slice.
## Scene transition acceptance

Main -> Route -> Village -> Tavern/Church should use a short fade transition.

Expected runtime marker:

[NEREIS][SCENE] Transition complete scene=...

F9 remains an immediate test reset and intentionally bypasses the transition.

## Interior clue acceptance

- Tavern clue id: `tavern_silver_bell`
- Church clue id: `church_confession_book`
- Each clue can be examined once.
- Visiting both locations must allow both clue IDs to be recorded.
- Each recorded clue increases Hero Memory by 1.
## Village Graveyard acceptance

From Village Hub, press E at VILLAGE GRAVEYARD.

Expected:
- `Location: graveyard` in F3 debug
- a graveyard checkpoint at the entrance
- two Bell Wraith encounters
- Hero death respawns the complete encounter group
- Bell Wraith attacks use sonic pulse logs
- `graveyard_hero_gravestone` can be examined once
- examining the gravestone increases World Clues and Hero Memory by 1
- EXIT returns to Village Hub
- quitting and relaunching from the graveyard resumes there
## Tavern rest acceptance

Inside the Tavern, E at the rest point should:
- restore Hero HP to 100
- restore stamina to 100
- preserve Humanity and all narrative state
- save the current location
- show the rest message
## Humanity acceptance

Humanity is a resilience / selfhood axis, not a morality score.

Current first-pass encounter effects:
- Lullaby broken bell: +1 Humanity
- Church ledger: -4 Humanity
- Tavern silver bell: +2 Humanity
- Church confession book: -5 Humanity
- Graveyard weathered stone: -8 Humanity

Humanity is clamped to 0–100, saved, restored on load, and shown as a permanent HUD bar.
## Route combat differentiation

Church Route spawns a Cultist at the route combat encounter.
Lullaby Route spawns a Pale Hound at the route combat encounter.

Both use the shared combat components and reset when the Hero dies.