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

    # Learn altered techniques in order so deeper forms cannot bypass earlier understanding.
    # 按顺序理解异变战技，避免直接跳过前置形态。
    if can_understand("blood_iaijutsu") and not ("blood_iaijutsu" in learned_techniques):
        learn_technique("blood_iaijutsu", "blood")
    elif "blood_iaijutsu" in learned_techniques and can_understand("abyss_iaijutsu") and not ("abyss_iaijutsu" in learned_techniques):
        learn_technique("abyss_iaijutsu", "abyssal")
    elif "abyss_iaijutsu" in learned_techniques and can_understand("black_horizon") and not ("black_horizon" in learned_techniques):
        learn_technique("black_horizon", "black_horizon")

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

func get_weapon_technique_id() -> String:
    return "technique_crescent_combo" if is_short_blade() else "technique_judgment_slash"

func can_use_technique(technique_id: String, debug_override: bool = false) -> bool:
    if debug_override:
        return technique_id in ["technique_judgment_slash", "technique_crescent_combo", "eldritch_echo"]
    return WorldState.is_ability_unlocked(technique_id)

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
            # The first mutation requires a learned human form plus a specific sewer discovery.
            # 第一阶段异变必须先学会人类拔刀斩，再完成下水道异形调查。
            var has_basic_form := WorldState.is_ability_unlocked("iaijutsu_basic")
            var defeated_sewer_aberrant := "sewer_aberrant_defeated" in WorldState.achievement_flags
            var carries_aberrant_gland := int(WorldState.upgrade_materials.get("aberrant_gland", 0)) > 0
            return has_basic_form and defeated_sewer_aberrant and carries_aberrant_gland and resonance >= 12 and ancient_exposure >= 1
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
    # Combat uses only forms the Hero has actually understood.
    # 战斗只使用主角已经真正理解的形态。
    if "black_horizon" in learned_techniques:
        return "black_horizon"
    if "abyss_iaijutsu" in learned_techniques:
        return "abyssal"
    if "blood_iaijutsu" in learned_techniques:
        return "blood"
    if WorldState.is_ability_unlocked("iaijutsu_basic"):
        return "human_iaijutsu"
    return "human"

func can_use_blood_iaijutsu() -> bool:
    # Compatibility name retained; L invokes the strongest available iaijutsu form.
    return not get_iaijutsu_profile().is_empty()

func get_iaijutsu_profile() -> Dictionary:
    return get_iaijutsu_profile_for_variant(resolve_iaijutsu_variant())

func get_iaijutsu_profile_for_variant(variant: String) -> Dictionary:
    match variant:
        "human_iaijutsu":
            return {
                "variant": "human_iaijutsu",
                "stamina_cost": 18.0,
                "health_cost": 0,
                "abnormal_load": 0.0,
                "damage_multiplier": 1.6,
                "reach": 104.0,
                "hitbox_size": Vector2(132.0, 52.0),
                "hit_duration": 0.13,
                "attack_time": 0.38,
                "windup": 0.10
            }
        "black_horizon":
            return {
                "variant": "black_horizon",
                "stamina_cost": 36.0,
                "health_cost": 14,
                "abnormal_load": 28.0,
                "damage_multiplier": 3.4,
                "reach": 184.0,
                "hitbox_size": Vector2(216.0, 78.0),
                "hit_duration": 0.24,
                "attack_time": 0.56,
                "windup": 0.19
            }
        "abyssal":
            return {
                "variant": "abyssal",
                "stamina_cost": 30.0,
                "health_cost": 10,
                "abnormal_load": 18.0,
                "damage_multiplier": 2.8,
                "reach": 154.0,
                "hitbox_size": Vector2(184.0, 70.0),
                "hit_duration": 0.20,
                "attack_time": 0.48,
                "windup": 0.15
            }
        "blood":
            return {
                "variant": "blood",
                "stamina_cost": 26.0,
                "health_cost": 8,
                "abnormal_load": 10.0,
                "damage_multiplier": 2.2,
                "reach": 124.0,
                "hitbox_size": Vector2(152.0, 58.0),
                "hit_duration": 0.16,
                "attack_time": 0.42,
                "windup": 0.11
            }
        _:
            return {}

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

func get_stamina_regen_multiplier() -> float:
    if abnormal_load >= 85.0:
        return 0.45
    if abnormal_load >= 65.0:
        return 0.60
    if abnormal_load >= 40.0:
        return 0.75
    if abnormal_load >= 20.0:
        return 0.90
    return 1.0

func get_abnormal_load_tier(value: float = -1.0) -> int:
    var load_value := abnormal_load if value < 0.0 else clampf(value, 0.0, 100.0)
    if load_value >= 85.0:
        return 4
    if load_value >= 65.0:
        return 3
    if load_value >= 40.0:
        return 2
    if load_value >= 20.0:
        return 1
    return 0

func recover_abnormal_load(amount: float) -> void:
    if amount <= 0.0 or abnormal_load <= 0.0:
        return
    var old_tier := get_abnormal_load_tier()
    abnormal_load = maxf(0.0, abnormal_load - amount)
    WorldState.abnormal_load = abnormal_load
    var new_tier := get_abnormal_load_tier()
    if new_tier < old_tier:
        print("[NEREIS][HERO] Abnormal load tier reduced %d -> %d" % [old_tier, new_tier])
    WorldState.save_game()

func add_abnormal_load(amount: float) -> void:
    if amount <= 0.0:
        return
    var old_tier := get_abnormal_load_tier()
    abnormal_load = clampf(abnormal_load + amount, 0.0, 100.0)
    WorldState.abnormal_load = abnormal_load
    var new_tier := get_abnormal_load_tier()
    if new_tier > old_tier:
        print("[NEREIS][HERO] Abnormal load tier increased %d -> %d; stamina regeneration reduced" % [old_tier, new_tier])
    WorldState.save_game()

func clear_abnormal_load() -> void:
    abnormal_load = 0.0
    WorldState.abnormal_load = 0.0
    WorldState.save_game()
