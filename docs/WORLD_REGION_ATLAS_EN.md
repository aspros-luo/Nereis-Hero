# Nereis-Hero World Atlas: Macro Areas and Story Locations

> This is the current narrative map outline. It groups the world geographically and by faction first, then lists meaningful places within each area. It is not a player-facing map, and not every candidate needs to become a separate level. A0–A13 are existing greybox region IDs; the locations below are story-design names.

## Macro map brain map

Before detailing any small map, review [World Map Brain Map and Spatial Relationships](WORLD_MAP_BRAINMAP_EN.md) to assess the relative positions of the six macro areas, hub responsibilities, and major connections. Do not treat illustrative abilities or quests as mandatory while the macro layout remains under review.

## 1. Six macro areas

| Macro area | Existing regions | Core purpose |
|---|---|---|
| 1. Frontier Village and Wilds | A1, A2, A5 | Emotional starting point, village attack, forest/canyon/cemetery exploration, traces of frontier conflict |
| 2. Abandoned City and Underworks | A3, A4 | First major box-world hub linking rooftops, streets, sewers, reservoir and high drains |
| 3. Church Frontier and Cathedral Domain | A0, A6, A7, A10 | From border surgery site and monastery to detention facilities, grand cathedral and church leadership |
| 4. Royal City and Royal Necropolis | A8, A9, A12 | Outer city, inner city, palace, underground tombs and royal service routes |
| 5. Church Black Site and Ancient-God Ruins | A11 | Distinguishes human experimentation from ancient-god remains and core revelations |
| 6. Deep Dream and Endgame Anomaly | A13 | An ending-dependent space, not an ordinary geographic district |

These are not six linear levels. They interlock: sewers can return toward the village or reach royal tomb routes; the abandoned city links the frontier, church, and royal city; hidden paths connect the church's public domain to its research sites.

## 2. Places within each macro area

### 1. Frontier Village and Wilds

- **Frontier Village:** main street and square, residential back lanes, village barricade, rooftop walkways, old well.
- **Mistwood and Mountain Canyon:** forest floor, canopy, broken bridge, canyon bottom, cliff cave, old pilgrim high road.
- **Bell Tomb and Wild Cemetery:** cemetery perimeter, bell-tomb pit, sealed burial room, reversed-bell chamber.
- **Frontier Battlefield and Canyon Fortress:** trenches, corpse slope, collapsed wall, fortress wall, watchtower.

Story role: establish village life and character ties first, then reveal traces of church activity through the forest, cemetery, and battlefield. Do not explain the entire conspiracy in the prologue.

### 2. Abandoned City and Underworks

- **Abandoned City:** western entry, old market street, ruined homes, rooftop links, raised pipes, old chapel, the erased Third Street.
- **Sewers and Old Reservoir:** waste outlet, sedimentation hall, old sewer, middle waterway, reservoir, flooded lower channel, sluice machinery room.

Story role: the first true box-world hub, where players can reach familiar spaces from rooftops, street level, or below ground. Resonance-hidden places should change the player's understanding of the city's past, not merely award extra loot.

### 3. Church Frontier and Cathedral Domain

- **Border Surgery Site:** restraint theatre, observation gallery, abandoned ward, waste escape route.
- **Border Monastery and Bell Tower:** lower cloister, courtyard, upper gallery, middle tower, tower top, silent window.
- **Detention Camp and Confession Prison:** intake yard, cell corridor, lower cells, confession well, maintenance shaft, supply tunnel.
- **Grand Cathedral and Church Core:** pilgrim stair, nave, side aisles, choir gallery, silent side chapel, inner court/papal district.

Story role: show four faces of the Church—research, public worship, detention and punishment, and institutional power. A lab, detention camp, and upper church district need not each be a separate macro map; they may be subspaces or hidden branches inside existing regions.

### 4. Royal City and Royal Necropolis

- **Outer Royal Ring and Ruined Streets:** lower alleys, outer plaza, abandoned housing, rooftop walks, high royal drain, inner-city side gate, mirror street.
- **Royal Tombs and Old Necropolis:** tomb entrance, royal chambers, middle water channel, deep inscription gallery, royal maintenance shaft, erased-name corridor.
- **Inner Royal City and Palace:** service street, royal courtyard, wall walk, upper throne hall, royal freight lift.

Story role: the royal city should explain the relationship between crown, Church, and ordinary people, not just host the final battles. The royal tombs also provide historical revelations and underground transit, rather than being an isolated dungeon.

### 5. Church Black Site and Ancient-God Ruins

- Royal maintenance-shaft exit
- Church laboratory layer
- Ancient residue layer
- Outer primordial womb
- Primordial void

Story role: the upper layer still shows the order of human research facilities; deeper spaces increasingly defy human architecture, sound, and physical rules. Keep a clear visual and narrative boundary between the laboratory and the ancient-god remains, even if they occupy the same macro region.

### 6. Deep Dream and Endgame Anomaly

- Dream boundary
- Memory corridor
- Ending-specific arena

Story role: spaces and encounters change according to endings such as *A Grave for Mortals*, *Eternal Paradise*, and *The Scourge of Flame*. This is a state-driven endgame region, not a normal map to reveal in full ahead of time.

## 3. Connection rules: a network, not a level list

1. **Give each macro area at least two geographic relationships.** Beyond the main route, use underground passages, upper routes, hidden entries, or later return shortcuts.
2. **Every local connection needs a spatial reason.** Wells meet waterways; drains meet underground spaces; walls meet rooftops; tower drops meet old streets; maintenance shafts meet laboratories.
3. **A shortcut changes how the player understands space.** Open a gate, lower a ladder, restore a lift, operate a sluice, or discover a resonance passage; do not simply teleport.
4. **Lifts serve vertical loops.** Their stops belong to real subregions, and activation should reduce repeated traversal of dangerous areas without soft-locking the main route.
5. **Hidden places should belong to the area's theme.** A tomb hides erased royal names; the city hides a forgotten street; the tower hides reversed bells; the deep ruins expose the true object of experimentation.
6. **Layer narrative information through exploration.** Show a phenomenon first, then contradictory evidence, and let players assemble the truth.

## 4. Fill a lightweight story skeleton first

For each place, answer five questions:

- Why does the player come here?
- What happened here, or what is happening now?
- What key environmental clue can be found?
- Which area connects to it through a shortcut, lift, or hidden route?
- What changes in the player's understanding of the village, Church, crown, or ancient gods when they leave?

Enemy waves, reward values, full sidequest dialogue, and room-by-room combat pacing can wait until this layer is stable.

## 5. Relationship to existing topology data

`tools/world_map_topology.json` continues to hold A0–A13, C01–C24, and technical subregion/link contracts. The new `story_geography` field captures the narrative-facing relationship between areas, places, story purpose, and connections. If earlier engineering groupings conflict with geographic naming, use this atlas as the story-planning baseline and adjust the technical mapping accordingly.

## 6. Status

This is a **narrative-level world map synthesis**, not proof that every place is built or runtime-tested. Next, use this atlas to add short events, environmental clues, and area connections in exploration order while preserving the box-world's multiple routes and verticality.
