# Map Story Skeleton & Ability-Gated Backtracking (v1)

> This document translates the world atlas into buildable exploration beats. It is a narrative/level-design contract, **not proof that the maps, items, or mechanics are implemented in Godot**. The guiding triad is: **see it but cannot reach it yet; reach it but cannot understand it yet; understand it and then change it.**

## Rules

### Keep gate types distinct

- **Ability gate:** grappling hook, climbing, special jump, lockpicking, or future traversal skills. Terrain should communicate the intended use.
- **Resonance gate:** at a sufficient Resonance level or at a specific point of resonance, the player may perceive hidden entrances, disguised enemies, erased structures, or another layer of space. Resonance must not become a universal key for every secret.
- **Story gate:** a route or reward opens after a side quest, an NPC survives, evidence is found, a rumor is heard, or a faction state changes.
- **Combined gate:** important secrets may require two conditions—for example, obtain the grappling hook, then notice old anchor scars at high Resonance; or collect conflicting records before identifying the route to a research wing.
- **Physical gate:** water levels, lifts, ladders, latches, and broken bridges. These primarily create interconnected loops; not every door should be a stat check.

### Every secret needs a landmark and a meaningful payoff

On the first visit, players should remember a clear landmark: an iron ring on a cliff, a silent bell, an erased third street, an extra shadow on a wall, or a missing royal name. On return, reward them with at least one meaningful result: an ability or upgrade, a key item, an NPC outcome, worldbuilding evidence, a shortcut, or a new combat option. Avoid hiding only a common consumable in a difficult corner.

### Make blocked paths legible

Use visible silhouettes, rope rings, broken handholds, wind, anomalous echoes, visible loot, or NPC hints. A failed attempt should teach the player what is missing rather than make them suspect broken collision.

### Resonance has narrative limits

Low Resonance shows the human world. Medium Resonance reveals concealed or disguised traces. High Resonance exposes the Ancient God's influence over reality, but brings greater hostility, misrecognition, or misleading impressions. High Resonance does not make every vision objectively true: it reveals what has been suppressed; the player must cross-check documents, NPCs, and environments.

### Reward cadence

- Early: small traversal lesson, village side quest, first return route.
- Midgame: a familiar place gains a new interpretation; shortcuts and character quests intertwine.
- Late: Resonance and key items combine to uncover deeper Church/Ancient God secrets.
- Endgame: the ending changes the arena and character fate; do not explain every branch with a generic keycard.

---

## Region I — Border Village & Wilderness

### S01 Village Street, Blacksmith, and Hunter's Hut

- **Why go there:** Hero has been rescued by villagers and needs to recover. After the raid, repairing equipment and finding missing people become urgent.
- **Characters/events:** The blacksmith distrusts the Church's official account; the hunter knows the outer cliffs and old hunting paths. Their quests should express “repairing a life” and “surviving the wild,” not merely trade an item for equipment.
- **Environmental clue:** A Church-standard restraint chain has been cut in the forge. A corner is missing from the hunter's map, which marks old iron anchors along a cliff.
- **Gate/backtracking:** Complete the hunter's quest, recover materials, and ask the blacksmith to repair the gear to receive the **grappling hook**. It opens a cliff face visible from the village but previously unclimbable. Reuse the hook at a few clearly marked points in later districts, including the bell tower and city rooftops.
- **Payoff:** A small hidden map such as the Windworn Lookout, with a traversal/combat upgrade, a hunter heirloom, and evidence pointing toward the border battlefield.
- **Knowledge gained:** Villagers are not merely waiting to be saved; they know routes erased from official maps.
- **Implementation note:** Show at least two recognizable anchor points before the hook is acquired. Make the first secret short and rewarding, then use the hook for more complex routes.

### S02 Village Defenses and Raided Homes

- **Why go there:** After the Church-and-bandit raid, Hero follows the attackers' trail and helps survivors.
- **Event/clue:** Arrows, Church wax seals, and bandit supply marks are mixed together, suggesting the raid was not simple opportunistic robbery. Do not reveal the whole conspiracy immediately.
- **Gate:** A side quest lets villagers repair a walkway or open a defense gate, creating a loop toward the old street/city.
- **Payoff:** A safe resupply point, changed NPC states, and a non-main-route connection toward A3.
- **Knowledge gained:** Someone may have disguised Church operations as bandit violence, but the evidence does not yet identify the person who ordered it.

