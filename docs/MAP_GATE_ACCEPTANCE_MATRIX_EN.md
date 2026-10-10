# Map Gate & Return Acceptance Matrix

> Status: static acceptance contract only. This is **not** a passing Godot 4.6.x runtime test.

Use this matrix for repeatable traversal checks. After any map/gate fix, rerun the affected region, the main route, and save/resume checks. A static validator passing must never be interpreted as runtime acceptance.

## 1. Main route without softlocks

| ID | Route | Preconditions | Expected result |
|---|---|---|---|
| M01 | A0 → A1 | Complete the prologue escape | Reach the village; the saved location maps to A1 |
| M02 | A1 → A2 → A3 | Normal progression | No hidden-region or resonance requirement |
| M03 | A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12 | Normal progression | Reach the inner city without H01–H08, C15, or C19 |
| M04 | A12 → ending | Meet the ending evaluator's state requirements | Enter the selected ending; H08 must not be mandatory |
| M05 | Any mainline region → Continue | A valid current location was saved | Restore a valid scene without a missing-path transition |

## 2. Macro shortcuts

| Connection | Opening side | Required condition | Regression focus |
|---|---|---|---|
| C04 A2 ↔ A5 | A5 | Reach A5 and open the old pilgrim highroad | The shortcut remains blocked from A2 before activation |
| C05 A3 ↔ A4 | A4 | Open the inspection hatch from A4 | Initial A3-to-A4 access remains available; return works after opening |
| C06 A4 ↔ A1 | A4 | Open the watergate and village-well exit | Must not open before first reaching A4 |
| C07 A4 ↔ A8 | A8 | Reach A8 through A7, then open the royal tomb gate | Must not bypass the first A7 progression |
| C10 A6 ↔ A3 | A6 | Reach A6 and open the bell-tower drop | A3 return spawn must not overlap the door |
| C12 A7 ↔ A4 | A7 | Open the supply tunnel | Reverse access from A4 remains blocked before activation |
| C15 A8 ↔ A11 | A8 | R01 and R06 sources, resonance ≥55, ancient exposure ≥2, Sight active | Path ID is C15; discovery/entry region ID is A11 |
| C16 A3 ↔ A9 | A9 | Reach A9 from A8, then open the old lift | Must not skip the first A8 mainline visit |
| C18 A9 ↔ A12 | A12 | Reach A12 through A10, then open the inner-city side gate | Must not skip the cathedral |
| C19 A10 ↔ A11 | A10 | R07 source, resonance ≥68, outer exposure ≥12, Outer-God story fact, Sight active | Path ID is C19; discovery/entry region ID is A11 |
| C23 A9 ↔ A4 | A9 | Reach A9, then open the royal drain | Must not disrupt the initial A4 progression order |

## 3. Resonance-hidden regions

Every gate follows the same interaction contract: **no usable E prompt before requirements → reveal while Resonance Sight is active and requirements are met → first E permanently opens the path → second E enters**. Permanent opening must survive scene changes, death, and save/load. Ending the reveal window may hide an unopened anomaly, but must never close a permanently opened route.

| Region | Parent | Minimum resonance | Exposure requirements | Required anomaly sources | Regression focus |
|---|---|---:|---|---|---|
| H01 Well Below the Well | A1 | 12 | None additional | None | A1 and A4 entrances share H01 state; A4 must not bypass first Sight discovery |
| H02 Bell Before the Sound | A2 | 18 | None additional | None | Remote A5 exit cannot bypass progression before A5 is reached |
| H03 Erased Third Street | A3 | 28 | None additional | None | Remote A9 exit requires A9 already reached |
| H04 Stairs Behind the Water | A4 | 36 | Ancient ≥1 | None | Remote A8 exit requires A8 already reached |
| H05 Silent Bell Room | A6 | 42 | Ancient ≥1 | None | A3 return shortcut follows the bell-tower-drop unlock state |
| H06 Erased Royal Name Corridor | A8 | 55 | Ancient ≥2 | R01, R03 | Do not confuse H06 with C15: H06 is a hidden subregion; C15 is a separate entrance to A11 |
| H07 Mirror Street | A9 | 68 | Outer ≥12 and Outer-God story fact | R07 | Resonance alone must not reveal a usable gate without the story fact; A12 exit requires A12 already reached |
| H08 Primordial Hollow | A11 | 78 | Ancient ≥2, Outer ≥18, Outer-God story fact | R01, R03, R04 | Missing any required source must keep the gate hidden; optional ending exit requires physical union |

## 4. Anomaly order and legacy saves

- R01–R08 source IDs must be unique; re-examining a source must not grant resonance or exposure deltas twice.
- R01 must unlock the existing `resonance_sight` ability. If an old save has the R01 source but lacks the ability, a later interaction may repair the ability and minimum state once.
- R04 / R05 / R06 use ancient-exposure floors, preventing missed prologue clues or optional paths from permanently locking later gates.
- R07's outer-exposure floor is conditional on the Outer-God story fact; the clue alone must not replace that story event.
- Test both orders for R08 and the Outer-God story event: story first, then R08; and R08 first, then story. Both paths must end with outer exposure at 18.
- Missing `discovered_hidden_regions`, `opened_hidden_paths`, or `entered_hidden_regions` fields in older saves must restore as empty collections without errors.

## 5. Spawn, death, and interaction focus

For every gate, test the following round trip:

1. Enter the hidden region and confirm the spawn point is outside the entry gate's interaction radius.
2. Return to the parent region and confirm the spawn side is correct, away from doors, enemies, and lethal collision.
3. After unlocking a shortcut, die and return to a checkpoint; the shortcut remains open. Unopened gates must not open because of death.
4. If an NPC, exit door, anomaly clue, and hidden gate overlap, only the highest-priority available interaction target shows an E prompt. An unavailable target must not steal focus.
5. On scene transition, clear temporary Sight, pause, and input-lock state while preserving permanent gates and clue records.
6. Save, quit, and continue from each hidden region; the correct scene and spawn side must be restored.

## 6. Acceptance status

- [x] Static topology contract defines main route, blocked edges, hidden-region thresholds, and source IDs.
- [x] Existing static validators cover the main route, scene references, selected spawn mappings, and gate-state contracts.
- [ ] Run M01–M05 in Godot 4.6.x.
- [ ] Verify real collision, gate opening, and bidirectional traversal for C04–C23.
- [ ] Verify reveal, two-step E interaction, persistence, and reload for H01–H08.
- [ ] Verify all spawn points, death recovery, interaction focus, and legacy-save migration.

**Important:** This is a repeatable test checklist, not a pass declaration. Godot runtime scenes have not been executed in the current environment, so engine behavior remains pending in-engine acceptance.
