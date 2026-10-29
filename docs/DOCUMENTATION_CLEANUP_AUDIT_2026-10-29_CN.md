# 文档清理审计 — 2026-10-29

> 分支：`feature/story-map-progression`
> 目的：减少重复入口，明确权威文档，避免误删仍被源码、场景、验证器或历史审计引用的文件。
> 本记录区分“已完成的整理”和“尚未满足安全删除条件的候选项”。

## 1. 已完成

- 新建 `docs/MILESTONE_HANDOFF_2026-10-29_CN.md`，作为新里程碑的单一交接入口。
- README 增加当前交接入口与叙事权威文档索引。
- README 移除重复的 `PROJECT_DOCUMENTATION_GOVERNANCE_CN.md` 索引段落。
- `WORLD_BUILDING_BIBLE_CN.md` 增加 2026-10-29 已确认的叙事规则、前期推进条件与地图路线。
- `WORLD_NARRATIVE_CLUE_LEDGER_CN.md` 增加不解释剧情的碎片叙事规则。
- `WORLD_MAP_BRAINMAP_CN.md` 增加最新路线裁定，并警告旧图/拓扑合同仍需工程核查。
- `NARRATIVE_PRESENTATION_AUDIT_AND_MIGRATION_CN.md` 明确当前规则与未完成的源码审计范围。
- `PROTAGONIST_OPENING_NARRATIVE_V1_CN.md` 与 `DIRECTOR_NARRATIVE_PLAN.md` 标记为受最新决策约束的历史/候选设计，不再凌驾于当前规则。
- `ROADMAP.md` 明确旧阶段清单不覆盖当前新里程碑优先级。

## 2. 当前权威文档职责

| 内容 | 权威入口 |
|---|---|
| 本次定稿与新里程碑交接 | `docs/MILESTONE_HANDOFF_2026-10-29_CN.md` |
| 世界观正史、角色边界、待定事项 | `docs/WORLD_BUILDING_BIBLE_CN.md` |
| 碎片叙事方法与线索证据链 | `docs/WORLD_NARRATIVE_CLUE_LEDGER_CN.md` |
| 宏观地图意图 | `docs/WORLD_MAP_BRAINMAP_CN.md`、`docs/FORMAL_WORLD_MAP_DESIGN_BASELINE_CN.md` |
| 结局状态/程序条件 | `docs/ENDING_CONDITION_DESIGN_CN.md` |
| 叙事呈现源码审计 | `docs/NARRATIVE_PRESENTATION_AUDIT_AND_MIGRATION_CN.md` |
| 修改、依赖与验收治理 | `docs/PROJECT_DOCUMENTATION_GOVERNANCE_CN.md` |

## 3. 暂不删除的候选项与原因

本次没有足够证据证明以下类别可以安全删除，因此不将“看起来重复”当作“无用”：

- `STORY.md`、`DIRECTOR_NARRATIVE_PLAN.md`、`PROTAGONIST_OPENING_NARRATIVE_V1_CN.md`：叙事方向有重叠，但包含不同年代的设计假设和可能的实现状态；已标记权威优先级，需逐条迁移有价值内容并检索引用后再考虑删除。
- `WORLD_MAP_BRAINMAP_*.md`、`BOX_WORLD_*.md`、`WORLD_MAP_* / COMPLETE_WORLD_MAP_*`：内容有重叠，但可能分别记录空间意图、验收、版本差异与历史原因；未完成交叉引用和拓扑核查前不删除。
- A0/A1/A2 区域设计、审计、运行时验收和 SVG/JSON 合同：不能因文档多就删除独立验收证据或机器可读合同。
- `tools/` 下的验证器、地图合同、清理/验收清单：不是普通说明文档，可能被开发者、Godot 或静态检查调用，必须先审查依赖。

## 4. 下一轮删除前必须完成

1. 对候选文档检索仓库中的 Markdown 链接、README 索引、脚本路径、场景资源路径、`preload/load`、验证器与动态文件引用。
2. 把仍有效的设计事实迁入权威文档；历史上重要的决定保留简短变更记录。
3. 检查跨语言版本是否仍被维护或链接；不能只删中文/英文其中一份而留下断链。
4. 检查文件是否是运行时、工具或验收输入；对 JSON、SVG、脚本和合同单独审查。
5. 逐文件记录证据和验证结果，再执行删除；无法证明安全的文件保留并标记历史/待审。

## 5. 当前未完成项

- 本轮没有执行全仓库文件级引用图分析。
- 本轮没有删除任何可能仍有设计、历史或工具价值的独立文件。
- 本轮没有修改 `tools/world_map_topology.json`、场景出口或验证器；C04 旧 A2↔A5 合同仍需后续工程审计。
- 本轮没有执行 Godot 运行时验收；文档更新不代表游戏流程已经通过。
