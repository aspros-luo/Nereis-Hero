# Nereis Hero

A 2D Soulslike action RPG in the Nereis / 蜜忒之歌 universe.

## Current playable direction

Development has moved beyond the original Core Combat Demo into the first narrative production pass.

The current default flow is:

**Church surgical ward → escape → remote village → Mite → Church / village investigation**

Godot project startup scene (boot / save-resume routing):

`res://scenes/boot.tscn`

New-run opening scene:

`res://scenes/escape_prologue.tscn`

The original combat demo remains available at:

`res://scenes/combat_demo.tscn`

Development working charter (Chinese / English):

`docs/DEVELOPMENT_WORKING_CHARTER_CN_EN.md`

## Current narrative foundation

Canonical story memory:

`docs/DEVELOPER_STORY_MEMORY.md`

World map master plan (Chinese draft):

`docs/WORLD_MAP_MASTER_PLAN_CN.md`

Phase I level topology (Chinese draft):

`docs/LEVEL_TOPOLOGY_PHASE_1_CN.md`

Full world network topology (Chinese draft):

`docs/WORLD_NETWORK_TOPOLOGY_CN.md`

Complete world map atlas (Chinese draft):

`docs/COMPLETE_WORLD_MAP_ATLAS_CN.md`

Macro world-map brain map (Chinese / English):

- `docs/WORLD_MAP_BRAINMAP_CN.md`
- `docs/WORLD_MAP_BRAINMAP_EN.md`

Second-round macro spatial layout and C01–C24 connection audit (Chinese / English; design review, not runtime acceptance):

- `docs/WORLD_MAP_SPATIAL_REVIEW_CN.md`
- `docs/WORLD_MAP_SPATIAL_REVIEW_EN.md`

Interconnected box-world design principles (Chinese; authoritative map-design constraints):

`docs/INTERCONNECTED_BOX_WORLD_DESIGN_CN.md`

Box-world structural re-audit (Chinese, 2026-10-12):

`docs/BOX_WORLD_REAUDIT_2026-10-12_CN.md`

Box-world structure re-audit and current spatial fixes (Chinese):

`docs/BOX_WORLD_STRUCTURE_REAUDIT_CN.md`

Map-first content completion roadmap (Chinese):

`docs/MAP_CONTENT_COMPLETION_ROADMAP_CN.md`

Map-first content completion roadmap (English):

`docs/MAP_CONTENT_COMPLETION_ROADMAP_EN.md`

M1 box-world route implementation log (Chinese; code committed, Godot runtime acceptance pending):

`docs/M1_BOX_WORLD_IMPLEMENTATION_LOG_CN.md`

A3 Forgotten City layered spatial design (Chinese; geometry and route wiring implemented, runtime acceptance pending):

`docs/MAP_DESIGN_A3_FORGOTTEN_CITY_CN.md`

World map atlas diagram (SVG):

`docs/assets/COMPLETE_WORLD_MAP_ATLAS.svg`

Map validation and resonance hidden areas overview (Chinese):

`docs/MAP_TOPOLOGY_VALIDATION_AND_HIDDEN_AREAS_CN.md`

Detailed static world map validation report (Chinese):

`docs/WORLD_MAP_VALIDATION_REPORT_CN.md`

Machine-readable world map topology:

`tools/world_map_topology.json`

Repeatable static topology validator:

`python3 tools/validate_world_map_topology.py`

A2–A4 / H01 first-loop graybox notes and runtime acceptance checklist (Chinese):

`docs/GRAYBOX_A2_A4_IMPLEMENTATION_CN.md`

A5–A8 main-route graybox extension notes (Chinese):

`docs/GRAYBOX_A5_A8_IMPLEMENTATION_CN.md`

A9–A12 main route and H07 Mirror Street graybox notes (Chinese):

`docs/GRAYBOX_A9_A12_IMPLEMENTATION_CN.md`

Graybox scene wiring static checker:

`tools/validate_graybox_scene_wiring.py`

Resonance / hidden regions design — 8 optional subareas (Chinese):

`docs/RESONANCE_HIDDEN_REGIONS_CN.md`

Hidden map network diagram (SVG):

`docs/assets/RESONANCE_HIDDEN_AREAS.svg`

Director plan:

`docs/DIRECTOR_NARRATIVE_PLAN.md`

