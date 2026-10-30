# Nereis Hero — Development Status

Date: 2026-10-24

## Current A2 terrain design continuation — 2026-10-24

- Added version-controlled SVG engineering blueprints for R04 Crypt Landing, R05 Old Pilgrim Highroad, and R06 Eastern Ravine under docs/maps/. They use existing room-local platform positions as a starting coordinate reference and overlay intended route links.
- These drawings are design drafts only: dashed arrows are planned routes, not proof that exits/transitions exist or are playable. Godot scene geometry and room runtime still need to be reconciled with them.
- Next step: expand/revise R04-R06 geometry where needed, author explicit editor-visible entry/exit markers, then implement and validate the shared room runtime. No A1 route switch has been made.

## Current A2 restart status — 2026-10-24

- Current design authority: docs/maps/A2_DESIGN_BASELINE_CN.md.
- Six A2 terrain scenes exist, but scenes/ash_forest.tscn still assembles them as one continuous map; A1 North Gate still routes to ash_forest.tscn.
- Geometry audit found the existing local scene coordinates do not yet match the coordinate extents recorded in the available Canva R01–R03 designs. Do not switch A1 to a terrain-only room scene before the shared room runtime and connection contract exist.
- Canva region overview, R01, R02, and a candidate R03 design are located. Creating separate R04–R06 Canva designs was blocked by quota_exceeded; no retry was made.
- Documentation governance and first-round cleanup are recorded in docs/PROJECT_DOCUMENTATION_GOVERNANCE_CN.md and docs/REPOSITORY_CLEANUP_AUDIT_2026-10-24_CN.md.
- A new structural validator, tools/validate_a2_room_scene_geometry.py, replaces the obsolete validator that parsed the retired procedural A2 platform branch. It has not been run locally; Godot runtime acceptance remains pending.
- Next A2 milestone: reconcile six room-local geometry and explicit entry/exit positions, then implement the shared room runtime while preserving C03/C04/H02, save/resume, checkpoints, and death recovery.

## Current direction

The project is now in the first **narrative production pass**, not merely a combat prototype.

Default startup:

`res://scenes/boot.tscn`

Boot resolves to:

- Church escape on a fresh run
- persisted narrative location after the prologue is complete

## Implemented production content

### Opening

- Church surgical ward
- 3 Experiment Wardens
- surgical residue clue
- checkpoint / death reset
- playable escape to village

### Village

- Village Hub
- Mite first meeting
- place-based relationship rhythm
- Mite House chapter
- private-house union trigger after relationship progression
- Tavern Mite interactions
- missed-connection empty-chair scene
- Restoration Camp
- North Gate / Village Defense
- Church / Tavern investigation routes
- Graveyard + Bell Keeper side story
- Ancient Research Ward

### Hidden resistance

Four canonical source arcs currently exist as implementation placeholders:

1. Ancient Research Ward
2. Graveyard Bell story
3. Restoration Order
4. Route Memory Echo

Three of four awaken the hidden resistance anchor.

The UI never tells the player that this is a true-ending requirement.

## Mite progression

Relationship facts:

- first meeting
- meal
- stay a while
- return
- post-resonance dialogue stages

After physical union:

- ancient-god residue awakens
- Outer-God resonance begins
- Mite control stage progresses 0 → 3
- subtle visual changes appear before any explicit monster transformation

Physical union in normal flow is triggered after the relationship has developed and the player rests at the Tavern.

The presentation is non-explicit and relies on fade-to-black and aftermath.

## Three ending theaters

### F1 — Candidate-driven

Uses the ending evaluator.

- no union → 凡人之墓 theater
- union + no resistance → 永恒乐园 theater
- union + hidden resistance → 烈火天罚 theater

### F2 — 永恒乐园

Prototype now includes:

- transformed High Priest
- transformed King
- union with Mite
- dream/paradise visual transition
- final state where no one is lonely / separate

### F4 — Ancient Research Ward

Prototype includes:

- research husk
- black vial
- sealed hair
- vessel ledger
- hidden ancient-god evidence

### F5 — Village Defense

Prototype includes:

- Bandits
- Church Inquisitors
- two attack waves
- Hero protecting the village
- defeat retry loop

### F6 — Mite Resonance

Isolated relationship/resonance prototype.

### F7 — Church Final Boss

Prototype includes:

- High Priest human phase
- High Priest ancient-god phase with area-burst attack
- King intervention
- King phase-two heavy charge
- post-victory epilogue showing the next corrupt order beginning

### F8 — 烈火天罚

Prototype includes:

- 100 nonblocking one-hit cultists
- 60-second true no-input waiting window for Mite
- corrupted lullaby
- Mite final encounter
- true 60-second no-input waiting condition
- Mite throws herself onto Hero's weapon
- restrained camera impact at the self-sacrifice
- city-scale detonation
- heavy camera impact

