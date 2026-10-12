# Box-World Developer Bible

> Status: production specification / actively being completed  
> Target branch: `development`  
> This is an internal development reference, not a player-facing map guide. A design described only in documentation must never be reported as implemented.

## 1. Core principle: developer omniscience, player-limited knowledge

The team must be able to answer every question about every region: entrances, exits, unlock conditions, arrival points, enemies and encounter composition, rewards, failure costs, Insight revelations, return routes, and effects on world state or endings.

The released game must not expose the complete world map, every exit, hidden-region coordinates, enemy placement tables, reward lists, or ending conditions by default. Players should build a mental map through landmarks, sightlines, environmental storytelling, sound, enemy behavior, item descriptions, ability unlocks, and changes in Insight. Do not use meaningless mazes, arbitrary route closures, or indistinguishable corridors as a substitute for exploration design.

## 2. Information layers

| Layer | Contents | Player visibility |
|---|---|---|
| D0 Developer authority | Full topology, coordinates, door states, spawn points, enemies, rewards, penalties, dependencies, ending gates | Hidden |
| D1 Runtime state | Open doors, collected items, boss state, Insight thresholds, quest flags, shortcut state | Communicated indirectly through gameplay |
| P1 Player perception | Visible terrain, traversed space, recognizable landmarks, audible threats | Visible/audible |
| P2 Player inference | Guesses about unexplored paths, danger, history, and factions | Player-generated |
| P3 Hidden truth | Insight-revealed routes, erased spaces, world and ending truths | Revealed in layers when conditions are met |

If a map menu is added later, it may show only areas the character has actually explored and has a plausible reason to remember. It must not automatically reveal every door, secret exit, enemy, reward, or undiscovered area. A local sketch is a future implementation choice; the principle of not disclosing the complete map remains.

## 3. Current macro-topology baseline

- Main regions A0–A13: 14 total; A13 is the abstract endgame layer, leaving A0–A12 as 13 primary exploration regions.
- Official hidden regions H01–H08: 8. H09, “Cliffside Experimental Grotto,” is a candidate only and is not official canon.
- The topology currently registers 24 macro connections across main routes, shortcuts, underground routes, secret entrances, and ending entrances.
- Three macro loops are registered: L01 Border Loop A1–A2–A3–A4–A1; L02 Mid-layer Loop A3–A5–A6–A3; L03 Royal Deep Loop A4–A8–A9–A4.
- These figures are a design baseline, not proof of scene implementation or playtest acceptance. Each connection must be checked against scene anchors, interaction conditions, arrival points, and viable return routes.

The authoritative connection table is `tools/world_map_topology.json`. If the document, JSON, and scenes disagree, record the discrepancy instead of silently assuming one source is correct.

## 4. Required dossier for every region

Every A/H region must have a record for each field below. Unknown fields must be marked `TBD`; do not invent values and present them as implemented facts.

### 4.1 Space and routes
- Region ID, name, narrative role, unlock phase, expected player abilities.
- Entry/exit IDs, scene, interactable, world coordinates, trigger radius, door state.
- Destination region, destination spawn, facing, vertical offset, safe landing area.
- One-way/two-way, returnability, shortcut status, first-open condition, persistent/temporary state.
- Main paths, branches, loops, dead ends, secrets, ability gates, Insight gates, optional detours.
- Landmarks, sightlines, background silhouettes, environmental color/light/sound cues.
- Soft-lock, fall, doorway overlap, and spawn/interactable overlap checks.

### 4.2 Enemies and encounters
- Enemy instance ID, archetype, count, coordinates/area, patrol range, facing, aggro distance.
- Encounter type: solo tutorial, mixed formation, ambush, pursuit, ranged pressure, elite, boss.
- Activation, respawn, death persistence, cross-scene persistence, and bypass options.
- Encounter intent, spatial advantages/disadvantages, usable terrain, expected resource cost, difficulty rating.
- Variants tied to Insight, quests, world state, or endings.
- Every fight needs a design purpose; do not inflate playtime with bloated health or repetitive enemies.

### 4.3 Rewards and information
- Reward ID, category, exact location, acquisition condition, missability, repeatability.
- Categories: weapon/ability, upgrade material, healing/consumable, currency, key item, side-quest evidence, environmental narrative, shortcut, hidden area, ending-condition item.
- Why the reward is placed here; whether it teaches a mechanic, pays off risk, changes routing, or reframes the world.
- Alternate source if missed; quest/ending impact; irreversible consequences.
- Clue reliability, source character/faction, and contradictions with other clues.

