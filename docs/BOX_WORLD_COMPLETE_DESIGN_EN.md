# Nereis-Hero Complete Box-World Map Design

> **Design version note (2026-10-12):** This is the v0.1 topology baseline and playtime-planning draft. Spatial authority now belongs to [Final Box-World Map Design v1.0 — Vertically Interconnected World](BOX_WORLD_FINAL_MAP_DESIGN_EN.md). This document remains historical context and a playtime baseline, not the final spatial authority.

> Version: 0.1 (topology baseline and playtime plan)  
> Date: 2026-10-12  
> Branch: `development`  
> Status: Design document; not yet accepted through Godot runtime testing  
> Core principle: **an interconnected box-world, not a linear chain of levels**

## 0. Purpose and scope

This document is the shared entry point for the current A0–A13 and H01–H08 map design. It consolidates region roles, progression route, macro connections, shortcuts, loops, hidden areas, and a provisional playtime target.

It describes the current design baseline; it does not claim that every region is finished. A topology connection is complete only after its physical door, collision, platform, spawn, save state, and runtime traversal pass Godot acceptance.

H09, “Cliffside Experiment Cave,” remains provisional. It is excluded from the formal map count, is not confirmed world canon, and must not become a mandatory ending condition.

## 1. Playtime target: a planning estimate, not a confirmed historical commitment

No explicit user-confirmed total playtime target for Nereis-Hero was found. The previously mentioned “20–30 hours” came from a different text-adventure planning discussion and must not be presented as the original commitment for this action game.

For content sizing, use these **provisional and adjustable production targets**:

- First ending: approximately **18–24 hours**.
- A substantially explored first run, with most shortcuts and hidden areas found: approximately **22–28 hours**.
- All three endings and high completion: approximately **30–40 hours**, provided ending branches, side content, combat challenges, and replay differences are actually implemented.

These are planning ranges, not measured results. Actual duration depends on combat difficulty, player skill, exploration habits, deaths, text volume, and backtracking.

### 1.1 First-run duration breakdown

| Activity | Suggested range | Main contributors |
|---|---:|---|
| First exploration and navigation | 6–9 h | 13 primary regions, spatial learning, exit discovery, environmental clues |
| Combat and bosses | 5–8 h | Regular encounters, elites, regional fights, boss learning and retries |
| Narrative and environmental storytelling | 2–4 h | Short dialogue, item descriptions, Church/Kingdom/Ancient-God/Outer-God clues |
| Revisits, shortcuts, and puzzles | 3–5 h | Unlocks, alternate routes, Resonance paths, revisiting old areas, evidence collection |
| **Planning envelope before overlap** | **16–26 h** | Activities overlap; center the first-ending target around 18–24 h |

Do not pad duration with empty traversal, inflated enemy health, or repeated corridors. Meaningful duration should emerge from route discovery, combat learning, shortcut unlocks, hidden spaces, and narrative interpretation.

### 1.2 Is the current content enough?

**It has the potential to support 18–24 hours, but it cannot yet be judged sufficient.** The current baseline contains 13 primary exploration regions (A0–A12), 8 formal hidden regions (H01–H08), and A13 as an abstract ending layer: 21 primary/hidden scene regions in total, excluding provisional H09.

If primary regions take only 15–20 minutes each and hidden areas 3–5 minutes, the game will likely feel short. Each primary region needs a memorable spatial theme, at least one notable combat or exploration beat, and a meaningful optional branch or revisit. Hidden regions need distinct experiences rather than a uniform tiny reward room. Boss counts, complete narrative branches, and replay value across endings still need separate implementation; region count alone cannot guarantee the target.

## 2. World structure overview

### 2.1 Region directory

