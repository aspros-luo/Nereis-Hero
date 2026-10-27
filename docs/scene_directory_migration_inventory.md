# Scene Directory Migration Inventory

Branch: `feature/story-map-progression`

Status: A0–A13 entry scenes have been moved to `scenes/regions/`; runtime and acceptance references were updated in this branch. GitHub static checks do not replace local Godot 4.6.1 import and runtime acceptance.

## Primary region entry scenes

| Region | Migrated entry scene | Status |
|---|---|---|
| A0 | `scenes/regions/escape_prologue.tscn` | migrated |
| A1 | `scenes/regions/village_hub.tscn` | migrated |
| A2 | `scenes/regions/ash_forest.tscn` | migrated |
| A3 | `scenes/regions/forgotten_city.tscn` | migrated |
| A4 | `scenes/regions/sewer_reservoir.tscn` | migrated |
| A5 | `scenes/regions/old_battlefield.tscn` | migrated |
| A6 | `scenes/regions/monastery_tower.tscn` | migrated |
| A7 | `scenes/regions/prison_depths.tscn` | migrated |
| A8 | `scenes/regions/royal_tomb.tscn` | migrated |
| A9 | `scenes/regions/royal_outer_ring.tscn` | migrated |
| A10 | `scenes/regions/grand_cathedral.tscn` | migrated |
| A11 | `scenes/regions/deep_research_depths.tscn` | migrated |
| A12 | `scenes/regions/inner_city.tscn` | migrated |
| A13 | `scenes/regions/terminal_anomaly.tscn` | migrated |

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

## Migration implementation and reference audit

The following runtime, route-data, and acceptance consumers were updated to the new entry-scene paths:
- `scripts/core/world_state.gd` (region ID mapping and resume destinations)
- `scripts/levels/greybox_world_region.gd` (doors, exits and route destinations)
- `tools/validate_graybox_scene_wiring.py` (acceptance assertions)
- `tools/world_map_topology.json` and other data contracts
- Every other `.gd`, `.tscn`, `.tres`, `.json`, `.py`, and `project.godot` reference on this branch.

The path update covers the central runtime scene routing, world-state region mapping, boot/prologue/village/route transitions, A2 room exits, the contract-room scene map, world topology, acceptance harness, static wiring checks, A2 geometry contract, A8 spatial contract, and the world acceptance ledger. A local Godot import is still required to catch parser/resource errors.

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

已更新集中式运行时路径映射、主要区域转场脚本、A2 独立房间出口、数据合同、静态校验器与接受度账本。迁移不改变场景内部节点树，也不涉及 A2/A5 房间合并。最后仍需在本地 Godot 4.6.1 中完成导入与实机转场验收。

### 后续验收

1. 对分支运行旧入口路径残留扫描，排除迁移历史文档中的说明文字。
2. 执行可用的静态校验；Godot 4.6.1 场景导入与实机转场仍需本地运行确认。
3. 将辅助场景（序章到达场景、A1 辅助场景、C24、OB01、A5 组装场景及悬崖/研究场景）按实际职责单独归档，不与正式区域入口混为一类。

A2 的六个运行时房间、A5 的 22 个旧房间以及现有节点树均保持原样；目录整理不授权删减房间，也不以脚本动态创建节点替代编辑器中可见的场景节点。

## 第二轮目录盘点（2026-10-27）

### 当前目录中发现的并行房间/区域实现

递归目录树中同时存在以下文件族，迁移前需要确认它们的用途与引用关系，不能仅凭文件名判断为冗余：

- A2：`scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn` 至 `a2_r06_room.tscn`，以及 `scenes/rooms/a2_bell_tomb.tscn`、`a2_mist_forest.tscn`、`a2_pilgrim_highroad.tscn` 等旧/独立房间场景。
- A5：`scenes/a5_rooms/a5_r01.tscn` 至 `a5_r22.tscn`、`scenes/rooms/a5/a5_room_01.tscn` 与 `a5_room_02.tscn`、`scenes/rooms/world_a5_r01.tscn` 至 `world_a5_r03.tscn`，并有 `scenes/a5_assembled_region.tscn`、`resources/rooms/a5_room_01.tres` 和 `a5_room_02.tres`。
- A0 及其他区域还存在 `scenes/rooms/world_a0_*.tscn`、`world_a4_*.tscn` 至 `world_a13_*.tscn` 等通用命名房间族。

以上只是目录层面的并存事实，不足以证明这些场景重复或可删除。后续需对每组检查 `PackedScene` 实例引用、RoomData/房间图合同、运行时加载脚本和验收脚本，再决定只归档、不迁移，或迁移到统一子目录。**本次不删除、不合并、不重命名这些房间文件。**

### 目录迁移安全边界

- 正式区域入口只迁移到 `scenes/regions/`；其内部房间仍按实际使用体系保留在对应房间目录。
- `scenes/boot.tscn`、`project.godot` 的主启动入口与 Autoload 位置保持稳定。
- A1 辅助场景、C24 排水探索、OB01 Boss、A5 组装场景、悬崖探索、古代研究实验室必须先判定调用方与职责，再归档；不能将它们误当成 A0–A13 入口。
- 目录树核对已覆盖 590 个符合脚本/场景/资源/配置/文档扩展名的文件条目（递归 Git tree 未截断）；这只是文件清单核对，**不是**全部文件内容的引用扫描。逐文件引用核验仍未完成，故不据此宣称旧路径零残留。

### 本轮迁移结果

- A0–A13 正式入口已统一归档至 `scenes/regions/`。
- `scenes/boot.tscn`、`project.godot` 的主启动入口与 Autoload 路径保持稳定。
- A2 六个运行时房间、A5 22 个旧房间以及辅助场景均保留原位。
- GitHub 静态路径核对不代表 Godot 本地导入和实际转场已经通过；这些仍是最终验收项。

A2 六个运行时房间与 A5 22 个旧房间必须保留；整理目录不等于删减内容。
