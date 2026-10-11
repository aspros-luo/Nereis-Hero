# 开发协作条约 / Development Working Charter

> 状态：生效中 / Active  
> 适用项目：Nereis-Hero（蜜忒之歌-英雄）  
> 维护原则：增量修改、可核验证据、精简对话上下文。

## 中文约定

1. **意见与建议采用正反方裁定。** 当用户提出意见、建议或方案时，内部比较支持理由、反对理由、风险和替代方案，再给出明确裁定。除非用户主动要求，不在对话中展开内部辩论过程；只报告结论、关键理由和必要风险。
2. **压缩对话上下文。** 不输出冗长思考过程、逐步自言自语或重复项目历史。优先直接推进工作；只汇报有用的状态变化、决策、验证结果、阻塞项和下一步。
3. **图片生成必须事先确认。** 不因“设计”“展示”“可视化”等词自动生成图片。若确实准备调用图片生成工具，必须先询问用户并等待明确同意；未获同意不得调用。
4. **先核实再修改。** 开始任务前检查当前分支、相关代码、配置和现有文档；区分已实现、静态检查通过、引擎实测通过与尚未验证。无法核实的历史信息必须标注为未知，不得推测成事实。
5. **尊重已确认的设计。** 不擅自推翻世界观、结局、战斗基线、地图拓扑或其他已确认决策。若发现可能影响设计的缺陷，先评估并说明必要影响；没有用户确认时优先采用最小风险修复。
6. **持续开发而非重复讨论。** 在任务明确且风险可控时，直接继续最高优先级的未完成工作，不要求用户重复确认已批准事项。只有剧情方向等不可逆的重大设计决定确实缺少依据时才询问。
7. **验证报告必须诚实。** 代码已提交不等于已运行；源码合同检查不等于脚本已执行；静态地图连通不等于 Godot 场景可玩。报告应标注验证方式、实际结果与未覆盖范围。
8. **GitHub 工作流约束。** 按既有开发分支推进；未经明确要求，不主动触发 GitHub Actions 或其他可能产生通知的工作流。文档修改应与实现状态一致，并保留中文 Markdown 文档。
9. **优先级。** 先修复阻断启动、通关、存档或交互的缺陷，再做回归验证，然后推进玩法与内容，最后处理表现层打磨。不得为追求新增功能而掩盖未验证的核心流程。

## English

1. **Evaluate user proposals through a pro/con decision process.** Weigh benefits, counterarguments, risks, and alternatives internally, then report the verdict and only the essential rationale unless the user asks for the full debate.
2. **Keep conversation context concise.** Avoid verbose internal reasoning and repeated history. Report meaningful changes, decisions, verification evidence, blockers, and next actions.
3. **Ask before image generation.** Do not generate an image merely because the user says “design,” “show,” or “visualize.” If image generation is being considered, ask first and wait for explicit approval.
4. **Verify before editing.** Inspect the current branch, relevant code, configuration, and docs. Distinguish implemented, statically checked, engine-tested, and unverified work. Never guess about unverifiable history.
5. **Preserve approved decisions.** Do not silently overturn established lore, endings, combat baselines, map topology, or other approved decisions. Prefer minimal-risk fixes; raise material design conflicts rather than changing direction unilaterally.
6. **Keep development moving.** Continue the highest-priority unfinished work when scope and risk are clear. Ask only when a consequential, hard-to-reverse narrative or design decision genuinely lacks a basis.
7. **Report verification honestly.** A commit is not a runtime test; a source-contract check is not proof that a script ran; static map connectivity does not prove playable Godot scenes. State methods, results, and uncovered areas.
8. **GitHub workflow constraints.** Work on the established development branch. Do not intentionally trigger GitHub Actions or notification-generating workflows unless explicitly requested. Keep Chinese Markdown documentation aligned with implementation status.
9. **Priority order.** Fix blockers to startup, progression, saving, and interaction first; then regressions, gameplay/content, and presentation polish. Do not hide unverified core flows behind new features.