### S03 Mistwood, Broken Bridge, and Canopy Trail

- **Why go there:** Search for missing villagers, hunter marks, or stolen supplies.
- **Gates:** The ground route is initially available; the ravine below the broken bridge is a detour; the canopy route requires the hook. At higher Resonance, marks on tree trunks form a complete direction.
- **Clue:** Animal carcasses remain uneaten, with wounds resembling experimental instruments. Birdsong abruptly stops near the old pilgrim road.
- **Payoff:** Hunter-quest resolution, rare materials, and a hidden hollow or small encounter. Do not turn the woods into a mandatory maze.
- **Knowledge gained:** The anomaly may come from Church experiments or something older; the game should not decide for the player yet.

### S04 Bell Tomb, Wilderness Graveyard, and Inverted Bell Chamber

- **Why go there:** Follow missing-person clues or the old anchor/road marks mentioned by the hunter.
- **Gates:** The graveyard perimeter is open; a sealed crypt uses a physical mechanism; the Inverted Bell Chamber requires a Resonance threshold or a record found elsewhere.
- **Clue:** Royal names have been scraped from tombstones while villagers' stones were re-engraved. At high Resonance, the bell sounds before it is struck.
- **Payoff:** Early evidence of the “erased royal names” motif, a rare upgrade material, and a vertical shortcut to the canyon road.
- **Knowledge gained:** The kingdom's past was not merely forgotten; someone actively edited it.

### S05 Border Battlefield and Canyon Fortress

- **Why go there:** Follow a Church convoy, a restoration-army supply line, or a merchant's account of the old battlefield.
- **Gates:** Trenches form the main route; the hook opens a high route along the wall/watchtower; the quartermaster's availability depends on story progress.
- **Clue:** Old military orders credit the royal house with the war, while Church inscriptions call it a divine mandate. Both accounts are incomplete.
- **Payoff:** Military supplies, a restoration-army quest, and a high connection to the city.
- **Knowledge gained:** Church and crown have long used each other; neither can be reduced to a faction that always controlled the other.

## Region II — Abandoned City & Underground Waterways

### S06 Old Market, Ruined Homes, and Rooftop Walkways

- **Why go there:** Follow the raiders, merchant clues, or a route into Church territory.
- **Box-world layout:** Street level hosts encounters and clues; rooftops bypass barricades and preserve sightlines to landmarks; drains connect to the underground water system. Let players see an upper door from below before returning with a hook or lift.
- **Clue:** A house has two addresses on official maps. A resident's ledger mentions a “Third Street” that does not exist.
- **Gate:** Physical mechanisms open the rooftop loop. At medium Resonance, the entrance to Third Street appears, but a latch must still be opened from the other side.
- **Payoff:** Merchant quest progress, a unique item, and a shortcut to the outer royal district.
- **Knowledge gained:** Resonance exposes erased city structures, but ledgers and physical evidence must corroborate the vision.

### S07 Sewers, Old Reservoir, and Sluice Control Room

- **Why go there:** Bypass the Church blockade, trace abducted people, or restore power to an old city lift.
- **Gates:** Valves, water levels, and sluice gates change routes. A low channel returns to an early region. High Resonance may reveal an unnatural silhouette beneath the water, but it is not automatically a walkable platform.
- **Clue:** Waste records show that some “medical effluent” was sent to a royal maintenance shaft, not outside the city.
- **Payoff:** A major shortcut, a hidden sediment chamber, and an entrance to the mid-level royal tomb waterway.
- **Knowledge gained:** The Church's secret facilities connect to royal infrastructure; the investigation now implicates national power.

### S08 Erased Third Street and Old Chapel

- **Why go there:** Find the entrance through a ledger, Resonance, or an old city map from the merchant.
- **Gate:** Medium-to-high Resonance reveals the street's afterimage; the player must open a latch from the rooftop/underground side to enter physically. Resonance alone cannot pass through walls.
- **Clue:** Figures in the street's afterimage face a chapel door that is no longer there. Physical records say the chapel was demolished long ago.
- **Payoff:** Important evidence, a unique charm, or a perception/Resonance upgrade.
- **Knowledge gained:** The structure may be erased history or a place still overlaid by an anomaly; the answer remains incomplete.

## Region III — Church Marches & Cathedral Lands

### S09 Border Surgical Ward and Escape Route