### F9

Deletes save data and starts the playable prologue.

## Debug shortcut matrix

From Village Hub:

- F1 — Candidate endgame
- F2 — Eternal Paradise
- F3 — Debug HUD
- F4 — Ancient Research Ward
- F5 — Village Defense
- F6 — Mite Resonance
- F7 — Church Final Boss
- F8 — 烈火天罚
- F9 — Reset

## Runtime limitation

The current maintainer environment has no Godot 4.6 executable.

Therefore:

- source structure is checked
- GitHub state is checked
- quote/string boundaries are checked
- major script structures are checked

But actual frame-level Godot runtime acceptance is still pending local execution.

## Important rule

Do not trigger GitHub Actions.

Do not replace the narrative canon with temporary prototype assumptions.

When a future implementation reaches a truly unresolved core story decision, stop that specific story layer and ask the director. Otherwise keep developing autonomously.


## Interaction / flow stabilization

- Unified nearest-interaction focus across Mite, NPCs, clues, doors, exits and rest points.
- Village house entry is now explicit **E** interaction; touching the door no longer transitions scenes.
- Route and interior doors are explicit **E** interactions.
- Completed routes can be replayed instead of auto-returning to the Village Hub.
- Narrative-to-scene transitions now wait on the narrative completion signal instead of a paused SceneTree timer.
- Route exits validate the memory echo belonging to the active route.

## Latest polish

- Shared Boss HUD now reads per-Boss max health, display name and phase.
- Village has subtle procedural firefly ambience.
- After Outer-God resonance, a subset of fireflies becomes synchronized and colder in tone.
- The final Mite waiting scene has 15s / 35s / 50s micro-movements before the 60s decision.
- The final Mite lunge has restrained camera impact; city detonation uses a much heavier impact.


## Map production continuation — 2026-10-11

### Completed in this continuation

- Audited the existing A3 local Resonance Sight bridge against the Hero → WorldState → `resonance_hidden_targets` refresh path. The bridge already receives state changes through `WorldState.refresh_resonance_reveals()`; no duplicate runtime mechanism was added.
- Strengthened `tools/validate_graybox_scene_wiring.py` so future edits must preserve the A3 route ID, resonance threshold (28), bridge coordinates, persistent open-state restoration, collision lifecycle, shared E-focus interaction, and the WorldState reveal dispatch.
- The validator source was re-fetched after its commit and the newly added assertions were checked against the current A3 route and WorldState source text. This is a contract-presence audit only; the Python validator itself was not executed in a local checkout.

### Still outstanding
- Re-audited regional death checkpoints: `_spawn_hero()` already stores the current region spawn as the checkpoint. The continuation now strengthens the static regression contract and avoids adding a duplicate save call; runtime respawn still needs Godot verification.

- Godot 4.6.x runtime acceptance remains pending because no Godot executable is available in the maintainer environment.
- The updated Python validators have not yet been run against a local working tree in this continuation.
- The A0–A12 / H01–H08 platform routes, C01–C24 transitions, save/continue spawn restoration, interaction arbitration, death recovery, and all ending handoffs still need runtime traversal. Do not describe them as runtime-passed.
- Continue by auditing the highest-risk unresolved map contracts and, where practical, improve static tooling before expanding further graybox geometry. Preserve the DS1-style interconnected box-world and Resonance Sight's ability to reveal routes within familiar regions.

### Verification boundary

- **Confirmed:** latest development branch source was fetched; validator assertions were committed; the current checked source strings satisfy the added local-route contracts.
- **Not confirmed:** execution of `python3 tools/validate_world_map_topology.py`, execution of `python3 tools/validate_graybox_scene_wiring.py`, Godot parser/import, collision behavior, player traversal, or frame-level scene changes.
- **Workflow policy:** no GitHub Actions were triggered.

## 2026-10-11 — Local Resonance route contract hardening

### 中文

- 加强 `tools/validate_graybox_scene_wiring.py`：现在会将 `greybox_world_region.gd` 中实际构造的局部鸣响路线 ID 与 `tools/world_map_topology.json` 完整比对，检查重复、缺失和多余 ID。
- 每条路线还会核对运行时 `match region_id` 分支与拓扑声明的 `region_id`，避免路线参数正确、却被错误地图构造的情况。
- 每条路线的交互提示、叙事标题和叙事正文都要求具有简体中文、繁体中文、日语非空译文；英文继续作为源文本与回退文本。
- 已通过 GitHub 远程读取内容后进行独立字符串一致性核对：11 条拓扑路线与 11 条运行时路线 ID 一致，运行时分区与拓扑声明一致，交互提示译文完整。
- **验证边界：** 以上是远程源码内容的一致性核对，不代表在本地执行了 Python 校验器，也不代表 Godot 4.6.x 运行时、碰撞、输入或实际走图已通过。正式验收仍需运行校验器并进行实机回归。

