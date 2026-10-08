extends Node
## Protagonist runtime rules.
## 玩家只看到 HP / 体力；共鸣、接触、人性、异常负荷等全部是隐藏状态。

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
    return true

func resolve_iaijutsu_variant() -> String:
    if outer_exposure >= 35 and resonance >= 68 and humanity <= 65:
        return "abyssal"
    if ancient_exposure >= 1 and resonance >= 12:
        return "blood"
    return "human"

func get_weapon_damage_multiplier() -> float:
    return 0.78 if is_short_blade() else 1.0

func get_weapon_reach() -> float:
    return 42.0 if is_short_blade() else 62.0

func get_weapon_stamina_modifier() -> float:
    return 0.82 if is_short_blade() else 1.0

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
