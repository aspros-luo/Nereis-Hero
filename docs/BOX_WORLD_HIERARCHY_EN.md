# Nereis-Hero Box World: Macro Regions, Subregions, Connections and Lifts (v1.0)

> This is a developer-facing design record, not player-facing map content. The machine-readable contracts live in `tools/world_map_topology.json`. Static design data does not prove that scenes are implemented or runtime-tested in Godot.

## 1. Five macro regions

| ID | Macro region | Included regions | Design responsibility |
|---|---|---|---|
| M1 | The Frontier and Mistwood | A0, A1, A2 | Prologue, first hub, and vertical-navigation tutorial through canopy paths and wells |
| M2 | The Abandoned City and Underworks | A3, A4 | First major hub: rooftops, raised pipes, inspection galleries, waterways, and reservoir layers |
| M3 | Battlefield, Monastery, Prison and Royal Tomb | A5, A6, A7, A8 | Deep loops through walls, bell tower, confession well, maintenance shafts, and tomb waterways |
| M4 | Outer Royal Ring and Grand Cathedral | A9, A10 | Late-game hub with rooftop routes, cathedral galleries, high drains, and service gates |
| M5 | Inner City and Primordial Depths | A11, A12, A13 | Distinct royal and primordial routes; ending spaces react to player state |

Macro regions organize the world; they are not five isolated maps. Existing cross-region IDs C01–C24 remain stable. New subregion links use SC IDs and lift contracts use LFT IDs.

## 2. Subregion principles

The `subregions` array enumerates spaces that can be navigated, populated, and tested independently. Each entry has an ID, parent region, name, layer, and design role.

- **Ground** supports first-pass navigation, major encounters, and readable landmarks.
- **Upper/tower** spaces must communicate their relation to the ground through sightlines and architecture, not coordinate offsets alone.
- **Underground** routes use believable wells, stairs, service hatches, waterways, cells, and tomb passages.
- **Deep/anomalous** spaces carry resonance discovery and shifts in world perception; they should not all be isolated reward rooms.
- A subregion may have multiple entrances and exits. Different entrances should change arrival height, sightline, encounter pressure, or information order whenever practical.

## 3. Local links, shortcuts and loops

The `intra_region_connections` array defines source and destination subregions, link type, travel direction, initial state, unlock condition, and design note.

- `walk`: streets, bridges, or corridors.
- `stairs`, `climb`, `ladder`: legible vertical movement.
- `drop`: a fall/drop route. One-way drops require a return plan or an explicit risk choice.
- `hatch`, `gate`, `winch`: mechanisms that open a passage.
- `lift`: a physical lift whose behavior must match an entry in `elevators`.
- `resonance`: a hidden route discovered through sound, silhouettes, reflections, or environmental feedback—not a visible developer marker.
- `loop`: an authored loop that must exist in physical space, not only in data.

A meaningful shortcut must shorten a known route, change arrival elevation, allow entry from the opposite side, or provide a safer return. Teleporting the player beside the same door is not sufficient.

## 4. Lift contracts

Eight lifts are specified:

| ID | Lift | Connection | Gameplay purpose |
|---|---|---|---|
| LFT01 | Mistwood counterweight platform | A2 ground–canopy | Safe return from canopy exploration |
| LFT02 | Sedimentation Hall service cage | A4 upper gallery–bottom shaft | Vertical underworks transport; retain an alternate route before power is restored |
| LFT03 | Bell Tower counterweight lift | A6 courtyard–tower top | Safe vertical return, distinct from the risky C10 drop |
| LFT04 | Prison maintenance cage | A7 corridor–shaft bottom | Internal prison transport without replacing C12 |
| LFT05 | Royal Tomb stone platform | A8 chambers–middle waterway | A revisit loop inside the tomb |
| LFT06 | Outer Ring freight lift | A9 lower streets–roof station | Combines with cross-region C16 for the late high route |
| LFT07 | Inner City cargo lift | A12 service street–maintenance level | Connects the inner-city ground and wall/service routes |
| LFT08 | Throne Hall counterweight lift | A12 wall walk–upper throne hall | Changes arrival height without changing ending eligibility |

Each lift requires a visible shaft and landing points, initial state, unlock condition, operation feedback at both ends, sound/animation, reachability checks, and a persistence policy for death and save/load. A broken or locked lift must not soft-lock the main path; keep a ladder, stairs, or a riskier alternate route where needed.

## 5. Implementation order

1. Build a verifiable A1–A4 vertical slice: ground, canopy/rooftops, raised pipes, waterways, and well bottoms.
2. Build A5–A8: trenches and walls, monastery tower, prison shaft, and the royal tomb middle waterway.
3. Build the A9–A12 rooftop route, cathedral gallery, high drain, inner-city service gate, and lifts.
4. Connect H01–H08 and A11/A13; test resonance discovery, returns, and independent ending conditions.
5. Validate each link through: design contract → scene geometry/entity → runtime gate state → arrival/return points → save/death recovery → in-engine Godot acceptance.

## 6. Player-information boundary

The complete developer map, subregion inventory, enemy placements, rewards/penalties, hidden entrances, and shortcut states are internal design data. The released game should guide players through landmarks, environmental cues, sound, local clues, and resonance—not expose this full design record or a complete developer map.

## 7. Acceptance status

This update establishes five macro regions, a subregion inventory, local-link contracts, and eight lift contracts. It is a **design-data expansion**, not a claim that all lifts, mechanisms, or scene connections are implemented. Each contract must be mapped to Godot scenes and runtime logic, with static checks and in-engine acceptance recorded separately.