### English

- Strengthened `tools/validate_graybox_scene_wiring.py` to compare the complete set of runtime local Resonance route IDs against `tools/world_map_topology.json`, catching duplicates, missing routes, and unexpected routes.
- Each route is now checked against its enclosing runtime `match region_id` branch, so correct parameters cannot silently be attached to the wrong region.
- Every route prompt, narrative title, and narrative body must provide non-empty Simplified Chinese, Traditional Chinese, and Japanese translations. English remains the source and fallback text.
- A separate string-level audit of the remotely retrieved source confirmed that all 11 topology route IDs match the 11 runtime route IDs, region assignments agree, and route prompts have translations.
- **Validation boundary:** This was a remote-source consistency audit only. The Python validator was not executed in a local checkout, and Godot 4.6.x runtime behavior, collisions, input, and traversal remain unverified. Acceptance still requires running the validator and performing runtime regression tests.

## 2026-10-11 — Local bridge interaction focus correction

### 中文

- 静态复核局部鸣响桥时发现一个会影响实际交互的焦点问题：路线是以地图根节点坐标绘制的组合对象，根节点通常位于 `(0, 0))，但共享交互焦点此前按根节点原点计算距离。即使主角站在桥体锚点附近，附近门或 NPC 仍可能错误抢走 E 焦点。
- 修复 `scripts/core/interaction_focus.gd`：支持可选的 `interaction_focus_position` 元数据；未提供元数据的既有交互对象仍使用原有全局位置，保持向后兼容。
- 修复 `scripts/world/resonance_local_route.gd`：每帧将桥体中心的全局坐标登记为焦点位置，让共享仲裁按真正的桥体锚点计算距离。
- 将上述合同加入 `tools/validate_graybox_scene_wiring.py`，并把桥中心焦点、附近交互竞争和语言切换列入 `docs/MAP_GATE_ACCEPTANCE_MATRIX_CN.md`。
- 这是根据源码定位并修复的逻辑缺陷，尚未通过 Godot 4.6.x 实机确认；仍需验证 E 提示显示、按 E 固定桥体，以及与相邻门 / NPC 的焦点竞争。

### English

- Static review found an interaction-focus defect: a local Resonance route is a composite object drawn in map coordinates, while its root origin is usually `(0, 0)`. Shared focus arbitration used that root origin for distance ranking, so a nearby door or NPC could incorrectly win the E prompt even when the Hero stood by the bridge anchor.
- Updated `scripts/core/interaction_focus.gd` to support optional `interaction_focus_position` metadata. Existing interactables without the metadata retain their previous global-position behavior.
- Updated `scripts/world/resonance_local_route.gd` to publish the bridge center's global position as the focus point, so arbitration uses the actual interaction anchor.
- Added static contracts for the anchor-aware focus logic and acceptance cases for bridge-center focus, nearby interactable competition, and language switching.
- This is a source-level defect fix, not a Godot 4.6.x runtime pass. In-engine verification is still required for the prompt, E-key anchoring, and focus competition with nearby doors/NPCs.


## Box-world structural re-audit — 2026-10-12

- Fixed a structural bypass: shared graybox exit doors previously used a 138px-high interaction trigger that extended down to the continuous floor. The trigger is now 110×80 and vertically aligned near the doorway; this should make raised exits depend on reaching their ledge, pending Godot runtime confirmation.
- Added a static regression contract for the trigger dimensions and alignment.
- Reclassified H09 as a provisional map candidate separate from the canonical H01–H08 resonance-hidden network. H09 is not approved story canon and is not part of the 21-scene core map acceptance count.
- Corrected stale validator contracts: the Hero spawn signature, C16 A3 anchor/return coordinates (2040/1960), and H05 return anchor (1870) now match the current scene code and topology manifest.
- Checked the fetched topology manifest with a lightweight graph audit: 14 abstract primary nodes, 24 macro edges, 8 canonical hidden regions, 1 provisional region; the primary route is initially reachable, all declared nodes become reachable in the final abstract graph, and L01–L03 have closed paths with matching declared unlock requirements.
- These are remote-source consistency checks, not execution of the repository Python validators or Godot runtime tests. No claim of in-engine traversal acceptance is made.

### Still outstanding

- Continue mapping every macro edge to its actual exit door, spawn side, height, and reverse-gate condition.
- Reduce the remaining “continuous ground leads to the next boundary” feel without adding arbitrary collision obstacles; prioritize meaningful upper/lower routes and return shortcuts in A2–A4, then A5–A9.
- Run both Python validators in a local checkout and complete Godot 4.6.x natural-exploration acceptance when an engine environment is available.

- Second spatial pass: C09 (A5→A6) now leaves from the upper battlefield parapet; C17 (A9→A10) now uses a two-step upper roof approach. F10 route hints, topology anchors, and static regression contracts were updated together. Runtime reachability is still unverified.

- H09 provisional loot is now decoupled from ending progression. New pickups only record `provisional_h09_relic_collected`; legacy `third_umbilical_cord` source entries from this candidate route are removed during load and the correction is saved. The third-cord motif remains undecided story material, not a finalized H09 requirement.

## 2026-10-15 — P1–P4 full-map continuation and A8 Boss

### Implemented / static contracts updated

- Added the independent optional A8 Boss arena: `scenes/royal_tomb_boss.tscn` and `scripts/levels/royal_tomb_boss.gd`.
- The A8 entrance uses its own persistent flag `defeated_royal_tomb_guardian`; it does not change C13/C14/C07/C15 or the ending evaluator. The C14 route to A9 remains available whether the Boss is fought or not.
- Boss death resets the arena encounter at the local checkpoint. Victory records the dedicated flag and opens the return door; returning to A8 uses the `boss_return` spawn at x=1700, between the x=1540 arena entrance and x=1870 H06 gate.
- Continue can resume `royal_tomb_boss`. The shared Ashen Knight script now supports a display name, phase property, visual theme and opt-out from the legacy global `boss_defeated` flag; the Boss HUD follows the currently bound encounter instance.
- Added B01–B08 runtime acceptance cases to `docs/MAP_GATE_ACCEPTANCE_MATRIX_CN.md` and the P1–P4 execution ledger at `docs/P1_P2_P3_P4_FULL_MAP_EXECUTION_CN.md`.
- Fixed the static map validator's region-exit extraction: it previously searched for eight literal spaces although the GDScript `match` blocks use tabs. The new whitespace-agnostic extractor covers the actual A2–A12 and H01–H08 exit blocks. Updated stale C08/C13 prompt assertions to match the authored door text.

### Remote source cross-check

- Confirmed inventory: 14 formal regions, 24 C-edges, 3 macro loops, 8 formal hidden regions, 6 macro regions, 76 subregions, 71 intra-region edges, and 8 elevator contracts.
- Confirmed final abstract topology reachability from A0 to all A0–A13 regions.
- Confirmed runtime hidden-gate IDs H01–H08 match topology; all 11 local Resonance route IDs match between topology and runtime.
- Confirmed P1 prologue / village-defense / C02 source contracts and P2 Boss entry / death reset / victory / return / Continue wiring.
- **Verification boundary:** These are remote source and topology cross-checks, not execution of the Python validators. Godot 4.6.1 parsing, collision, combat, save/Continue, and continuous natural-exploration acceptance remain pending. No GitHub Actions were triggered.



## 2026-10-30 — A0 场景加载与伏击 AI 修复（待本地验收）

- 修复 S01 `escape_prologue.tscn`、洞外 `prologue_exterior.tscn` 以及 A0 R01–R03 场景中的颜色序列化写法；R01/R02/R03 分别规范化 18/22/28 处颜色值。
- 复核 S01、S02、洞外、A0 R01–R03、伏击敌人及相关子场景的直接外部资源路径，当前分支文件树中未发现缺失路径。
- 修复 S02 伏击守卫 AI 目标查找错误：守卫实例位于 `Wardens` 子节点，旧相对路径 `../Hero` 指向错误位置；Hero 已加入 `player` 组，守卫改用玩家组查找目标。
- 变更分支：`feature/story-map-progression`。代码与审计文档已提交。
- **验收状态：BLOCKED（等待本地 Godot 4.6.1 验证）**。远程静态检查不等于场景解析、碰撞或战斗运行时通过。需按 A0 审计文档逐项测试新游戏、S01→S02、伏击 AI、死亡重试与出口解锁。


## 2026-10-30 — A0 S02→洞外加载问题追加修复（待本地复测）

- 用户实机日志确认：S01→S02、三名伏击守卫战斗、闪避无敌帧、伏击清除与出口解锁均正常。
- 洞外场景转场仍返回 `ERR_CANT_OPEN (19)`。远程静态检查未发现该场景直接/二级资源路径缺失。
- 修复 `scenes/prologue_exterior.tscn` 中 14 处 `PackedVector2Array(Vector2(...), ...)` 序列化为扁平坐标序列的格式问题。
- 验收状态：A0 前半流程实机通过；洞外加载修复待本地重新导入及复测，不标记为完整通过。
