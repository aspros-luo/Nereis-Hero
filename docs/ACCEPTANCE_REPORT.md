# Nereis Hero — Core Combat Demo Acceptance Report

Date: 2026-10-07

## 1. Acceptance target

Current milestone:

Hero → simple level → small enemies → Boss

Default scene:

res://scenes/combat_demo.tscn

Active development branch:

development

Design references:

- Hollow Knight: responsive 2D movement, deliberate spacing, readable enemy timing, compact combat loop.
- Blasphemous 2: heavier commitment, stronger hit presentation, dark religious visual language, phase-driven boss pressure.

These are reference principles only. The project uses original Nereis characters, rules and world content.

## 2. Implementation status

### Hero

Completed:

- left/right movement
- jump
- coyote time
- jump input buffer
- three-step attack rhythm
- attack windup / contact / recovery
- stamina consumption and regeneration
- dodge
- dodge invulnerability
- hurt state
- knockback
- death and respawn
- hit confirmation
- small camera impact on hit / damage

### Small enemies

Completed:

- Cultist melee enemy
- Pale Hound pounce enemy
- attack telegraphs
- hit-stagger
- knockback response
- distinct pressure patterns
- shared Hitbox / Hurtbox combat system

### Boss

Completed:

- Ashen Knight
- 240 HP
- readable heavy attack telegraph
- Phase II at 120 HP
- increased movement pressure in Phase II
- shorter attack cadence
- Phase II damage increased to 36
- Phase II HUD feedback
- Boss health HUD

### Core level

Completed:

- horizontal playable level
- Hero starting area
- first checkpoint
- exactly 3 small enemies
- Ash Gate
- Boss approach checkpoint
- compact Ashen Arena
- Boss spawn after all 3 small enemies are defeated
- death reset of the small-enemy wave before Boss combat
- Boss completion state

### HUD / UX

Completed:

- HP
- Stamina
- Humanity
- Boss HP
- enemy progress 0/3 → 3/3
- HIT <damage>
- DEFEATED // RETURNING TO CHECKPOINT
- THE ASHEN KNIGHT // PHASE II
- CORE COMBAT DEMO COMPLETE
- F3 debug toggle
- F9 clean reset

## 3. Static verification

The following repository checks passed on the current development branch:

- default startup scene points to combat_demo.tscn
- hero attack signal is connected to the Hitbox callback
- Hitbox avoids self-hit and emits hit confirmation
- Cultist contains attack windup and hit-stagger
- Pale Hound contains attack windup and pounce behavior
- Ashen Knight exposes a Phase II signal
- HUD contains progress / phase / completion feedback
- Combat Demo connects Hero hit feedback and Boss phase feedback
- Boss only spawns after 3 small enemies are defeated
- Hero death resets the small-enemy wave before Boss combat
- Boss approach checkpoint is created after the Ash Gate opens
- Demo completion flag and completion HUD are wired
- modified core scripts have balanced (), [] and {} structures
- no duplicate GDScript function definitions were detected in the checked files

No GitHub Actions workflow was added or triggered as part of this work.

## 4. Manual runtime acceptance

This is the remaining final gate.

The maintainer environment used for repository work does not contain a Godot executable and cannot download the runtime, so the following items have NOT been claimed as runtime-passed here:

- actual window startup
- keyboard / mouse input
- real frame-to-frame combat timing
- actual hitbox overlap behavior
- actual dodge invulnerability timing
- real checkpoint respawn positioning
- visual readability of telegraphs
- real Boss Phase II transition
- real end-to-end Boss defeat
- actual F9 reload behavior

Therefore the correct overall status is:

**IMPLEMENTATION COMPLETE / STATIC VERIFICATION PASSED / FINAL RUNTIME ACCEPTANCE PENDING**

## 5. Local environment

Recommended engine:

Godot 4.6.x, Standard/GDScript build.

The project does not require the .NET build.

Godot 4.6.1 is stable, and newer 4.6.x maintenance releases are also available. The project should remain within the 4.6.x line for this acceptance pass.

## 6. Local commands

Clone and select the development branch:

    git clone https://github.com/aspros-luo/Nereis-Hero.git
    cd Nereis-Hero
    git checkout development
    git pull --ff-only origin development

Verify the branch:

    git branch --show-current

Expected:

    development

Verify the project file:

    test -f project.godot && echo "project.godot OK"
    grep -n 'run/main_scene' project.godot

Expected main scene:

    run/main_scene="res://scenes/combat_demo.tscn"

### macOS

When Godot is installed as /Applications/Godot.app:

    /Applications/Godot.app/Contents/MacOS/Godot --version

Run the project:

    /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD"

Or, when Godot is already in PATH:

    godot --version
    godot --path "$PWD"

Godot's official command-line documentation supports running a project with --path and running a specific scene from the command line.

## 7. Manual acceptance procedure

### A. Clean start

Press F9 once after startup.

Expected:

- clean Core Combat Demo
- Hero at the left side
- HUD title: NEREIS HERO // CORE COMBAT DEMO
- objective starts at 0 / 3
- no Boss visible

### B. Hero movement

Perform:

- A / D
- Space
- move through the first checkpoint

Observe:

- responsive horizontal movement
- jump
- no excessive floatiness
- checkpoint activation

### C. Hero attack

Press J several times in combat range.

Verify:

- first attack
- second attack during the combo window
- third attack
- visible windup
- visible attack arc
- stamina decreases
- successful hit shows HIT <damage>

### D. Dodge

