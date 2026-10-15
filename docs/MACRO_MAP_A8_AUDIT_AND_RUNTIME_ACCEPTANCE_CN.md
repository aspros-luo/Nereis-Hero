# Formal Map Audit — Macro Topology & A8 / 宏观地图与 A8 落地核对

> Branch: `development`  
> Audit scope: topology JSON and source-level graybox contracts.  
> Result: structural IDs confirmed; A8 has a documented implementation gap. Static review is not Godot runtime acceptance.

## 1. Macro topology inventory / 宏观拓扑清点

Source: `tools/world_map_topology.json`

- Primary regions: **14**, exactly A0–A13.
- Macro connections: **24**, exactly C01–C24.
- Macro loops: **3**, exactly L01–L03.
- Hidden regions: **8**, exactly H01–H08.
- The topology's region and connection IDs are contiguous and contain no missing IDs in these ranges.
- The three declared loops are:
  - L01: A1 → A2 → A3 → A4 → A1
  - L02: A3 → A5 → A6 → A3
  - L03: A4 → A8 → A9 → A4

These counts and ID ranges were checked against the fetched topology data. This is a direct data inspection, not a claim that the repository's Python validators were executed in a local checkout.

## 2. Route direction review / 路线方向审查

The formal map must preserve the difference between `initial_access` and `final_direction`.

- C01 is the one-way prologue transition A0 → A1.
- C06 is a one-way return shortcut A4 → A1 after the watergate condition is satisfied.
- C15 (A8 ↔ A11) and C19 (A10 ↔ A11) are separate resonance-gated routes with different prerequisites and entry sides.
- C21 (A11 → A13) is available only after `physical_union_complete` and is forward-only.
- C22 (A12 → A13) is a forward-only terminal entry after the A12 main-route progress flag.
- C13 is authored as an elevated, bidirectional A7/A8 connection. Its topology contains paired upper anchors and spawn-side metadata.
- C14 is a bidirectional A8/A9 main route. Its topology record has no dedicated `spatial_contract`; the scene's A8/A9 door and spawn mappings therefore remain a source-level contract to verify explicitly.

The three loop definitions are conditional macro loops, not immediately open paths in a new game. C05/C06, C10, and C07/C23 have to remain visibly locked until their respective flags are earned.

## 3. A8 source inspection / A8 源码检查

### Existing support

The shared graybox script `scripts/levels/greybox_world_region.gd` includes:

- 22 authored platform rectangles in the A8 platform block, including multiple heights and a west-side upper landing.
- A7 → A8 C13 entry side `maintenance_shaft_entry`, with the spawn x mapped to 190 and y offset -120.
- A8 → A7 C13 return side `maintenance_shaft_return`, with an elevated return door at the west boundary and a corresponding elevated spawn mapping.
- A8 → A9 C14 main exit and A9 → A8 reverse main exit.
- C15's A8-side gate configured as `secret_id = "C15"`, resonance threshold 55, ancient exposure threshold 2, and the two required anomaly sources.
- H06 as a separate A8 hidden-region gate, so H06 and C15 are not represented by the same secret ID.

### Gap found: A8 boss encounter is not wired / 发现缺口：A8 尚未接入 Boss 遭遇

The current A8 encounter branch in `_spawn_region_encounters()` only spawns `A8_Cultist_01`. No A8 boss encounter is declared in that branch, and the source does not currently establish a dedicated Boss arena, boss entry lock, victory flag, or post-boss return/unlock contract.

**This is an implementation gap, not a topology error.** Do not mark the A8 Boss requirement complete based solely on the layered platform rectangles. The next implementation step should add a separately identified A8 boss encounter and an explicit arena lifecycle without changing C13/C14/C15 semantics or inventing a new macro connection ID.

### Geometry risks still requiring runtime / 仍需引擎实测的几何风险