| ID | Region | Spatial role | Core experience |
|---|---|---|---|
| A0 | Border Surgery and Escape Route | Prologue | Escape, tutorial, fractured memory; no large loop required |
| A1 | Border Village | Starting hub | Safety, village relationships, hidden well, later revisits |
| A2 | Mistwood, Bell Tomb, and Old Pilgrim Road | Surface exploration | Canopy high road, bell tomb, old pilgrim route |
| A3 | Abandoned City | First major hub | Street level, raised pipes, bell-tower return lane, eastern rooftop lift |
| A4 | Sewers, Sedimentation Hall, and Old Reservoir | Underground hub | Multi-level transit: village watergate, prison low route, tomb mid-waterway, royal high drain |
| A5 | Old Battlefield and Border Fortress | Combat/surface | Trenches, fortress, pilgrim-road shortcut, secondary bell-room exit |
| A6 | Monastery, Cloisters, and Bell Tower | Vertical structure | Upper/lower routes, tower drop, shortcut back to the city |
| A7 | Prison, Well of Confession, and Maintenance Shaft | Vertical underground | Low supply tunnel, maintenance shaft, main route to royal tomb |
| A8 | Old Royal Tomb and Royal Underpass | Underground hub | Royal history, tomb passages, outer-ring route, secret access to deep research |
| A9 | Royal Outer Ring and Abandoned Quarter | Late-game hub | Rooftops, old lift, royal drain, multiple links to cathedral and inner city |
| A10 | Grand Cathedral, Pilgrim Steps, and Church Inner Court | Mainline | Church power center, upper route, secret silent side chapel |
| A11 | Ancient-God Ruins and Deep Research Zone | Optional deep area | Ancient remains and Church experiments; two secret entrances |
| A12 | Royal Inner City and Throne District | Pre-ending mainline | Relationship between crown and Church, side gate, throne approach |
| A13 | Deep Dream and Final Anomaly | Ending layer | Ending-specific finale; abstract layer, not a normal exploration region |
| H01 | Echo Layer Beneath the Well | Hidden | Early Resonance lesson; later opening into the underground network |
| H02 | Reversed Bell Chamber | Hidden | Sound in reverse order; later connection to the battlefield |
| H03 | The Erased Third Street | Hidden | Evidence of erased urban memory; later service door to the outer ring |
| H04 | Stairs Behind the Water | Hidden | Misalignment between reflection and physical space; royal-tomb side route |
| H05 | Silent Bell Chamber | Hidden | Monastery anomaly that echoes the reversed bell |
| H06 | Corridor of Erased Royal Names | Hidden | Royal history and deleted names; later royal transit connection |
| H07 | Mirror Street: Beyond the Rain | Hidden | Outer-ring reflections, inner-city side gate, late-game revisiting |
| H08 | Womb / Primordial Hollow | Deep hidden | High-risk space at the boundary of ancient remains and Outer-God influence |
| H09 | Cliffside Experiment Cave | **Provisional** | Graybox candidate only; not approved narrative content |

### 2.2 Textual connection overview

The initial guidance route is:

`A0 → A1 → A2 → A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12`

This is only the initial progression route, not the intended shape of the world. A4 must act as an underground hub connected through the A3 sewer entrance, A1 watergate/well, A7 prison supply route, A8 mid-level tomb waterway, and A9 royal drain. A11 is a deep optional region reachable through secret entrances from the tomb or cathedral. A13 receives ending-specific entries based on progression state.

**Acceptance must not focus on the progression chain alone.** The key question is whether players can choose alternate routes from hubs such as A3, A4, and A9 after unlocking connections—and understand why those routes exist.

## 3. Macro connection register