Short story foundation:

`docs/STORY.md`

The three canonical endings are:

- **凡人之墓**
- **永恒乐园**
- **烈火天罚**

The Hero / Mite relationship is a central emotional axis.

Mite is genuinely pure and initially unaware of the Outer God's larger reality.

Hero never knowingly learns her true identity during the main story.

The Church's ancient-god experimentation leaves residue inside Hero.

Much later, Hero and Mite's physical relationship becomes the bridge between the ancient-god residue and the Outer-God influence.

## Current implemented production work

### Opening

- Playable Church surgical ward escape
- Three Experiment Wardens
- Surgical residue clue
- Prologue checkpoint
- Transition into the village

### Village / Mite

- Playable Village Hub
- First Mite meeting
- Mite interaction progression
- Hidden relationship facts instead of a visible romance meter
- Rushed mainline progression can cause the Mite connection to be missed
- Missed connection returns as a quiet empty-chair scene
- Procedural lullaby motif tied to the village

### Hidden investigation

- Persistent hidden artifact evidence state
- The hidden resistance anchor is assembled from multiple independent story sources. H09's provisional relic is not wired into ending progression; its final role remains undecided.
- Ancient research ward
- Graveyard bell story
- Restoration order
- Route memory echo
- Evidence is not exposed as a "true ending checklist"

### World-map graybox — connected main-route slice

- A2–A12 have programmatic graybox scenes; H01 Well Below the Well and H07 Mirror Street have dedicated hidden-region scenes.
- A11 Deep Research Depths and H08 Primordial Hollow have now been added using the shared graybox controller, with distinct environmental landmarks and scene-resume mappings.
- R01–R08 are connected as one-time anomaly investigations. R01 unlocks the existing Resonance Sight ability; R04–R06 use minimum exposure floors to avoid permanently locking optional content.
- H01 has persistent discovered / opened / entered states shared by its village and A4 entrances; the A4 return hatch is a one-time unlock.
- After the village defense, A1 has two main exploration directions: A2 through the old pilgrim road, or A3 through the old drainage passage. A3 returns to A1 and also connects to A2, A4, and A5.
- A2 now has an optional canopy platform route; A3 has an optional rooftop loop plus a local Resonance Sight bridge that can be permanently anchored in the same map; A4 has a raised pipe-walk route alongside the ground path.
- A5–A8 now have distinct optional upper routes: battlefield parapet, monastery side balcony, prison maintenance catwalk, and royal-tomb gallery.
- A9–A12 now have optional upper traversal routes: outer-ring rooftops, cathedral choir gallery, research observation bridge, and inner-city crown wall.
- H01–H08 have distinct upper/returning route motifs. H09 is a provisional candidate and is excluded from the canonical map count until the structure review decides whether to keep it.
- A5, A7, A10, and A12 now have persistent environmental evidence sources covering the battlefield's rewritten history, prisoner transfers, the church's double-sealed relic, and the king's knowledge of church experiments.
- H01–H08 contain unique one-time environmental evidence sources. H09's conditional boss-and-relic route is provisional and not part of the canonical hidden-area set; clues do not grant free resonance or ancient/outer-god exposure.
- A1 now includes a 17-segment optional rooftop traversal line and a village-hearth rest point; A0's surgical ward now has a six-platform maintenance catwalk that does not bypass the warden lock.
- A2–A12 each have a region-specific rest point; canonical hidden regions H01–H08 intentionally do not grant free rest points. H09 is provisional. These are graybox code additions, not yet runtime-verified.
- H07 requires Resonance Sight, resonance ≥ 68, outer exposure ≥ 12, the outer-god story flag, and the R07 evidence source. Its A12 shortcut stays locked until the player reaches the Inner City and opens the far-side gate.
- A11 can be reached from A8 through C15 (Royal Tomb maintenance shaft) or A10 through C19 (Silent Chapel). Each path has its own persistent gate ID while both record entry to A11. R08 raises resonance to 78 and adds the planned outer exposure.
- H08 requires resonance ≥ 78, ancient exposure ≥ 2, outer exposure ≥ 18, the outer-god story flag, and three prior anomaly sources. A12 routes through the shared ending evaluator; H08 offers an optional deep-dream exit only after the physical-union story state.
- H09 Cave Beneath the Cliff, its mad cleric, specimen, and candidate relic remain a provisional implementation pending map review; the relic does not affect ending eligibility and none of these details are locked story requirements. Recent platform and A3 route edits are code-wired but still require Godot 4.6.x runtime acceptance. A13 remains a topology-level ending layer rather than a dedicated standalone scene.