### 4.4 Penalties and risk
- Damage, traps, falls, status effects, resource loss, alarms, reinforcements, route closure.
- Trigger, warning, counterplay, damage/loss range.
- Death respawn, resource recovery, enemy reset, and shortcut persistence rules.
- Whether the penalty is telegraphed, learnable, and a fair trade against the reward.
- No untelegraphed instant-kill trap unless a clear, readable special-case rationale exists.

### 4.5 Insight and hidden content
- Insight value/state threshold, trigger location, visibility change, audio/visual feedback.
- Whether the revelation is a physical path, interactable, enemy, item, text, or world anomaly.
- Fair environmental hints at low Insight; whether high Insight changes the player's interpretation of an old area.
- Alternative clues around the threshold; misleading-but-fair presentation.
- Every Insight change needs observable runtime feedback, not just a document entry.

### 4.6 Acceptance status
Use only these statuses:
- `DESIGNED`: designed, not implemented.
- `IMPLEMENTED_STATIC`: present in source/scene, not run in-game.
- `RUNTIME_CHECKED`: verified in Godot runtime.
- `PLAYTESTED`: checked through actual play.
- `ACCEPTED`: design, implementation, and experience accepted.
- `BLOCKED`: a concrete blocker exists.
Record evidence, test steps, version/commit, and known defects. Static review must not be presented as runtime verification.

## 5. Player-discovery rules

1. Show a landmark or hint of a route before the player reaches the entrance; confirm the connection only after discovery.
2. A shortcut should recontextualize space the player has already traversed. Opening it needs clear sound, animation, or scene feedback.
3. A hidden region must change understanding, routing, resources, or narrative—not merely add an empty room.
4. Insight should preferably reveal something that was already there but imperceptible, rather than making an ordinary door appear from nowhere.
5. Penalties should teach: enemy placement, terrain, audio, and visual telegraphs can all become player knowledge.
6. Do not list all enemies, rewards, and routes in the HUD or map; communicate fairness through readable environmental cues.
7. Temporary disorientation is acceptable; prolonged confusion caused by repetitive layouts, unreadable exits, or silent triggers is not.
8. Optional regions and ending truths may be missed, but this should be a meaningful trade-off, not concealment of a critical control rule.

## 6. Playtime and content density

Current estimates—not measured commitments—are 18–24 hours for a first ending, 22–28 hours for a relatively thorough first run, and 30–40 hours for multiple endings and high completion. These goals require meaningful route reuse, real shortcuts, ability-gated revisits, differentiated hidden regions, and sufficient boss/elite/narrative density—not simply longer corridors or tougher enemies.

For every region, record:
- Estimated blind main-route time, branch exploration, revisits, combat, and narrative reading.
- What is new on the first visit versus later revisits.
- Expected encounters, elites/bosses, supplies, checkpoints, key rewards, and missable content.
- Whether spatial and cognitive variation prevent meaningless repetition.

Update playtime only after real playtests, recording tester, route, completion, and deaths. Until then, label it an estimate.

## 7. Verification order

1. A2–A4: first core box-world cluster; verify the border loop, underground exits, return spawn, and doorway interaction range.
2. A5–A8: verify the mid-layer loop, bell-tower drop, low prison supply route, and royal-tomb waterway as a comprehensible network.
3. A9–A12: verify the late-game hub, royal drain, inner-city side gate, and secret entrances.
4. H01–H08: verify each threshold, revelation feedback, entry/exit route, and unique payoff.
5. A11/H08/A13: review ending dependencies against shared lore. A single intimate event must not become a hard gate for every major ending without explicit design justification.

## 8. Definition of done

The map may be declared development-accepted only when:
- Every region has a spatial, enemy, reward, penalty, Insight, and acceptance dossier.
- Every connection matches real scene anchors, door logic, and destination spawn.
- Primary regions form a legible network of multiple paths, loops, and shortcuts.
- Every hidden region has a clear discovery logic, unique payoff, and return route.
- No known soft locks, accidental one-way traps, doorway interaction conflicts, or unsafe spawn overlaps remain.
- Key encounters, rewards, and penalties pass runtime and blind-play checks.
- Chinese and English documentation are synchronized, with unimplemented/unverified items explicitly marked.
- The player-facing release does not expose the developer dossier.

## 9. Current gaps

The topology is only a macro-connection baseline. It does not prove that enemy placements, rewards, penalties, and trigger conditions are complete. Subsequent work must map actual scene content to these fields and update status with scene/source evidence. If Godot runtime testing is unavailable, reports must clearly distinguish static review from runtime acceptance.