| ID | Connection | Type | Unlock / purpose |
|---|---|---|---|
| C01 | A0 → A1 | Main | Escape route to village |
| C02 | A1 ↔ A2 | Main | Village/forest traversal |
| C03 | A2 ↔ A3 | Main | City via canopy high road; return must preserve elevation |
| C04 | A2 ↔ A5 | Shortcut | Open old pilgrim high road after reaching A5 |
| C05 | A3 ↔ A4 | Underground | Raised pipe-walk into sewer/reservoir hub |
| C06 | A4 → A1 | Shortcut | Open watergate and village well return |
| C07 | A4 ↔ A8 | Shortcut | Open middle royal-tomb waterway after reaching A8 |
| C08 | A3 ↔ A5 | Main | Primary city/battlefield connection |
| C09 | A5 ↔ A6 | Main | Enter monastery via broken upper parapet |
| C10 | A6 ↔ A3 | Shortcut | Bell-tower drop creates the L02 mid-level loop |
| C11 | A6 ↔ A7 | Main | Monastery into prison |
| C12 | A7 ↔ A4 | Shortcut | Open low prison supply tunnel |
| C13 | A7 ↔ A8 | Main | Maintenance shaft into royal tomb |
| C14 | A8 ↔ A9 | Main | Tomb to royal outer ring |
| C15 | A8 ↔ A11 | Secret | Find tomb maintenance shaft into deep research |
| C16 | A3 ↔ A9 | Shortcut | Open eastern rooftop lift after reaching A9 |
| C17 | A9 ↔ A10 | Main | Cathedral via rooftop high road |
| C18 | A9 ↔ A12 | Shortcut | Open inner-city side gate after reaching A12 |
| C19 | A10 ↔ A11 | Secret | Deep research via silent side chapel |
| C20 | A10 ↔ A12 | Main | Cathedral to royal inner city |
| C21 | A11 → A13 | Ending | Opens when deep-dream ending state permits |
| C22 | A12 → A13 | Ending | Opens when throne ending state permits |
| C23 | A9 ↔ A4 | Shortcut | Open royal high drain from the outer ring |
| C24 | A1 ↔ A3 | Shortcut | City cut-through after surviving village defense |

> The prologue connection C01 and ending entrances C21/C22 need not behave like ordinary two-way hubs. Other important regions should form cross-links or local loops wherever possible.

## 4. Three registered macro loops

### L01 Border Loop: A1—A2—A3—A4—A1

- **Experience:** Leave the village, cross forest and city, reach the underground hub, then return to the familiar village through the well/watergate.
- **Unlocks:** Open the sewer inspection hatch from A4 (C05); open the watergate and village well exit (C06).
- **Value:** Establishes the underground water system as a real part of the settlement rather than making the old well a decorative prop.
- **Risks:** C06 must not be confused with H01; return spawn must preserve the correct elevation and avoid hidden-door triggers.

### L02 Mid-Level Loop: A3—A5—A6—A3

- **Experience:** City to battlefield to monastery, then descend from the bell tower to another level of the city.
- **Unlock:** Open bell-tower drop C10 from A6.
- **Value:** A clear shortcut changes how players understand the city's spatial layout.
- **Risks:** The elevated door must be reached from the high route; return must land on a standable upper platform, not the ground beneath the door.

### L03 Deep Kingdom Loop: A4—A8—A9—A4

- **Experience:** Underground waterways to royal tomb, then the outer ring, and back to the reservoir through the royal drain.
- **Unlocks:** Reach A8 through A7 and open C07; open C23 from A9.
- **Value:** Connects prison, tomb, city, and water infrastructure into one spatial system.
- **Risks:** C12 low supply tunnel, C07 mid-level tomb waterway, and C23 high royal drain must be visibly distinct.

These are the three currently registered macro loops, not a quota or limit. If actual play still relies mainly on retracing the same path, more useful cross-links are required.

## 5. Hidden-region design register

