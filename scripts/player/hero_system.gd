extends Node
## Protagonist runtime rules.
## 主角运行时规则。
## Players only see HP and stamina; resonance, exposure, humanity and abnormal load stay hidden.
## 玩家只看到 HP / 体力；共鸣、接触、人性、异常负荷等全部是隐藏状态。

signal technique_understood(technique_id: String)

enum WeaponStyle {
    LONG_SWORD,
    SHORT_BLADE,
}

const WEAPON_NAMES := {
    WeaponStyle.LONG_SWORD: "long_sword",
    WeaponStyle.SHORT_BLADE: "short_blade",
}

var current_weapon: WeaponStyle = WeaponStyle.LONG_SWORD
var resonance := 0
var ancient_exposure := 0
var outer_exposure := 0
var humanity := 100
var abnormal_load := 0.0
var learned_techniques: Array[String] = []
var technique_variants: Dictionary = {}

func _ready() -> void:
    _load_from_world_state()

func _process(_delta: float) -> void:
    # Keep runtime values aligned with saved narrative facts without exposing them in HUD.
    resonance = clampi(int(WorldState.hero_resonance), 0, 100)
    ancient_exposure = clampi(int(WorldState.ancient_exposure), 0, 100)
    outer_exposure = clampi(int(WorldState.outer_exposure), 0, 100)
    humanity = clampi(int(WorldState.hero_humanity), 0, 100)
    abnormal_load = clampf(float(WorldState.abnormal_load), 0.0, 100.0)

    # Discover the first altered technique silently when its world conditions are met.
    if can_understand("blood_iaijutsu") and not ("blood_iaijutsu" in learned_techniques):
        learn_technique("blood_iaijutsu", "blood")

func _load_from_world_state() -> void:
    resonance = clampi(int(WorldState.hero_resonance), 0, 100)
    ancient_exposure = clampi(int(WorldState.ancient_exposure), 0, 100)
    outer_exposure = clampi(int(WorldState.outer_exposure), 0, 100)
    humanity = clampi(int(WorldState.hero_humanity), 0, 100)
    abnormal_load = clampf(float(WorldState.abnormal_load), 0.0, 100.0)

    current_weapon = WeaponStyle.SHORT_BLADE if WorldState.current_weapon_style == "short_blade" else WeaponStyle.LONG_SWORD
    learned_techniques.clear()
    for technique_id in WorldState.learned_techniques:
        learned_techniques.append(str(technique_id))
    technique_variants = WorldState.technique_variants.duplicate(true)

func switch_weapon() -> void:
    current_weapon = WeaponStyle.SHORT_BLADE if current_weapon == WeaponStyle.LONG_SWORD else WeaponStyle.LONG_SWORD
    WorldState.current_weapon_style = WEAPON_NAMES[current_weapon]
    WorldState.save_game()

func is_long_sword() -> bool:
    return current_weapon == WeaponStyle.LONG_SWORD

func is_short_blade() -> bool:
    return current_weapon == WeaponStyle.SHORT_BLADE

func add_resonance(amount: int, source_id: String = "") -> void:
    if amount <= 0:
        return
    resonance = clampi(resonance + amount, 0, 100)
    WorldState.hero_resonance = resonance
    if not source_id.is_empty():
        WorldState.record_resonance_source(source_id)
    WorldState.save_game()

func add_ancient_exposure(amount: int) -> void:
    if amount <= 0:
        return
    ancient_exposure = clampi(ancient_exposure + amount, 0, 100)
    WorldState.ancient_exposure = ancient_exposure
    WorldState.save_game()

func add_outer_exposure(amount: int) -> void:
    if amount <= 0:
        return
    outer_exposure = clampi(outer_exposure + amount, 0, 100)
    WorldState.outer_exposure = outer_exposure
    WorldState.save_game()

func can_understand(technique_id: String) -> bool:
    match technique_id:
        "blood_iaijutsu":
            return resonance >= 12 and ancient_exposure >= 1
        "abyss_iaijutsu":
            return resonance >= 42 and outer_exposure >= 12
        "black_horizon":
            return resonance >= 68 and outer_exposure >= 35 and humanity <= 65
        _:
            return false

func learn_technique(technique_id: String, variant_id: String = "") -> bool:
    if technique_id.is_empty() or technique_id in learned_techniques:
        return false
    if not can_understand(technique_id):
        return false

    learned_techniques.append(technique_id)
    if not variant_id.is_empty():
        technique_variants[technique_id] = variant_id
    WorldState.learned_techniques = learned_techniques.duplicate()
    WorldState.technique_variants = technique_variants.duplicate(true)
    WorldState.save_game()
    technique_understood.emit(technique_id)
    return true

func resolve_iaijutsu_variant() -> String:
    if outer_exposure >= 35 and resonance >= 68 and humanity <= 65:
        return "abyssal"
    if ancient_exposure >= 1 and resonance >= 12:
        return "blood"
    return "human"

func get_combo_limit() -> int:
    return 4 if is_short_blade() else 3

func get_combo_reset_time() -> float:
    return 0.34 if is_short_blade() else 0.42

func get_attack_duration() -> float:
    return 0.23 if is_short_blade() else 0.34

func get_attack_windup() -> float:
    return 0.025 if is_short_blade() else 0.07

func get_combo_damage_multiplier(combo_step: int) -> float:
    if is_short_blade():
        var short_multipliers := [0.72, 0.78, 0.88, 1.05]
        return float(short_multipliers[clampi(combo_step - 1, 0, short_multipliers.size() - 1)])
    var sword_multipliers := [1.0, 1.18, 1.5]
    return float(sword_multipliers[clampi(combo_step - 1, 0, sword_multipliers.size() - 1)])

func get_weapon_reach(combo_step: int = 1) -> float:
    if is_short_blade():
        var short_reach := [27.0, 29.0, 32.0, 36.0]
        return float(short_reach[clampi(combo_step - 1, 0, short_reach.size() - 1)])
    var sword_reach := [48.0, 54.0, 62.0]
    return float(sword_reach[clampi(combo_step - 1, 0, sword_reach.size() - 1)])

func get_weapon_hitbox_size(combo_step: int = 1) -> Vector2:
    if is_short_blade():
        var short_widths := [42.0, 44.0, 48.0, 54.0]
        return Vector2(float(short_widths[clampi(combo_step - 1, 0, short_widths.size() - 1)]), 34.0)
    var sword_widths := [66.0, 72.0, 84.0]
    return Vector2(float(sword_widths[clampi(combo_step - 1, 0, sword_widths.size() - 1)]), 48.0)

func get_weapon_stamina_modifier() -> float:
    return 0.72 if is_short_blade() else 1.0

func get_hit_window_duration(combo_step: int) -> float:
    if is_short_blade():
        return 0.065
    return 0.11 if combo_step < 3 else 0.14

func can_use_blood_iaijutsu() -> bool:
    return "blood_iaijutsu" in learned_techniques

func add_abnormal_load(amount: float) -> void:
    if amount <= 0.0:
        return
    abnormal_load = clampf(abnormal_load + amount, 0.0, 100.0)
    WorldState.abnormal_load = abnormal_load
    WorldState.save_game()

func clear_abnormal_load() -> void:
    abnormal_load = 0.0
    WorldState.abnormal_load = 0.0
    WorldState.save_game()