Approach an enemy and press K / Shift during its attack telegraph.

Verify:

- Hero moves rapidly
- Hero is briefly invulnerable
- damage is ignored during the dodge window

### E. Death and respawn

Allow a small enemy to defeat the Hero.

Verify:

- DEFEATED // RETURNING TO CHECKPOINT
- Hero returns with full HP
- stamina returns to full
- before Boss combat, the three-small-enemy wave is rebuilt

### F. Small enemy route

Defeat:

1. Cultist A
2. Pale Hound
3. Cultist B

Verify:

- HUD reaches 3 / 3
- each enemy has readable attack timing
- enemies visibly react to successful hits

### G. Ash Gate

After 3 / 3:

Verify:

- Ash Gate disappears
- Boss approach checkpoint becomes active
- Ashen Knight appears only after the gate opens
- objective changes to DEFEAT THE ASHEN KNIGHT

### H. Boss combat

Fight the Ashen Knight.

Verify:

- Boss health bar appears
- heavy attack has visible windup
- damage is applied only at the attack release window
- Boss reacts to successful Hero attacks

### I. Boss Phase II

Reduce Boss HP to 120 or below.

Verify exactly once:

    THE ASHEN KNIGHT // PHASE II

Then verify:

- faster movement
- shorter attack cadence
- stronger attack
- more aggressive pressure

### J. Boss death

Defeat the Ashen Knight.

Verify:

    CORE COMBAT DEMO COMPLETE

Also verify:

- Boss health HUD disappears
- no new enemy wave is created

### K. Boss checkpoint regression

During Boss combat, deliberately die once.

Verify:

- Hero respawns at the Boss approach checkpoint
- Hero does NOT restart the entire road
- small enemies are not respawned

### L. F3 / F9

Press F3:

- debug panel toggles

Press F9:

- save is deleted
- current scene reloads
- demo returns to a clean 0 / 3 state

## 8. Expected important logs

Startup:

    [NEREIS][DEMO] Core Combat Demo started

Small enemy progression:

    [NEREIS][DEMO] Small enemy defeated 1/3
    [NEREIS][DEMO] Small enemy defeated 2/3
    [NEREIS][DEMO] Small enemy defeated 3/3

Gate:

    [NEREIS][DEMO] All small enemies defeated; Boss gate opened

Boss:

    [NEREIS][DEMO] Boss encounter started

Phase II:

    [NEREIS][BOSS] Ashen Knight entered Phase 2

Completion:

    [NEREIS][DEMO] CORE COMBAT DEMO COMPLETE

## 9. Runtime bug collection

For a failed acceptance item, run:

    godot --path "$PWD" --verbose 2>&1 | tee /tmp/nereis-hero-demo.log

After reproducing the issue:

    grep -Ei "ERROR|SCRIPT ERROR|Parse Error|Parser Error|Invalid call|Invalid get|Invalid set" /tmp/nereis-hero-demo.log

Send the resulting error section together with the exact acceptance step that failed.

## 10. Final conclusion

The Core Combat Demo implementation has reached the intended development scope.

The project is ready for interactive acceptance in Godot.

The only remaining gate is real runtime execution; no runtime pass is claimed until the project has actually been launched and the acceptance sequence above has been performed.

Once the local runtime checklist passes, this milestone can be considered fully accepted and the next development stage can begin.

## 11. First real Godot 4.6.1 launch findings

The first local launch exposed issues that static repository checks did not catch:

1. project.godot had the [application] and [autoload] sections ordered incorrectly. Godot therefore interpreted application settings such as the project name and feature array as autoload entries.
2. Godot 4.6.1 treated several Variant-inference warnings as errors because warnings are configured to be treated as errors in this project/editor context.
3. The Pale Hound used a custom draw_ellipse() method that conflicts with CanvasItem's native method signature.
4. Several retained scripts used untyped get_node_or_null() results.

These issues have now been fixed on the development branch. The corrected project.godot uses a proper [application] section followed by [autoload], all currently exposed Variant inference sites use explicit types / clampf / clampi, the Pale Hound helper has been renamed, and retained NPC/world scripts have explicit Node2D typing.

The repository has been rechecked after these fixes. Core and retained scripts checked in this pass have balanced syntax structure, no duplicate function definitions, and no remaining untyped get_node_or_null patterns or native draw_ellipse override.

## 12. Updated local verification command

After pulling the latest development branch, close and reopen Godot so the project configuration is reloaded:

    cd Nereis-Hero
    git checkout development
    git pull --ff-only origin development

Optional clean editor cache reset if Godot still displays errors from the old project configuration:

    rm -rf .godot

Then start the editor again:

    /Applications/Godot.app/Contents/MacOS/Godot --editor --path "$PWD"

Or start the project directly:

    /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD"

The previous errors involving Resource file not found for the project name, the 4.6/GL Compatibility array being treated as an autoload, Variant inference, and the Pale Hound draw_ellipse override should no longer appear after the updated branch is pulled.


## 13. Second local launch finding

After the project configuration and gameplay scripts were corrected, Godot 4.6.1 surfaced one additional strict Variant-inference error in scripts/effects/hit_spark.gd.

The affected values are now explicitly typed, including the alpha calculation, and the code uses maxf() for the floating-point clamp.

The remaining core gameplay scripts were re-scanned for the same high-risk inferred-Variant patterns; no matching untyped get_node_or_null(), Object.get(), Object.name, global-position, numeric clamp, or native draw_ellipse override patterns were found in the checked development files.