| Region | Parent / anchor | Resonance threshold | Purpose | Secondary exit |
|---|---|---:|---|---|
| H01 Echo Layer Beneath the Well | A1 old well | 12 | Early anomaly lesson; later underground access | A4, after reaching A4 |
| H02 Reversed Bell Chamber | A2 bell tomb | 18 | Sound/time-order anomaly | A5, after reaching battlefield |
| H03 The Erased Third Street | A3 old market/chapel | 28 | Evidence of erased urban memory | A9, after reaching outer ring |
| H04 Stairs Behind the Water | A4 old reservoir | 36 | Reflection/physical-space mismatch | A8, after reaching royal tomb and opening side door |
| H05 Silent Bell Chamber | A6 tower/silent window | 42 | Thematic counterpoint to reversed bell | A3, linked to tower-drop route |
| H06 Corridor of Erased Royal Names | A8 royal inscriptions | 55 | Royal history and deleted names | A9, after reaching outer ring |
| H07 Mirror Street: Beyond the Rain | A9 flooded reflection | 68 | Late-game spatial anomaly and revisiting | A12, after reaching inner city |
| H08 Womb / Primordial Hollow | A11 deep observation wall | 78 | Deep, high-risk space where ancient remains and Outer-God influence meet | A13; current condition is tied to ending routing and needs a dedicated review |

### 5.1 Shared rules for hidden areas

Each H area must separately verify: undiscovered, anomaly perceived, entrance revealed, entrance opened, entered, clue/reward obtained, and secondary exit unlocked. One Boolean must not stand in for all states.

- Resonance reveals anomalies, but every secret should not use the same visual effect.
- Entrances need environmental hints so players can reasonably infer that something is wrong.
- Hidden regions need a safe return. Secondary exits should open only after the destination has been reasonably reached, avoiding accidental mainline skips.
- Clues and rewards must persist through scene changes, death, and reload.
- H08 currently references `physical_union_complete`. This is in tension with the shared-world design constraint that intimacy and investigation are separate dimensions. Do not make one intimate event a hard ending gate for the other game without a dedicated design decision. If retained as a Hero ending condition, document it as a Hero-specific ending contract and recheck cross-project causality.
- H09 is not a formal hidden region and must not be used to inflate map count or playtime.

## 6. Box-world construction principles

### 6.1 Each region must be more than a horizontal corridor

Each primary region should combine at least two of the following: main path, multiple elevation lanes, side branch/local loop, hidden entrance, shortcut exit, revisit reward. Hubs must have multiple meaningful destinations; several doors leading to more linear corridors do not create a box-world.

### 6.2 Every elevation change needs a spatial reason

- A2: canopy high road and ground-level bell tomb.
- A3: street, raised pipe-walk, bell-tower return lane, eastern rooftop lift.
- A4: reservoir floor, low prison supply tunnel, mid-level royal-tomb waterway, high royal drain.
- A5–A7: broken battlefield parapet, monastery tower, prison shaft and low route.
- A8–A9: royal-tomb middle level, city rooftops, royal drain.
- A10–A12: cathedral upper levels, outer-ring rooftops, inner-city side gate, throne approach.

Platforms, silhouettes, and landmarks must communicate these layers. Invisible walls must not be the primary way to force route restrictions.

### 6.3 Shortcut acceptance

A shortcut is meaningful if at least one of these is true:

1. It materially shortens revisits between explored regions.
2. It connects previously separated spatial layers.
3. It allows a known landmark to be approached from a new direction.
4. It opens another side of a hub and creates a verifiable loop.

### 6.4 Revisit content

Each important revisit should offer at least one reasonable new motivation: a new exit, Resonance-visible object, previously locked door, changed enemy state, item/environmental evidence, side-character change, or shortcut. Do not make players traverse unchanged routes repeatedly just to pad duration.

## 7. Content density and combat recommendations

The current script already places some encounters in primary and hidden regions, but enemy placement alone is not a complete combat design. Each primary region should plan:

- One memorable change in combat rhythm (ambush, narrow terrain, vertical combat, ranged/melee combinations, etc.).
- One recognizable environmental threat or spatial pressure.
- One optional exploration reward.
- A connection or revisit value that changes how the player understands the map (not mandatory in every region, but required in hubs).
- A deliberate rest-point and death-recovery route.

Elite and boss encounters should be distinct by regional theme. Avoid repeating the same ordinary enemies everywhere or inflating health merely to increase duration. Total boss count, full boss phases, and ending-specific encounters still need a separate combat-content matrix.

