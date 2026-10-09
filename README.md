# Nereis Hero

A 2D Soulslike action RPG in the Nereis / 蜜忒之歌 universe.

## Current playable direction

Development has moved beyond the original Core Combat Demo into the first narrative production pass.

The current default flow is:

**Church surgical ward → escape → remote village → Mite → Church / village investigation**

Default startup:

`res://scenes/escape_prologue.tscn`

The original combat demo remains available at:

`res://scenes/combat_demo.tscn`

## Current narrative foundation

Canonical story memory:

`docs/DEVELOPER_STORY_MEMORY.md`

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
- Four independent hidden story sources can assemble the resistance anchor
- Ancient research ward
- Graveyard bell story
- Restoration order
- Route memory echo
- Evidence is not exposed as a "true ending checklist"

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

### Debug controls / 调试快捷键

- F1 — candidate-driven endgame theater / 按当前条件进入结局剧场
- F2 — Eternal Paradise Theater / 永恒乐园测试
- F3 — global world-state Debug panel / 全局世界状态调试面板
- F4 — toggle Hero-local overlay / 显示或隐藏主角调试面板
- F5 — session-only all-protagonist-ability override and temporary fixtures / 本次运行全部主角能力覆盖与临时测试设施
- F6 — refill HP/stamina and clear temporary actions/effects / 恢复生命与体力，清除临时动作和效果
- F7 — Church Final Boss Theater / 教会最终 Boss 测试
- F8 — 烈火天罚 Theater
- F9 — clean reset / 清档重置
- F10 — Ancient Research Ward / 古代研究区测试
- F11 — Village Defense Theater / 村庄防守测试
- F12 — Mite Resonance Theater / 蜜忒共鸣测试

F5 does not grant persistent unlocks or story progression. Debug anchors, hidden traces, marked walls and selected iaijutsu form are session-only.

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


## Art production / 美术生产

The first original painterly-inspired SVG sample is integrated into the existing rendering scripts:
- Hero long-sword / short-blade variants
- Mite
- Cultist
- Ashen Knight phases 1 and 2
- Judgment Slash, three Crescent Combo stages, Eldritch Echo sigil and hit spark

See [Art Asset Pipeline](docs/ART_ASSET_PIPELINE.md) and [Art Asset Provenance & Licenses](assets/art/ART_ASSET_LICENSES.md) for the bilingual workflow and source/license ledger. No third-party environment pack has been imported yet; the environment pack selection remains a separate step to avoid a style mismatch.

本项目已将第一批原创绘画质感 SVG 接入现有绘制脚本：主角长剑/短刃、蜜忒、苦修者、灰烬骑士两阶段，以及断罪斩、残月连斩三段、余响符印和命中火花。美术流程见[美术生产流程](docs/ART_ASSET_PIPELINE.md)，素材来源与许可证见[美术素材来源与许可](assets/art/ART_ASSET_LICENSES.md)。目前尚未导入第三方环境素材包，避免在未核对风格和许可前混搭。