- **Why go there:** Hero's amnesia, bodily marks, and opening escape are central to the main story.
- **Constraint:** The opening offers sensory fragments, restraints, and torn observation notes. Hero must not immediately understand the experiment or Mite's true identity.
- **Gate:** The escape tunnel provides the initial one-way departure. On a later visit via drains/maintenance passages, the player can reach the previously locked observation gallery and archive.
- **Clue:** Hero is catalogued as a disposable subject. Staff call the procedure “faith adaptation,” while the instruments carry inexplicable ancient markings.
- **Payoff:** Evidence about Hero's altered body, a shortcut into Church territory, and a partial—not complete—revision of his memories.
- **Knowledge gained:** The Church used Hero as a subject, but the experiment's true result remains uncertain.

### S10 Monastery, Bell Tower, and Silent Window

- **Why go there:** Find a way past the Church border or investigate missing monks.
- **Gates:** The tower has multiple vertical routes. The hook reaches exterior beams; at a Resonance threshold, the player notices a window that returns no echo.
- **Clue:** Prayers, bells, and architectural shadows disagree. A monk's diary records two different bells on the same night.
- **Payoff:** A vertical shortcut, a hidden chapel, and an early reliable clue about Resonance.
- **Knowledge gained:** Ritual may conceal anomalies, but not every believer knows the truth.

### S11 Detention Camp, Confession Prison, and Supply Tunnel

- **Why go there:** Rescue captured villagers, trace disappearances, or help the restoration army obtain a prisoner list.
- **Gates:** The public route frees some prisoners. A hidden cell requires evidence or high Resonance to identify an anomalous wall. The supply tunnel loops back to the monastery/city after its far latch is opened.
- **Clue:** The prisoner list includes villagers, heretics, failed subjects, and Church staff purged by internal politics.
- **Payoff:** NPC outcome branches, a supply route, and testimony from an insider.
- **Knowledge gained:** Church oppression also targets its own members as part of internal power struggles.

### S12 Grand Cathedral, Inner Sanctum, and Papal Quarter

- **Why go there:** The main story reaches the Church's center of power; side quests determine available evidence and allies.
- **Box-world layout:** Nave, side aisles, choir gallery, and inner sanctum loop together. A seemingly sealed upper level can be revisited from the tower/roof. The secret research entrance must be grounded in a royal maintenance route or relevant evidence.
- **Clue:** Public sermons call faith a pure miracle; internal documents describe it as a resource that can be extracted, allocated, and reproduced.
- **Payoff:** Major faction choices, core Church evidence, and connections to the royal city or research complex.
- **Knowledge gained:** The Church has converted faith into a technology of power. Whether the crown was truly ignorant must be resolved in the royal district.

## Region IV — Royal City & Royal Tombs

### S13 Outer City, Inner City, and Mirror Street

- **Why go there:** Trace Church finances/shipments, meet restoration forces, or reach the palace.
- **Gates:** Gates, rooftops, and high drainage channels form three layers. The hook is used only at marked anchors. Resonance reveals an older street scene overlaid on Mirror Street.
- **Clue:** Royal monuments credit conquest to the crown; Church monuments credit divine revelation. Both omit the cost paid by ordinary people.
- **Payoff:** City shortcuts, merchant/quartermaster quest outcomes, and clues to the royal tomb.
- **Knowledge gained:** Crown and Church have shared legitimacy for generations; the conflict is not simply a good king versus an evil Church.

### S14 Royal Catacombs, Erased-Name Gallery, and Maintenance Shaft

- **Why go there:** Enter from the city waterways or palace district to find royal records and the real route to the research complex.
- **Gates:** Waterways and lifts establish a loop. Resonance reveals erased inscriptions, but records collected from both ends are needed to interpret them.
- **Clue:** Royal maintenance logs record the sealing and periodic inspection of an ancient site. Later logs rewrite the work as ordinary water-system maintenance.
- **Payoff:** Evidence needed to access the secret research complex, fragments of ancient royal history, and a major upgrade material.
- **Knowledge gained:** The crown knew at least part of what lay below. Whether it collaborated willingly or was gradually sidelined remains to be established.

### S15 Palace, Throne Gallery, and Royal Freight Lift