## 8. Narrative placement without damaging exploration

The map should be stabilized before large-scale narrative filling, but spaces should reserve narrative opportunities:

- A0: experimentation on the protagonist, escape, fractured memory; do not explain the entire Church conspiracy in the prologue.
- A1: villagers have independent lives and motives; Mite's ordinary life should feel genuine, and the entire village must not be written as fully informed cultists.
- A2–A4: roads, pipes, wells, reservoirs, and anomalous sounds imply that older structures predate current Kingdom infrastructure.
- A5–A7: battlefield, monastery, and prison show traces of expansion, Church discipline, and research.
- A8–A10: royal inscriptions, cathedral machinery, and erased names gradually reveal the relationship between faith, power, and rewritten history.
- A11: show evidence of Church research and ancient remains without collapsing Ancient-God, Outer-God, and Kingdom-faith forces into one.
- A12–A13: let prior exploration and ending state shape the final interpretation; do not explain everything in one linear conversation.
- H01–H08: prioritize environmental change, item descriptions, sound, spatial contradictions, and sparse text over long exposition in every hidden room.

Narrative duration should come from the player assembling fragments, not from large blocks of unskippable dialogue. Hero does not know Mite's true identity; player knowledge must not automatically become Hero's knowledge.

## 9. Complete acceptance checklist

### Topology
- [ ] Connections, directions, and unlock conditions for A0–A12 agree.
- [ ] A13 accepts only ending-authorized entrances.
- [ ] C04/C06/C07/C10/C12/C16/C18/C23/C24 have explicit locked/unlocked behavior.
- [ ] L01/L02/L03 are physically traversable; if play still feels linear, revise the map.
- [ ] H01–H08 can be found, entered, and exited; secondary exits obey their conditions.

### Space and interaction
- [ ] Elevated doors are reachable only from their intended platform route.
- [ ] Every arrival and return spawn lands on a standable platform.
- [ ] Spawns do not overlap door, hidden entrance, rest-point, or other E-interaction focus areas.
- [ ] Ground, low, middle, and high routes are visually and mechanically distinct.
- [ ] Door and reward state remains correct after death, respawn, scene change, and reload.

### Experience
- [ ] Important hubs offer multiple meaningful exits.
- [ ] Every shortcut materially shortens travel or changes route choice.
- [ ] Revisits reveal new content or choices.
- [ ] Hidden areas have distinct experiences rather than identical reward rooms.
- [ ] Combat and rest-point pacing is deliberate; no empty traversal or health inflation for padding.

### Runtime and duration
- [ ] Walk every connection in Godot 4.6.x.
- [ ] Record static-validation and runtime-validation results separately.
- [ ] During playtests, record first-visit time, revisit time, deaths, and points of confusion.
- [ ] Collect at least one full first-ending playthrough before revising the 18–24 hour target.
- [ ] Reassess the 30–40 hour high-completion target only after all endings and major hidden content exist.

## 10. Current conclusion and next steps

The current design has a foundation for an interconnected box-world: multiple hubs, 9 defined shortcuts, 3 explicit macro loops, and 8 formal hidden regions. However, completeness, playability, and target duration have not yet been proven in runtime.

Next steps:

1. Finish A2–A4 space, door interaction, return-spawn, and L01 acceptance.
2. Review A5–A8 and L02 to ensure the mid-level network is not a single progression line.
3. Review A9–A12, the outer ring, cathedral, inner city, and L03.
4. Verify Resonance, return, secondary exits, and persistence for H01–H08 individually.
5. Change the actual traversal network based on playability, not just connection counts.
6. Once the map passes acceptance, fill regional narrative, bosses, and side quests, then calibrate playtime using playtest data.

**The map is not complete because every region has a name. It is complete when players can build a mental map of an interconnected world and continually reinterpret it through new abilities, shortcuts, and Resonance discoveries.**