- A8 platform rectangles show intended vertical layering, but source text alone cannot prove that the jump physics can traverse every required gap.
- C13's two ends are designed as elevated entries; the scene must be tested for actual landing, wall/ceiling collision, and the possibility of running around the door along the continuous floor.
- C14 is a ground-level A8/A9 transition in the topology. Verify the A8 east exit, A9 west exit, and both arrival positions match the intended lower-ring route and do not spawn inside door interaction ranges.
- C15 is positioned at the A8 maintenance shaft. Verify its trigger focus does not overlap C14, the H06 gate, the rest point, or the Boss arena entrance.
- The currently inspected A8 encounter branch contains no explicit boss, so Boss arena entry/exit, death recovery, and gate persistence cannot yet be accepted.

## 4. Static validator execution / 静态验证器执行说明

The repository contains these existing validators:

```bash
python3 tools/validate_world_map_topology.py
python3 tools/validate_spatial_route_contracts.py
python3 tools/validate_connection_direction_audit.py
python3 tools/validate_graybox_scene_wiring.py
```

In this review environment, repository source was inspected through GitHub file reads; there was no checked-out repository filesystem or Godot executable available to execute these Python scripts. Therefore **their runtime output is not reported as pass/fail here**. Run them from the repository root to obtain authoritative local results. Fix any reported failures before accepting the static contract.

## 5. Godot 4.6.1 manual acceptance / 本地运行时验收清单

Run with a fresh test save and a progressed save where relevant. Record pass/fail per item.

### Macro traversal
- [ ] Walk the primary route A0 → A1 → A2 → A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12.
- [ ] Verify L01 after opening the A4 inspection hatch and village well watergate; walk the loop in both directions.
- [ ] Verify L02 after opening C10 from A6; confirm the A3 return door appears only after unlock.
- [ ] Verify L03 after opening C07 from A8 and C23 from A9; walk the loop both ways.
- [ ] Verify C01 and C06 remain one-way; verify C21/C22 enter A13 forward-only.
- [ ] Verify C04/C10/C16/C18/C23/C24 are initially blocked and become traversable only after their own conditions.

### A8 vertical traversal and transitions
- [ ] Enter A8 from A7 through C13; confirm arrival on the upper west landing, with no fall-through or immediate re-trigger.
- [ ] Return from A8 to A7 through C13; confirm the maintenance-shaft return spawn is supported.
- [ ] Enter A8 from A9 and return through C14; confirm the lower outer-ring path and both spawn sides.
- [ ] Traverse each intended A8 platform jump in both directions where the route is designed to be reversible.
- [ ] Verify H06's internal entrance and C15's A11 route are distinct, with independent conditions and persistent state.
- [ ] Verify C15 conditions unmet / met / opened / scene reload / death recovery / return from A11.
- [ ] Check that the continuous floor does not permit bypassing the intended high-level route or entering through a locked gate.
- [ ] After a Boss implementation is added, test arena entry, fight boundary, victory flag, death/reset, and post-victory return path.

### Save, death, and interaction
- [ ] Save and reload after opening each macro shortcut and hidden gate; verify persistent flags.
- [ ] Die in A8 and verify the checkpoint does not place the Hero inside a wall, door trigger, or unsupported platform.
- [ ] Confirm C14, C15, H06, the rest point, and Boss arena entrance do not overlap in interaction focus.
- [ ] Check output for scene transition errors, invalid collision geometry, and repeated transition loops.

## 6. Acceptance status / 验收状态

- **Confirmed by source data:** 14 primary regions, C01–C24, L01–L03, H01–H08.
- **Source contracts present:** C13 elevated bidirectional setup; C14 paired main exits; C15 separately gated A8 → A11 route; H06 is separate.
- **Gap identified:** A8 has no dedicated Boss encounter/arena lifecycle in the inspected encounter wiring.
- **Not claimed as passed:** Python validators, Godot import/startup, platform collision, jump reachability, ground bypass, save/load, death recovery, interaction focus, and end-to-end transitions.