- **Why go there:** Follow the restoration route, confront the main story, or investigate the king's relationship with the Church.
- **Gates:** Service streets, courtyards, and wall walks interconnect. The freight lift reaches the maintenance level after power is restored elsewhere or a pass is obtained.
- **Clue:** The king's orders show he knew the Church was eroding royal authority, but feared open conflict would collapse the kingdom. This explains his choice without absolving him.
- **Payoff:** Evidence central to the royal route, a palace loop, and confirmation of faction states before the ending.
- **Knowledge gained:** The king is neither an omniscient mastermind nor an innocent bystander; his compromises caused real suffering.

## Region V — Secret Research Complex & Ancient God Ruins

### S16 Church Lab, Ancient Remains, and Primordial Hollow

- **Why go there:** Enter through the royal maintenance shaft, a secret inner-sanctum passage, or an anomalous route perceived at high Resonance.
- **Spatial boundary:** The lab retains human lights, numbering, records, and maintenance rails. Beyond the boundary, geometry destabilizes; walls seem grown rather than built.
- **Gates:** The ordinary route reveals the lab. High Resonance exposes hidden links and residual forms. Key evidence lets players identify the actual purpose of some mechanisms.
- **Clue:** The Church renamed Ancient God residue “grace medium” to disguise it as traditional faith. Lab notes contradict ritual texts.
- **Payoff:** Endgame routes, fragments needed for the Third Cord side quest, and clues about Mite's connection to the Ancient God—without telling Hero who Mite truly is.
- **Knowledge gained:** The player may assemble a fuller truth than Hero. Player knowledge and character knowledge can remain different for a long time.

## Region VI — Deep Dream & Endgame Visions

### S17 Dream Boundary, Memory Corridor, and Ending Arenas

- **Why go there:** Access depends on key items, relationships, Resonance, and main-story choices. This is not a normal map available for casual return.
- **Grave of Mortals:** Preserve incomplete knowledge; focus on the Church's fall, the restoration army's victory, and the irony that it may become the next Church. Do not force every player to see the full Ancient God truth.
- **Eternal Paradise:** After physical union, Hero gradually becomes an Outer God vessel. The space uses tender, familiar, and illogical village memories to make the dream feel desirable; do not rely on a red/black filter alone.
- **Inferno's Judgment:** Hero has physically united with Mite but is not fully controlled. The Third Cord is assembled from evidence/relics earned across several side quests. The ending stresses that neither can fully control the result; there is no perfect victory.
- **Gates/payoff:** The arena, enemies, Mite's presentation, and final encounter change according to state. Ending variants must not be reduced to swapping a boss texture.
- **Knowledge gained:** The mortal route carries the cost of ignorance; the paradise route shows peace swallowed by desire; the inferno route shows resistance succeeding at an irreversible cost.

## Ability and gate register

| Mechanic | First taught | First visible blocker | Return use | Constraint |
|---|---|---|---|---|
| Grappling hook | After hunter/blacksmith quest | Iron anchors on village cliff | Windworn Lookout, tower exterior, city high routes | Show anchors first; not every wall is climbable |
| Physical mechanisms | Village defense / sluice | Ladders, latches, sluices, lifts | Open loops, change water levels, reconnect districts | Create real spatial loops |
| Medium Resonance | Mistwood or bell tower | Erased marks / anomalous echo | Third Street, Silent Window, royal inscriptions | Reveals clues, does not auto-open doors |
| High Resonance | Mid/late Ancient God sites | Hidden links and reality overlays | Research complex / dream clues | Carries danger, misdirection, or a cost |
| Story evidence | Merchant, Church clerk, quartermaster quests | Sealed archives / faction routes | Inner sanctum, royal shaft, ending branches | Reasoning should not collapse into one key |
| Combined side-quest relics | Multiple side quests | Irreversible endgame gate | Inferno's Judgment route | Each component needs independent use and text |

## Lightweight implementation order

1. **Build one verifiable traversal loop:** hunter quest → hook → village cliff → small secret map → reward/clue → return to familiar ground.
2. Add Resonance revisits: see an anomaly first → progress normally and raise Resonance → revisit to perceive a new structure → still need a physical mechanism or evidence to proceed.
3. Build the city's vertical box-world: gradually connect street, rooftops, and underground; show later routes before they become accessible.
4. Connect character quests and faction states to the Church, royal city, and endings. Do not implement every complex condition at once.

**Acceptance criteria:** Players can explain why a place is currently unreachable; recognize old landmarks after acquiring a skill; find secret rewards tied to local story; experience Resonance as meaningful knowledge rather than a simple visual filter; and have readable hints plus a return route for every critical path.
