# Scene Directory Migration Inventory

Branch: `feature/story-map-progression`

Status: inventory derived from the current branch tree, `scripts/core/world_state.gd`, and `tools/world_map_topology.json`. This is a migration plan, not evidence of runtime acceptance.

## Primary region entry scenes

| Region | Current entry scene | Proposed path |
|---|---|---|
| A0 | `scenes/escape_prologue.tscn` | `scenes/regions/escape_prologue.tscn` |
| A1 | `scenes/village_hub.tscn` | `scenes/regions/village_hub.tscn` |
| A2 | `scenes/ash_forest.tscn` | `scenes/regions/ash_forest.tscn` |
| A3 | `scenes/forgotten_city.tscn` | `scenes/regions/forgotten_city.tscn` |
| A4 | `scenes/sewer_reservoir.tscn` | `scenes/regions/sewer_reservoir.tscn` |
| A5 | `scenes/old_battlefield.tscn` | `scenes/regions/old_battlefield.tscn` |
| A6 | `scenes/monastery_tower.tscn` | `scenes/regions/monastery_tower.tscn` |
| A7 | `scenes/prison_depths.tscn` | `scenes/regions/prison_depths.tscn` |
| A8 | `scenes/royal_tomb.tscn` | `scenes/regions/royal_tomb.tscn` |
| A9 | `scenes/royal_outer_ring.tscn` | `scenes/regions/royal_outer_ring.tscn` |
| A10 | `scenes/grand_cathedral.tscn` | `scenes/regions/grand_cathedral.tscn` |
| A11 | `scenes/deep_research_depths.tscn` | `scenes/regions/deep_research_depths.tscn` |
| A12 | `scenes/inner_city.tscn` | `scenes/regions/inner_city.tscn` |
| A13 | `scenes/terminal_anomaly.tscn` | `scenes/regions/terminal_anomaly.tscn` |

## Root-level scenes that are not primary region entries

These remain separate until their ownership and every reference are audited:

- `scenes/boot.tscn` — project launch scene; keep path stable.
- `scenes/prologue_exterior.tscn`, `scenes/mite_house.tscn` — staged C01 arrival scenes.
- `scenes/village_backhill.tscn`, `scenes/village_graveyard.tscn`, `scenes/rebel_camp.tscn` — A1 auxiliary/visit scenes.
- `scenes/old_drain_exploration.tscn` — shared C24 route segment, not a region entry.
- `scenes/royal_tomb_boss.tscn` — optional boss arena OB01, not A8's region entry.
- `scenes/a5_assembled_region.tscn` — legacy/assembled A5 scene; review ownership separately before moving.
- `scenes/cliff_exploration.tscn` — cliff exploration scene; review ownership separately.
- `scenes/ancient_research_lab.tscn` — auxiliary research scene; review ownership separately.

## Required pre-move audit

Before moving any entry scene, update and verify all path consumers in:
- `scripts/core/world_state.gd` (region ID mapping and resume destinations)
- `scripts/levels/greybox_world_region.gd` (doors, exits and route destinations)
- `tools/validate_graybox_scene_wiring.py` (acceptance assertions)
- `tools/world_map_topology.json` and other data contracts
- Every other `.gd`, `.tscn`, `.tres`, `.json`, `.py`, and `project.godot` reference on this branch.

The first reference scan found direct consumers in the files above. It is not yet a complete repository-wide scan, so primary entry scenes have deliberately not been moved in this batch.

## Non-negotiable preservation

- Keep A2 R01–R06 as six separate authored room scenes.
- Keep all 22 legacy A5 room scenes; do not merge or delete them during directory cleanup.
- Preserve each moved scene's node tree and attached scripts.
- A GitHub path/reference check is not a substitute for Godot 4.6.1 editor and runtime acceptance.

## 迁移前引用审计记录（2026-10-27）

### 已确认的高风险引用点

在正式区域入口移动之前，至少必须同步检查以下文件：

- `scripts/core/world_state.gd`：A0–A13 场景路径映射、区域识别与恢复/重载场景路径均有硬编码引用。
- `scripts/levels/greybox_world_region.gd`：包含大量跨区域出口目标与返回路线；它不仅是地图逻辑，也是运行时场景路径的主要集中点。
- `tools/validate_graybox_scene_wiring.py`：包含正式区域场景路径的静态断言。若场景迁移而断言未更新，验收脚本会因旧路径产生误报或遗漏新路径。
- `tools/world_map_topology.json`：包含序章路线链、区域入口路径与空间合同数据，需要逐项核对是否记录的是运行时入口路径还是设计文档路径。
- `project.godot`：启动场景必须保持 `scenes/boot.tscn` 稳定；Autoload 路径应独立核验，不应随正式区域入口一起改动。

### 当前审计边界

本轮已读取并检查上述文件以及场景目录说明，确认正式区域路径存在多处直接引用；尚未完成对所有文本文件的全仓库逐文件引用扫描。因此，本轮**不移动 A0–A13 场景文件**，避免制造未更新的引用。隐藏区域 H01–H08 的现有路径在已检查的 `world_state.gd`、`greybox_world_region.gd` 和拓扑 JSON 中均能看到新目录路径；但这不等于已经证明仓库所有引用均无遗漏。

### 下一批执行顺序

1. 完成全仓库旧路径引用盘点，覆盖脚本、场景、资源、配置、JSON 与 Python 验收工具。
2. 按依赖组更新所有引用，并将 A0–A13 正式入口迁移到 `scenes/regions/`。
3. 检查每个目标文件只存在于新路径，且旧路径引用数为零（允许迁移清单/历史说明中的路径作为文字记录）。
4. 执行可用的静态校验；Godot 4.6.1 场景导入与实机转场仍需本地运行确认。
5. 将辅助场景（序章到达场景、A1 辅助场景、C24、OB01、A5 组装场景及悬崖/研究场景）按实际职责单独归档，不与正式区域入口混为一类。

A2 的六个运行时房间、A5 的 22 个旧房间以及现有节点树均保持原样；目录整理不授权删减房间，也不以脚本动态创建节点替代编辑器中可见的场景节点。