Implementation notes and acceptance checklists:

`docs/GRAYBOX_A2_A4_IMPLEMENTATION_CN.md`

`docs/GRAYBOX_A5_A8_IMPLEMENTATION_CN.md`

`docs/GRAYBOX_A9_A12_IMPLEMENTATION_CN.md`

`docs/GRAYBOX_A11_H08_IMPLEMENTATION_CN.md`

### Combat

- Weighty 2D action foundation
- Three-step attack rhythm
- Dodge / invulnerability
- Stamina
- Hit-stagger
- Hitstop feedback
- Cultist / Pale Hound pressure patterns
- Two-phase Ashen Knight
- Procedural combat audio

### Director test theaters

**F7 — Church Final Boss Theater**

High Priest human phase → ancient-god phase → King.

**F8 — 烈火天罚 Theater**

100 cultists → Mite → waiting / self-sacrifice → city detonation.

The 100 cultist count is intentionally a spectacle. Future crowdfunding can optionally turn the crowd into supporter cameos.

### Debug

- F1 — candidate-driven endgame theater
- F2 — Eternal Paradise Theater
- F3 — debug overlay
- F4 — Ancient Research Ward
- F5 — Village Defense Theater
- F6 — Mite Resonance Theater
- F7 — Church Final Boss Theater
- F8 — 烈火天罚 Theater
- F9 — clean reset

## Narrative style

The game favors discovery rather than exposition.

The main references are:

- Dark Souls
- Bloodborne
- Blasphemous 2
- The Song of Saya
- Neon Genesis Evangelion
- Biblical Eden imagery
- Lovecraftian cosmic horror

These are reference influences, not content to copy.

The intended narrative language is:

**items as evidence + environment as narrative + NPCs as biased witnesses + contradictory memories + recurring symbols + emotional subtext**

## 地图测试与中文版文字对齐

地图实机验收入口（中文完整用例、F10 调试面板、存档保护说明）：

- [地图测试模式与完整验收用例](docs/MAP_TEST_MODE_AND_ACCEPTANCE_CN.md)

当前地图测试面板支持 A0–A12 中已实现的场景、正式隐藏区域 H01–H08，以及临时候选 H09 的独立调试传送，并提供灵视条件和全地图连通测试预设。**请先进入已有存档，再按 F10 开启地图测试模式；不要按 F9 或开始新游戏。** 测试模式会暂停正式存档写入，结束时可选择重新读取磁盘存档。

H09 崖下实验窟目前包含条件回访与实体遗物拾取，但仍是临时候选，不计入正式地图验收，也不代表其具体剧情已确定。中文界面的地图测试面板与调试 HUD 已开始对齐；完整游戏仍需逐场景审查所有玩家可见文本，未完成审查前不宣称全项目中文化已完成。

## Save / Resume

The default startup goes through:

`res://scenes/boot.tscn`

A completed prologue resumes from the last persisted story location. F9 clears the run and starts the prologue again.

## Engine

Godot 4.6.x / GDScript / GL Compatibility.

## Runtime verification

The maintainer environment does not contain a Godot executable, so interactive frame-level runtime acceptance must still be performed locally with Godot 4.6.x.

Repository structure and source changes are continuously checked.

## Branch

Development happens on:

`development`

Do not add or trigger GitHub Actions for this project.

## Production rule

When implementation reaches a major unresolved story decision — especially Hero/Mite history, the four hidden resistance side stories, the final antagonist's political motive, the Outer God's identity, or the exact ending condition — stop coding that story layer and return to story design.

For ordinary gameplay, combat, UI, effects, technical systems and presentation, development can proceed autonomously.

### World-map terminal layer update (2026-10-12)

The A13 terminal anomaly is now represented by `scenes/terminal_anomaly.tscn` rather than remaining a topology-only node. The A12 main route and the gated A11/H08 deep-dream routes converge on A13, which delegates the final choice to the existing ending evaluator. Save/resume mapping and static wiring contracts were updated. This is source-level integration only; Godot traversal and ending transitions remain unverified.
