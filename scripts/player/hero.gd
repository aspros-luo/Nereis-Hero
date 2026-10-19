extends CharacterBody2D

signal presentation_action_finished(action_name: String)

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const SLASH_ARC_SCRIPT = preload("res://scripts/effects/slash_arc.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")
const HERO_SYSTEM_SCRIPT = preload("res://scripts/player/hero_system.gd")
const ECHO_PULSE_SCRIPT = preload("res://scripts/effects/echo_pulse.gd")
const GRAPPLE_ANCHOR_SCRIPT = preload("res://scripts/systems/grapple_anchor.gd")
const RESONANCE_TARGET_SCRIPT = preload("res://scripts/systems/resonance_hidden_target.gd")
const DEBUG_WALL_SCRIPT = preload("res://scripts/systems/debug_traversal_wall.gd")

const HERO_SKELETON_SCENE = preload("res://scenes/player/hero_skeleton.tscn")

## The skeletal character is now the default production presentation.
## 骨骼角色现为默认正式表现；保留 F8/WorldState 回退开关，供本地验收期间快速回滚。
@export var use_skeleton_visual := true
var skeleton_visual: Node2D
var skeleton_visual_enabled := false

const SPEED := 260.0 # Running speed; retained as the upper movement cap.
const WALK_SPEED := 118.0
const RUN_HOLD_THRESHOLD := 0.22
const ATTACK_MOVE_SPEED := 92.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const DODGE_SPEED := 620.0
# Quick Dash is a separate, non-invulnerable mobility action; values await in-game tuning.
# 快速冲刺是独立位移动作，不提供闪避无敌帧；以下数值仍需实机调校。
const QUICK_DASH_SPEED := 760.0
const QUICK_DASH_DURATION := 0.16
const QUICK_DASH_STAMINA_COST := 24.0
const QUICK_DASH_COOLDOWN := 1.10
const GRAPPLE_MAX_RANGE := 440.0
const GRAPPLE_PULL_SPEED := 860.0
const GRAPPLE_MAX_DURATION := 1.05
const GRAPPLE_COOLDOWN := 0.65
const WALL_CLIMB_SPEED := 160.0
const WALL_SLIDE_SPEED := 118.0
const WALL_JUMP_HORIZONTAL_SPEED := 340.0
const RESONANCE_SIGHT_STAMINA_COST := 10.0
const RESONANCE_SIGHT_DURATION := 4.5
const RESONANCE_SIGHT_COOLDOWN := 6.0
const DEBUG_IAIJUTSU_VARIANTS := ["human_iaijutsu", "blood", "abyssal", "black_horizon"]
const DEBUG_ANCHOR_OFFSETS := [Vector2(230, -130), Vector2(360, -42), Vector2(-190, -150), Vector2(0, -250)]
const DEBUG_REVEAL_OFFSETS := [Vector2(180, -185), Vector2(-205, -170), Vector2(0, -290)]
const ATTACK_DURATION := 0.34
const ATTACK_WINDUP := 0.07
const DODGE_DURATION := 0.18
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const COMBO_RESET_TIME := 0.42
const MAX_STAMINA := 100.0
const ATTACK_STAMINA_COST := 12.0
const DODGE_STAMINA_COST := 28.0
const STAMINA_REGEN_DELAY := 0.65
const STAMINA_REGEN_RATE := 42.0
const HURT_DURATION := 0.18
const HURT_KNOCKBACK := 180.0
const IAIJUTSU_STAMINA_COST := 26.0
const IAIJUTSU_HEALTH_COST := 8
const IAIJUTSU_DAMAGE_MULTIPLIER := 2.2
const IAIJUTSU_REACH := 124.0

# Weapon-bound special techniques. These are initial tuning values, not final balance.
# 武器绑定战技：以下数值是首轮调试基准，不是最终平衡结果。
const JUDGMENT_STAMINA_COST := 20.0
const JUDGMENT_DAMAGE_MULTIPLIER := 1.6
const JUDGMENT_WINDUP := 0.35
const JUDGMENT_DURATION := 0.70
const JUDGMENT_REACH := 66.0
const JUDGMENT_HITBOX_SIZE := Vector2(86.0, 54.0)
const JUDGMENT_HIT_DURATION := 0.14
const CRESCENT_STAMINA_COST := 16.0
const CRESCENT_DAMAGE_MULTIPLIER := 0.65
const CRESCENT_DURATION := 0.56
const CRESCENT_HIT_TIMES := [0.08, 0.23, 0.38]
const CRESCENT_REACH := [35.0, 38.0, 42.0]
const CRESCENT_HITBOX_WIDTHS := [54.0, 58.0, 62.0]
const CRESCENT_HIT_DURATION := 0.065
const ECHO_STAMINA_COST := 28.0
const ECHO_COOLDOWN := 8.0
const ECHO_WINDUP := 0.16
const ECHO_DURATION := 0.42
const ECHO_RANGE := 185.0
const ECHO_STAGGER_DURATION := 0.32

enum CombatState { IDLE, MOVE, JUMP, FALL, ATTACK, DODGE, QUICK_DASH, GRAPPLE, WALL_CLIMB, HURT, DEAD }

var health := 100
## When true, the current level owns death resolution (e.g. a bespoke prologue ending).
var defer_death_recovery := false
var facing := 1.0
var movement_hold_time := 0.0
var attack_time := 0.0
var attack_windup := 0.0
var attack_hit_registered := false
var combo_step := 0
var combo_window := 0.0
var dodge_time := 0.0
var dodge_collision_exceptions: Array[PhysicsBody2D] = []
var quick_dash_time := 0.0
var quick_dash_cooldown_remaining := 0.0
var grapple_requested := false
var grapple_target: Node2D
var grapple_time_remaining := 0.0
var grapple_cooldown_remaining := 0.0
var resonance_sight_requested := false
var resonance_sight_time_remaining := 0.0
var resonance_sight_cooldown_remaining := 0.0
var wall_climb_active := false
var debug_iaijutsu_variant := "human_iaijutsu"
var debug_anchor_fixtures: Array[Node2D] = []
var debug_reveal_fixtures: Array[Node2D] = []
var debug_wall_fixtures: Array[Node2D] = []
# A short opening at dodge start rewards precise timing without adding another resource.
# 闪避起始的短窗口奖励精准操作，不额外引入资源条。
const PERFECT_DODGE_WINDOW := 0.075
const RIPOSTE_BONUS_MULTIPLIER := 1.35
var perfect_dodge_window_remaining := 0.0
var riposte_bonus_active := false
var invulnerable := false
var stamina := MAX_STAMINA
var stamina_regen_delay := 0.0
var hurt_time := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
# Counts only extra mid-air jumps; the ordinary ground/coyote jump is always available.
# 只记录额外空中跳跃次数；地面跳与土狼时间跳始终可用。
var air_jumps_used := 0
const MAX_EXTRA_AIR_JUMPS := 1
var camera_shake_time := 0.0
var camera_shake_strength := 0.0
var hit_confirm_time := 0.0
var state := CombatState.IDLE
var previous_state := CombatState.IDLE
var animation_time := 0.0
var attack_hitbox: Area2D
var attack_requested := false
var technique_requested := false # Legacy iaijutsu prototype input; retained during migration.
var weapon_technique_requested := false
var eldritch_requested := false
var iaijutsu_active := false
var active_action_kind := "none"
var action_elapsed := 0.0
var technique_hit_index := 0
var eldritch_cooldown_remaining := 0.0
var debug_ability_override := false
# Debug overlay is enabled by default on this development branch for acceptance testing.
# 当前开发分支默认开启主角调试覆盖层；F4 可显示/隐藏。
var debug_mode_enabled := true
var dodge_requested := false
var quick_dash_requested := false
var jump_requested := false
var hero_system: Node
signal defeated
signal attack_started(combo_step: int)
signal dodge_started
signal attack_landed(damage: int, target: Node)

func _input(event: InputEvent) -> void:
	if WorldState.input_locked or WorldState.menu_input_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# F4-F6 are consumed here so they cannot also trigger a scene-theater shortcut.
		# F4-F6 在主角输入层消费，避免同时触发场景测试快捷键。
		if event.keycode == KEY_F4:
			debug_mode_enabled = not debug_mode_enabled
			queue_redraw()
			_log("DEBUG", "Hero overlay %s" % ("ON" if debug_mode_enabled else "OFF"))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F5:
			toggle_debug_ability_override()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F6:
			debug_refill_combat_resources()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F8 and OS.is_debug_build():
			WorldState.hero_skeleton_visual_enabled = not WorldState.hero_skeleton_visual_enabled
			_set_skeleton_visual_enabled(WorldState.hero_skeleton_visual_enabled)
			_log("VISUAL", "Skeletal Hero %s (F8 toggles procedural fallback)" % ("ON" if skeleton_visual_enabled else "OFF"))
			get_viewport().set_input_as_handled()
		elif OS.is_debug_build() and event.ctrl_pressed and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]:
			# Ctrl+1..8 are portable debug-only shortcuts; all actions are presentation-only.
			# Ctrl+1 踉跄，2 跪地，3 回头，4 失足，5 倒地，6 起身，7 死亡姿势，8 清除动作。
			match event.keycode:
				KEY_1:
					request_hero_presentation_action("stagger", 0.8)
				KEY_2:
					request_hero_presentation_action("exhausted_kneel", 1.2)
				KEY_3:
					request_hero_presentation_action("look_back", 1.0)
				KEY_4:
					request_hero_presentation_action("stumble", 0.8)
				KEY_5:
					request_hero_presentation_action("knockdown", 0.0)
				KEY_6:
					request_hero_presentation_action("get_up", 1.0, 90)
				KEY_7:
					request_hero_presentation_action("death", 0.0)
				KEY_8:
					clear_hero_presentation_action()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_T:
			# Debug-only smoke test: isolate enemy time scaling from the precision-dodge trigger.
			# 仅限 Debug 覆盖：将敌人减速效果与精准闪避触发条件分开测试。
			if debug_ability_override:
				WorldState.trigger_witch_time(2.4, 0.22)
				_log("DEBUG", "Witch Time test triggered via T; enemy time scale=0.22 for 2.4s")
			else:
				_log("DEBUG", "Witch Time test requires F5 ability override")
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_PAGEUP:
			if debug_ability_override:
				_cycle_debug_iaijutsu_variant(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_PAGEDOWN:
			if debug_ability_override:
				_cycle_debug_iaijutsu_variant(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			if is_instance_valid(grapple_target):
				_cancel_grapple("manual cancel")
			elif state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD]:
				grapple_requested = true
		elif event.keycode == KEY_V:
			resonance_sight_requested = true
		elif event.keycode == KEY_J:
			if state not in [CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD]:
				attack_requested = true
		elif event.keycode == KEY_L:
			if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
				technique_requested = true
		elif event.keycode == KEY_F:
			if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
				weapon_technique_requested = true
		elif event.keycode == KEY_R:
			if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
				eldritch_requested = true
		elif event.keycode == KEY_K or event.keycode == KEY_SHIFT:
			if state not in [CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD]:
				dodge_requested = true
		elif event.keycode == KEY_SPACE or event.keycode == KEY_UP:
			if state not in [CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.HURT, CombatState.DEAD]:
				jump_requested = true
		elif event.keycode == KEY_X:
			if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
				quick_dash_requested = true
		elif event.keycode == KEY_Q:
			if hero_system and state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD]:
				hero_system.switch_weapon()
				queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state != CombatState.QUICK_DASH:
			attack_requested = true

func _ready() -> void:
	hero_system = HERO_SYSTEM_SCRIPT.new()
	hero_system.name = "HeroSystem"
	add_child(hero_system)
	_setup_combat_components()
	_set_skeleton_visual_enabled(use_skeleton_visual or WorldState.hero_skeleton_visual_enabled)
	debug_ability_override = WorldState.debug_ability_override_active
	if debug_ability_override:
		_refresh_debug_test_fixtures(true)
		WorldState.refresh_resonance_reveals(true)
	_log("BOOT", "Hero initialized")
	queue_redraw()

func _setup_combat_components() -> void:
	attack_hitbox = Area2D.new()
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.set_script(HITBOX_SCRIPT)
	add_child(attack_hitbox)
	attack_hitbox.setup(self, Vector2(66, 48), Vector2(facing * 48.0, -28.0))

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.set_script(HURTBOX_SCRIPT)
	add_child(hurtbox)
	hurtbox.setup(self, Vector2(34, 78), Vector2(0, -34))

func _process(delta: float) -> void:
	animation_time += delta
	if is_instance_valid(skeleton_visual) and skeleton_visual.has_method("apply_visual_context"):
		skeleton_visual.call("apply_visual_context", get_visual_context())
	# Physics updates already request redraws. Avoid issuing a second redraw every rendered frame.


func _set_skeleton_visual_enabled(enabled: bool) -> void:
	skeleton_visual_enabled = enabled
	if enabled:
		if not is_instance_valid(skeleton_visual):
			skeleton_visual = HERO_SKELETON_SCENE.instantiate() as Node2D
			skeleton_visual.name = "HeroSkeletonVisual"
			skeleton_visual.connect("presentation_action_finished", _on_skeleton_presentation_action_finished)
			# Keep the presentation rig's local transform nonsingular before it enters Skeleton2D's
			# transform synchronization. Its geometry is authored at unit scale.
			skeleton_visual.scale = Vector2.ONE
			# The rig's feet extend below its root; align them to the production Hero's floor origin.
			skeleton_visual.position = Vector2(0.0, -34.0)
			# Hero can be spawned while its parent scene is still initializing. Attach after the
			# current ready chain so Skeleton2D does not invert a transient singular transform.
			call_deferred("add_child", skeleton_visual)
	else:
		if is_instance_valid(skeleton_visual):
			skeleton_visual.queue_free()
		skeleton_visual = null
	queue_redraw()

## Public presentation-only action request for story beats. Does not lock input or alter gameplay.
## duration <= 0 keeps the visual action active until clear_hero_presentation_action().
func request_hero_presentation_action(action_name: String, duration: float = 0.65, priority: int = -1) -> bool:
	if not is_instance_valid(skeleton_visual) or not skeleton_visual.has_method("request_presentation_action"):
		return false
	return bool(skeleton_visual.call("request_presentation_action", action_name, duration, priority))


func clear_hero_presentation_action() -> void:
	if is_instance_valid(skeleton_visual) and skeleton_visual.has_method("clear_presentation_action"):
		skeleton_visual.call("clear_presentation_action")


func _on_skeleton_presentation_action_finished(action_name: String) -> void:
	presentation_action_finished.emit(action_name)


func _physics_process(delta: float) -> void:
	if state == CombatState.DEAD:
		return

	_update_camera_shake(delta)
	hit_confirm_time = max(0.0, hit_confirm_time - delta)
	eldritch_cooldown_remaining = maxf(0.0, eldritch_cooldown_remaining - delta)
	quick_dash_cooldown_remaining = maxf(0.0, quick_dash_cooldown_remaining - delta)
	grapple_cooldown_remaining = maxf(0.0, grapple_cooldown_remaining - delta)
	resonance_sight_cooldown_remaining = maxf(0.0, resonance_sight_cooldown_remaining - delta)
	if resonance_sight_time_remaining > 0.0:
		resonance_sight_time_remaining = maxf(0.0, resonance_sight_time_remaining - delta)
		if resonance_sight_time_remaining <= 0.0:
			WorldState.set_resonance_sight_active(false)
	_update_jump_buffer(delta)
	_update_combo_window(delta)

	if is_on_floor():
		coyote_time = COYOTE_TIME
		air_jumps_used = 0
	else:
		coyote_time = max(0.0, coyote_time - delta)

	if WorldState.input_locked:
		grapple_requested = false
		_cancel_grapple("world input locked")
		resonance_sight_requested = false
		resonance_sight_time_remaining = 0.0
		WorldState.set_resonance_sight_active(false)
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		quick_dash_requested = false
		jump_requested = false
		jump_buffer = 0.0
		_cancel_attack_action()
		dodge_time = 0.0
		_set_dodge_enemy_collision_ignored(false)
		quick_dash_time = 0.0
		wall_climb_active = false
		perfect_dodge_window_remaining = 0.0
		riposte_bonus_active = false
		if state in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB]:
			_set_state(CombatState.IDLE)
		_reset_camera_shake()
		invulnerable = false
		velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		queue_redraw()
		return

	if hurt_time > 0.0:
		# Inputs received during hitstun are discarded instead of firing after recovery.
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		quick_dash_requested = false
		jump_requested = false
		jump_buffer = 0.0
		grapple_requested = false
		resonance_sight_requested = false
		hurt_time = max(0.0, hurt_time - delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		if hurt_time <= 0.0:
			_set_state(CombatState.IDLE)
		queue_redraw()
		return

	if WorldState.menu_input_locked:
		# Ignore any action queued before the menu opened; ongoing attacks and enemy actions still resolve.
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		quick_dash_requested = false
		jump_requested = false
		jump_buffer = 0.0
		# A menu must not keep carrying the Hero horizontally during an active dash.
		grapple_requested = false
		_cancel_grapple("menu opened")
		resonance_sight_requested = false
		resonance_sight_time_remaining = 0.0
		WorldState.set_resonance_sight_active(false)
		if quick_dash_time > 0.0:
			quick_dash_time = 0.0
			velocity.x = 0.0
			if state == CombatState.QUICK_DASH:
				_set_state(CombatState.IDLE)

	if grapple_requested:
		grapple_requested = false
		if attack_time <= 0.0 and dodge_time <= 0.0:
			_start_grapple()
	if resonance_sight_requested:
		resonance_sight_requested = false
		_toggle_resonance_sight()
	if is_instance_valid(grapple_target):
		# Grapple is a traversal commitment; do not buffer combat actions during the pull.
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		quick_dash_requested = false
		jump_requested = false
		jump_buffer = 0.0
		resonance_sight_requested = false
		_update_grapple(delta)
		queue_redraw()
		return

	if stamina_regen_delay > 0.0:
		stamina_regen_delay = max(0.0, stamina_regen_delay - delta)
	elif stamina < MAX_STAMINA:
		var regen_multiplier: float = hero_system.get_stamina_regen_multiplier() if hero_system else 1.0
		stamina = min(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * regen_multiplier * delta)

	if attack_time > 0.0:
		attack_time = max(0.0, attack_time - delta)
		attack_windup = max(0.0, attack_windup - delta)
		action_elapsed += delta
		match active_action_kind:
			"judgment_slash":
				if attack_windup <= 0.0 and not attack_hit_registered:
					_release_judgment_slash()
					attack_hit_registered = true
			"crescent_combo":
				_update_crescent_combo()
			"eldritch_echo":
				if attack_windup <= 0.0 and not attack_hit_registered:
					_release_eldritch_echo()
					attack_hit_registered = true
			_:
				if attack_windup <= 0.0 and not attack_hit_registered:
					var base_damage := float(WorldState.hero_attack_damage)
					var multiplier: float = hero_system.get_combo_damage_multiplier(combo_step) if hero_system else 1.0
					var iaijutsu_profile: Dictionary = (hero_system.get_iaijutsu_profile_for_variant(debug_iaijutsu_variant) if debug_ability_override else hero_system.get_iaijutsu_profile()) if hero_system and iaijutsu_active else {}
					if iaijutsu_active:
						multiplier = float(iaijutsu_profile.get("damage_multiplier", IAIJUTSU_DAMAGE_MULTIPLIER))
					var damage := int(round(base_damage * multiplier))
					var reach: float = hero_system.get_weapon_reach(combo_step) if hero_system and not iaijutsu_active else float(iaijutsu_profile.get("reach", IAIJUTSU_REACH))
					var shape_size: Vector2 = hero_system.get_weapon_hitbox_size(combo_step) if hero_system and not iaijutsu_active else iaijutsu_profile.get("hitbox_size", Vector2(152, 58))
					attack_hitbox.position.x = facing * reach
					attack_hitbox.set_shape_size(shape_size)
					var hit_duration: float = hero_system.get_hit_window_duration(combo_step) if hero_system and not iaijutsu_active else float(iaijutsu_profile.get("hit_duration", 0.16))
					attack_hitbox.activate(damage, hit_duration)
					_spawn_slash_arc()
					attack_hit_registered = true
					_log("COMBAT", "Hero attack hit window; damage=%d" % damage)
		if attack_time <= 0.0:
			attack_hit_registered = false
			iaijutsu_active = false
			active_action_kind = "none"
			action_elapsed = 0.0
			technique_hit_index = 0

	if perfect_dodge_window_remaining > 0.0:
		perfect_dodge_window_remaining = maxf(0.0, perfect_dodge_window_remaining - delta)

	if quick_dash_requested:
		quick_dash_requested = false
		if attack_time <= 0.0 and dodge_time <= 0.0:
			_start_quick_dash()

	if quick_dash_time > 0.0:
		quick_dash_time = maxf(0.0, quick_dash_time - delta)
		velocity.x = facing * QUICK_DASH_SPEED
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		_set_state(CombatState.QUICK_DASH)
		move_and_slide()
		if quick_dash_time <= 0.0:
			if not is_on_floor():
				_set_state(CombatState.JUMP if velocity.y < 0.0 else CombatState.FALL)
			elif abs(velocity.x) > 10.0:
				_set_state(CombatState.MOVE)
			else:
				_set_state(CombatState.IDLE)
		queue_redraw()
		return

	if dodge_time > 0.0:
		dodge_time = max(0.0, dodge_time - delta)
		_set_dodge_enemy_collision_ignored(true)
		velocity.x = facing * DODGE_SPEED
		_set_state(CombatState.DODGE)
		move_and_slide()
		if dodge_time <= 0.0:
			_set_dodge_enemy_collision_ignored(false)
		queue_redraw()
		return
	elif invulnerable:
		invulnerable = false
		_log("HERO", "Dodge ended; invulnerable=false")

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := 0.0 if WorldState.menu_input_locked else Input.get_axis("ui_left", "ui_right")
	if not WorldState.menu_input_locked:
		if Input.is_key_pressed(KEY_A):
			direction = -1.0
		elif Input.is_key_pressed(KEY_D):
			direction = 1.0

	if direction != 0.0:
		facing = sign(direction)
		movement_hold_time += delta
		var move_speed := ATTACK_MOVE_SPEED if attack_time > 0.0 else (SPEED if movement_hold_time >= RUN_HOLD_THRESHOLD else WALK_SPEED)
		velocity.x = move_toward(velocity.x, direction * move_speed, 2200.0 * delta)
	else:
		movement_hold_time = 0.0
		var friction := 1250.0 if attack_time > 0.0 else 2200.0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	var can_ground_or_coyote_jump := coyote_time > 0.0
	var can_unlocked_double_jump := (debug_ability_override or WorldState.is_ability_unlocked("double_jump")) and air_jumps_used < MAX_EXTRA_AIR_JUMPS and not can_ground_or_coyote_jump
	wall_climb_active = false
	var wall_normal := _get_marked_wall_normal()
	var can_wall_traverse := (debug_ability_override or WorldState.is_ability_unlocked("wall_climb")) and not WorldState.menu_input_locked
	if can_wall_traverse and wall_normal != Vector2.ZERO and not is_on_floor() and attack_time <= 0.0 and dodge_time <= 0.0:
		var pressing_into_wall := absf(direction) < 0.1 or direction * wall_normal.x < -0.1
		if pressing_into_wall:
			if jump_buffer > 0.0:
				jump_buffer = 0.0
				jump_requested = false
				velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
				velocity.y = JUMP_VELOCITY
				coyote_time = 0.0
				_set_state(CombatState.JUMP)
				_log("MOVEMENT", "Wall jump performed")
			else:
				wall_climb_active = true
				if Input.is_key_pressed(KEY_W):
					velocity.y = -WALL_CLIMB_SPEED
				else:
					velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	if wall_climb_active:
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		quick_dash_requested = false

	if jump_buffer > 0.0 and (can_ground_or_coyote_jump or can_unlocked_double_jump) and attack_time <= 0.0 and dodge_time <= 0.0:
		jump_buffer = 0.0
		if can_unlocked_double_jump:
			air_jumps_used += 1
			_log("MOVEMENT", "Double jump used; extra_jumps=%d/%d" % [air_jumps_used, MAX_EXTRA_AIR_JUMPS])
		coyote_time = 0.0
		velocity.y = JUMP_VELOCITY
		_set_state(CombatState.JUMP)

	if weapon_technique_requested and attack_time <= 0.0 and dodge_time <= 0.0:
		weapon_technique_requested = false
		_perform_weapon_technique()
	if eldritch_requested and attack_time <= 0.0 and dodge_time <= 0.0:
		eldritch_requested = false
		_perform_eldritch_echo()
	if technique_requested and attack_time <= 0.0 and dodge_time <= 0.0:
		technique_requested = false
		_perform_iaijutsu()
	if attack_requested and attack_time <= 0.0 and dodge_time <= 0.0:
		attack_requested = false
		_perform_attack()

	if dodge_requested and dodge_time <= 0.0 and attack_time <= 0.0:
		dodge_requested = false
		_start_dodge()

	move_and_slide()

	if wall_climb_active:
		_set_state(CombatState.WALL_CLIMB)
	elif not is_on_floor():
		_set_state(CombatState.JUMP if velocity.y < 0.0 else CombatState.FALL)
	elif attack_time > 0.0:
		_set_state(CombatState.ATTACK)
	elif abs(velocity.x) > 10.0:
		_set_state(CombatState.MOVE)
	else:
		_set_state(CombatState.IDLE)

	queue_redraw()

func _update_jump_buffer(delta: float) -> void:
	if jump_requested or Input.is_action_just_pressed("ui_accept"):
		jump_requested = false
		jump_buffer = JUMP_BUFFER_TIME
	elif jump_buffer > 0.0:
		jump_buffer = max(0.0, jump_buffer - delta)

func _update_combo_window(delta: float) -> void:
	if combo_window > 0.0:
		combo_window = max(0.0, combo_window - delta)
	elif combo_step != 0:
		combo_step = 0

func _perform_attack() -> void:
	var stamina_cost := ATTACK_STAMINA_COST
	if hero_system:
		stamina_cost *= hero_system.get_weapon_stamina_modifier()
	if stamina < stamina_cost:
		return
	stamina -= stamina_cost
	stamina_regen_delay = STAMINA_REGEN_DELAY

	if combo_window > 0.0:
		combo_step = mini(hero_system.get_combo_limit() if hero_system else 3, combo_step + 1)
	else:
		combo_step = 1
	combo_window = hero_system.get_combo_reset_time() if hero_system else 0.42
	if hero_system:
		combo_step = mini(combo_step, hero_system.get_combo_limit())

	iaijutsu_active = false
	active_action_kind = "basic"
	action_elapsed = 0.0
	technique_hit_index = 0
	attack_time = hero_system.get_attack_duration() if hero_system else 0.34
	attack_windup = hero_system.get_attack_windup() if hero_system else 0.07
	attack_hit_registered = false
	if hero_system:
		attack_hitbox.position.x = facing * hero_system.get_weapon_reach(combo_step)
		attack_hitbox.set_shape_size(hero_system.get_weapon_hitbox_size(combo_step))

	_set_state(CombatState.ATTACK)
	attack_started.emit(combo_step)
	_log("COMBAT", "Hero attack %d started; windup=%.2f" % [combo_step, attack_windup])

func _perform_weapon_technique() -> void:
	if not hero_system:
		return
	var technique_id: String = hero_system.get_weapon_technique_id()
	if not hero_system.can_use_technique(technique_id, debug_ability_override):
		_log("TECHNIQUE", "Weapon technique locked: %s" % technique_id)
		return

	var stamina_cost := CRESCENT_STAMINA_COST if technique_id == "technique_crescent_combo" else JUDGMENT_STAMINA_COST
	if stamina < stamina_cost:
		_log("TECHNIQUE", "Insufficient stamina for %s" % technique_id)
		return

	stamina -= stamina_cost
	stamina_regen_delay = STAMINA_REGEN_DELAY
	combo_step = 1
	combo_window = 0.0
	iaijutsu_active = false
	active_action_kind = "crescent_combo" if technique_id == "technique_crescent_combo" else "judgment_slash"
	action_elapsed = 0.0
	technique_hit_index = 0
	attack_hit_registered = false
	attack_time = CRESCENT_DURATION if active_action_kind == "crescent_combo" else JUDGMENT_DURATION
	attack_windup = 0.0 if active_action_kind == "crescent_combo" else JUDGMENT_WINDUP
	_set_state(CombatState.ATTACK)
	_log("TECHNIQUE", "Started %s; stamina=%.0f" % [technique_id, stamina_cost])

func _release_judgment_slash() -> void:
	var damage := int(round(float(WorldState.hero_attack_damage) * JUDGMENT_DAMAGE_MULTIPLIER))
	attack_hitbox.position.x = facing * JUDGMENT_REACH
	attack_hitbox.set_shape_size(JUDGMENT_HITBOX_SIZE)
	attack_hitbox.activate(damage, JUDGMENT_HIT_DURATION)
	_spawn_technique_arc("technique_judgment_slash", 0)
	_log("TECHNIQUE", "Judgment Slash released; damage=%d" % damage)

func _update_crescent_combo() -> void:
	while technique_hit_index < CRESCENT_HIT_TIMES.size() and action_elapsed >= float(CRESCENT_HIT_TIMES[technique_hit_index]):
		_release_crescent_hit(technique_hit_index)
		technique_hit_index += 1

func _release_crescent_hit(stage_index: int) -> void:
	var stage := clampi(stage_index, 0, 2)
	combo_step = stage + 1
	var damage := int(round(float(WorldState.hero_attack_damage) * CRESCENT_DAMAGE_MULTIPLIER))
	attack_hitbox.position.x = facing * float(CRESCENT_REACH[stage])
	attack_hitbox.set_shape_size(Vector2(float(CRESCENT_HITBOX_WIDTHS[stage]), 36.0))
	attack_hitbox.activate(damage, CRESCENT_HIT_DURATION)
	_spawn_technique_arc("technique_crescent_combo", stage)
	_log("TECHNIQUE", "Crescent Combo hit %d/3; damage=%d" % [stage + 1, damage])

func _perform_eldritch_echo() -> void:
	if not hero_system or not hero_system.can_use_technique("eldritch_echo", debug_ability_override):
		_log("TECHNIQUE", "Eldritch Echo locked")
		return
	if eldritch_cooldown_remaining > 0.0:
		_log("TECHNIQUE", "Eldritch Echo cooling down; remaining=%.1f" % eldritch_cooldown_remaining)
		return
	if stamina < ECHO_STAMINA_COST:
		_log("TECHNIQUE", "Insufficient stamina for Eldritch Echo")
		return

	stamina -= ECHO_STAMINA_COST
	stamina_regen_delay = STAMINA_REGEN_DELAY
	eldritch_cooldown_remaining = ECHO_COOLDOWN
	active_action_kind = "eldritch_echo"
	action_elapsed = 0.0
	technique_hit_index = 0
	attack_hit_registered = false
	iaijutsu_active = false
	attack_time = ECHO_DURATION
	attack_windup = ECHO_WINDUP
	combo_step = 1
	combo_window = 0.0
	_set_state(CombatState.ATTACK)
	_log("TECHNIQUE", "Eldritch Echo invoked; cooldown=%.1f" % ECHO_COOLDOWN)

func _release_eldritch_echo() -> void:
	var pulse: Node2D = ECHO_PULSE_SCRIPT.new()
	pulse.global_position = global_position + Vector2(0.0, -30.0)
	get_parent().add_child(pulse)
	var affected := 0
	for target in get_tree().get_nodes_in_group("combat_enemies"):
		if not is_instance_valid(target) or not target is Node2D:
			continue
		if global_position.distance_to((target as Node2D).global_position) > ECHO_RANGE:
			continue
		if target.has_method("apply_echo_stagger") and bool(target.call("apply_echo_stagger", ECHO_STAGGER_DURATION)):
			affected += 1
	_log("TECHNIQUE", "Eldritch Echo resolved; affected_enemies=%d" % affected)

func _spawn_combat_slash_arc(step: int, short_blade: bool) -> void:
	var effect: Node2D = SLASH_ARC_SCRIPT.new()
	effect.global_position = global_position
	get_parent().add_child(effect)
	effect.call("setup", facing, step, short_blade, false, "")

func _spawn_technique_arc(technique_id: String, stage: int) -> void:
	var effect: Node2D = SLASH_ARC_SCRIPT.new()
	effect.global_position = global_position
	get_parent().add_child(effect)
	effect.call("setup_combat_technique", facing, technique_id, stage)

func set_debug_ability_override(enabled: bool) -> void:
	if debug_ability_override == enabled:
		return
	debug_ability_override = enabled
	WorldState.debug_ability_override_active = enabled
	if enabled:
		_refresh_debug_test_fixtures(true)
	else:
		WorldState.clear_witch_time("Debug override disabled")
		_cancel_grapple("debug override disabled")
		if quick_dash_time > 0.0:
			quick_dash_time = 0.0
			velocity.x = 0.0
			if state == CombatState.QUICK_DASH:
				_set_state(CombatState.IDLE)
		quick_dash_requested = false
		resonance_sight_time_remaining = 0.0
		WorldState.set_resonance_sight_active(false)
		if hero_system:
			hero_system.clear_debug_abnormal_load()
		_refresh_debug_test_fixtures(false)
		debug_iaijutsu_variant = "human_iaijutsu"
	WorldState.refresh_resonance_reveals(debug_ability_override)
	queue_redraw()
	_log("DEBUG", "Ability override %s (session only; not saved)" % ("ON" if enabled else "OFF"))

func toggle_debug_ability_override() -> void:
	set_debug_ability_override(not debug_ability_override)

func _cycle_debug_iaijutsu_variant(direction: int) -> void:
	var selected_index := DEBUG_IAIJUTSU_VARIANTS.find(debug_iaijutsu_variant)
	if selected_index < 0:
		selected_index = 0
	selected_index = posmod(selected_index + direction, DEBUG_IAIJUTSU_VARIANTS.size())
	debug_iaijutsu_variant = str(DEBUG_IAIJUTSU_VARIANTS[selected_index])
	_cancel_attack_action()
	_log("DEBUG", "Session-only iaijutsu form selected: %s" % debug_iaijutsu_variant)
	queue_redraw()

func _refresh_debug_test_fixtures(enabled: bool) -> void:
	for fixture in debug_anchor_fixtures + debug_reveal_fixtures + debug_wall_fixtures:
		if is_instance_valid(fixture):
			fixture.queue_free()
	debug_anchor_fixtures.clear()
	debug_reveal_fixtures.clear()
	debug_wall_fixtures.clear()
	if not enabled or get_parent() == null:
		return

	for index in range(DEBUG_ANCHOR_OFFSETS.size()):
		var anchor := Node2D.new()
		anchor.set_script(GRAPPLE_ANCHOR_SCRIPT)
		anchor.name = "DebugGrappleAnchor_%d" % index
		anchor.set("debug_fixture", true)
		anchor.set("anchor_label", "TEST ANCHOR %d" % (index + 1))
		get_parent().add_child(anchor)
		anchor.global_position = global_position + DEBUG_ANCHOR_OFFSETS[index]
		debug_anchor_fixtures.append(anchor)

	for index in range(DEBUG_REVEAL_OFFSETS.size()):
		var hidden_target := Node2D.new()
		hidden_target.set_script(RESONANCE_TARGET_SCRIPT)
		hidden_target.name = "DebugResonanceTarget_%d" % index
		get_parent().add_child(hidden_target)
		hidden_target.global_position = global_position + DEBUG_REVEAL_OFFSETS[index]
		hidden_target.call("configure", [0, 15, 32][index], [0, 1, 1][index], [0, 0, 12][index], "TRACE %d" % (index + 1), true)
		debug_reveal_fixtures.append(hidden_target)

	for offset in [-210.0, 210.0]:
		var wall := StaticBody2D.new()
		wall.set_script(DEBUG_WALL_SCRIPT)
		wall.name = "DebugWall_%s" % ("Left" if offset < 0.0 else "Right")
		get_parent().add_child(wall)
		wall.global_position = global_position + Vector2(offset, -90.0)
		debug_wall_fixtures.append(wall)

	_log("DEBUG", "Temporary traversal fixtures created: 4 anchors, 3 hidden traces, 2 marked walls")

func _start_grapple() -> void:
	if state in [CombatState.ATTACK, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.HURT, CombatState.DEAD] or attack_time > 0.0 or dodge_time > 0.0 or quick_dash_time > 0.0 or hurt_time > 0.0:
		_log("MOVEMENT", "Grapple cannot start during the current action")
		return
	if not (debug_ability_override or WorldState.is_ability_unlocked("grapple")):
		_log("MOVEMENT", "Grapple locked")
		return
	if grapple_cooldown_remaining > 0.0:
		_log("MOVEMENT", "Grapple cooling down; remaining=%.2f" % grapple_cooldown_remaining)
		return
	var best_target: Node2D
	var best_distance := GRAPPLE_MAX_RANGE
	for candidate in get_tree().get_nodes_in_group("grapple_anchors"):
		if not is_instance_valid(candidate) or candidate == self or not candidate is Node2D:
			continue
		var candidate_node := candidate as Node2D
		var distance := global_position.distance_to(candidate_node.global_position)
		if distance <= best_distance:
			best_distance = distance
			best_target = candidate_node
	if not is_instance_valid(best_target):
		_log("MOVEMENT", "No grapple anchor in range (max %.0f)" % GRAPPLE_MAX_RANGE)
		return

	_cancel_attack_action()
	grapple_target = best_target
	grapple_time_remaining = GRAPPLE_MAX_DURATION
	grapple_cooldown_remaining = GRAPPLE_COOLDOWN
	attack_requested = false
	technique_requested = false
	weapon_technique_requested = false
	eldritch_requested = false
	dodge_requested = false
	quick_dash_requested = false
	jump_requested = false
	jump_buffer = 0.0
	invulnerable = false
	velocity = Vector2.ZERO
	_set_state(CombatState.GRAPPLE)
	_log("MOVEMENT", "Grapple started; target=%s distance=%.0f" % [best_target.name, best_distance])

func _update_grapple(delta: float) -> void:
	if not is_instance_valid(grapple_target):
		_cancel_grapple("target lost")
		return
	grapple_time_remaining = maxf(0.0, grapple_time_remaining - delta)
	if grapple_time_remaining <= 0.0:
		_cancel_grapple("timeout")
		return
	var to_target := grapple_target.global_position - global_position
	if to_target.length() <= 34.0:
		_cancel_grapple("target reached")
		return
	velocity = to_target.normalized() * GRAPPLE_PULL_SPEED
	move_and_slide()
	_set_state(CombatState.GRAPPLE)

func _cancel_grapple(reason: String = "") -> void:
	var grapple_was_active := is_instance_valid(grapple_target) or grapple_time_remaining > 0.0 or state == CombatState.GRAPPLE
	if not is_instance_valid(grapple_target):
		grapple_target = null
		grapple_time_remaining = 0.0
		velocity = Vector2.ZERO
		if state == CombatState.GRAPPLE:
			_set_state(CombatState.IDLE)
		if grapple_was_active and not reason.is_empty():
			_log("MOVEMENT", "Grapple ended: %s" % reason)
		return
	grapple_target = null
	grapple_time_remaining = 0.0
	velocity = Vector2.ZERO
	if state == CombatState.GRAPPLE:
		_set_state(CombatState.IDLE)
	if grapple_was_active and not reason.is_empty():
		_log("MOVEMENT", "Grapple ended: %s" % reason)

func _toggle_resonance_sight() -> void:
	if resonance_sight_time_remaining > 0.0:
		resonance_sight_time_remaining = 0.0
		WorldState.set_resonance_sight_active(false)
		_log("SENSE", "Resonance Sight disabled")
		return
	if not (debug_ability_override or WorldState.is_ability_unlocked("resonance_sight")):
		_log("SENSE", "Resonance Sight locked")
		return
	if resonance_sight_cooldown_remaining > 0.0:
		_log("SENSE", "Resonance Sight cooling down")
		return
	if stamina < RESONANCE_SIGHT_STAMINA_COST:
		_log("SENSE", "Insufficient stamina for Resonance Sight")
		return
	stamina -= RESONANCE_SIGHT_STAMINA_COST
	stamina_regen_delay = STAMINA_REGEN_DELAY
	resonance_sight_time_remaining = RESONANCE_SIGHT_DURATION
	resonance_sight_cooldown_remaining = RESONANCE_SIGHT_COOLDOWN
	WorldState.set_resonance_sight_active(true)
	WorldState.refresh_resonance_reveals(debug_ability_override)
	_log("SENSE", "Resonance Sight active for %.1fs" % RESONANCE_SIGHT_DURATION)

func _get_marked_wall_normal() -> Vector2:
	if not is_on_wall():
		return Vector2.ZERO
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider = collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("wall_climb_surfaces"):
			var normal := collision.get_normal()
			if absf(normal.x) >= 0.70:
				return normal
	return Vector2.ZERO

func debug_refill_combat_resources() -> void:
	WorldState.clear_witch_time("Debug refill")
	WorldState.set_resonance_sight_active(false)
	resonance_sight_time_remaining = 0.0
	resonance_sight_cooldown_remaining = 0.0
	_cancel_grapple("Debug refill")
	wall_climb_active = false
	if hero_system:
		hero_system.clear_debug_abnormal_load()
	_reset_camera_shake()
	hit_confirm_time = 0.0
	air_jumps_used = 0
	health = 100
	stamina = MAX_STAMINA
	stamina_regen_delay = 0.0
	eldritch_cooldown_remaining = 0.0
	quick_dash_time = 0.0
	quick_dash_cooldown_remaining = 0.0
	quick_dash_requested = false
	grapple_requested = false
	grapple_cooldown_remaining = 0.0
	resonance_sight_requested = false
	invulnerable = false
	hurt_time = 0.0
	dodge_time = 0.0
	_set_dodge_enemy_collision_ignored(false)
	perfect_dodge_window_remaining = 0.0
	riposte_bonus_active = false
	attack_requested = false
	technique_requested = false
	weapon_technique_requested = false
	eldritch_requested = false
	dodge_requested = false
	jump_requested = false
	jump_buffer = 0.0
	velocity.x = 0.0
	combo_step = 0
	combo_window = 0.0
	_cancel_attack_action()
	if state in [CombatState.HURT, CombatState.DODGE, CombatState.QUICK_DASH, CombatState.GRAPPLE, CombatState.WALL_CLIMB, CombatState.ATTACK]:
		_set_state(CombatState.IDLE)
	_log("DEBUG", "HP/stamina/cooldowns restored; queued actions cleared (session only)")

func get_debug_action_kind() -> String:
	return active_action_kind

func get_debug_eldritch_cooldown() -> float:
	return eldritch_cooldown_remaining

func _perform_iaijutsu() -> void:
	if not hero_system:
		return
	var profile: Dictionary
	if debug_ability_override:
		profile = hero_system.get_iaijutsu_profile_for_variant(debug_iaijutsu_variant)
	else:
		if not hero_system.can_use_blood_iaijutsu():
			return
		profile = hero_system.get_iaijutsu_profile()
	if profile.is_empty():
		return

	var stamina_cost := float(profile.get("stamina_cost", IAIJUTSU_STAMINA_COST))
	var health_cost := int(profile.get("health_cost", IAIJUTSU_HEALTH_COST))
	if stamina < stamina_cost or health <= health_cost:
		return

	stamina -= stamina_cost
	health -= health_cost
	stamina_regen_delay = STAMINA_REGEN_DELAY
	active_action_kind = "iaijutsu"
	action_elapsed = 0.0
	technique_hit_index = 0
	hero_system.add_abnormal_load(float(profile.get("abnormal_load", 10.0)), debug_ability_override)
	combo_step = 3
	combo_window = 0.0
	attack_time = float(profile.get("attack_time", 0.42))
	attack_windup = float(profile.get("windup", 0.11))
	attack_hit_registered = false
	iaijutsu_active = true
	_set_state(CombatState.ATTACK)
	_log("COMBAT", "%s used; hidden abnormal load increased" % str(profile.get("variant", "blood")))


func _set_dodge_enemy_collision_ignored(ignored: bool) -> void:
	# Dodge may pass through ordinary enemy bodies, but never changes collision with terrain,
	# doors, shutters, or level boundaries. Keep this independent from invulnerability frames.
	# 翻滚只忽略普通敌人的物理身体，不修改墙壁、地面、门、封锁障碍或关卡边界碰撞。
	if ignored:
		for candidate in get_tree().get_nodes_in_group("combat_enemies"):
			if not is_instance_valid(candidate) or not candidate is PhysicsBody2D or candidate == self:
				continue
			var enemy := candidate as PhysicsBody2D
			if not dodge_collision_exceptions.has(enemy):
				add_collision_exception_with(enemy)
				dodge_collision_exceptions.append(enemy)
		return
	for enemy in dodge_collision_exceptions:
		if is_instance_valid(enemy):
			remove_collision_exception_with(enemy)
	dodge_collision_exceptions.clear()

func _start_dodge() -> void:
	if stamina < DODGE_STAMINA_COST:
		return
	stamina -= DODGE_STAMINA_COST
	stamina_regen_delay = STAMINA_REGEN_DELAY
	dodge_time = DODGE_DURATION
	_set_dodge_enemy_collision_ignored(true)
	perfect_dodge_window_remaining = PERFECT_DODGE_WINDOW
	invulnerable = true
	_set_state(CombatState.DODGE)
	dodge_started.emit()
	_log("HERO", "Dodge started; invulnerable=true")

func _start_quick_dash() -> void:
	if not debug_ability_override and not WorldState.is_ability_unlocked("quick_dash"):
		_log("MOVEMENT", "Quick dash locked; ability is not unlocked")
		return
	if quick_dash_cooldown_remaining > 0.0:
		_log("MOVEMENT", "Quick dash cooling down; remaining=%.2f" % quick_dash_cooldown_remaining)
		return
	if stamina < QUICK_DASH_STAMINA_COST:
		_log("MOVEMENT", "Insufficient stamina for Quick Dash")
		return

	_cancel_attack_action()
	stamina -= QUICK_DASH_STAMINA_COST
	stamina_regen_delay = STAMINA_REGEN_DELAY
	quick_dash_time = QUICK_DASH_DURATION
	quick_dash_cooldown_remaining = QUICK_DASH_COOLDOWN
	# Do not carry buffered actions through a dash and fire them after the dash ends.
	attack_requested = false
	technique_requested = false
	weapon_technique_requested = false
	eldritch_requested = false
	dodge_requested = false
	grapple_requested = false
	resonance_sight_requested = false
	jump_requested = false
	jump_buffer = 0.0
	invulnerable = false
	_set_state(CombatState.QUICK_DASH)
	_log("MOVEMENT", "Quick Dash started; stamina=%.0f cooldown=%.2f" % [QUICK_DASH_STAMINA_COST, QUICK_DASH_COOLDOWN])

func _set_state(next_state: CombatState) -> void:
	if state == next_state:
		return
	previous_state = state
	state = next_state
	_log("STATE", "%s -> %s" % [_state_name(previous_state), _state_name(state)])

func _state_name(value: CombatState) -> String:
	return CombatState.keys()[value]

func get_debug_state() -> String:
	return _state_name(state)

## Presentation-only contract for the future skeletal visual adapter.
## 仅供未来骨骼表现层读取；战斗规则仍由本控制器拥有。
func get_visual_state_name() -> String:
	match state:
		CombatState.IDLE:
			return "idle"
		CombatState.MOVE:
			return "run"
		CombatState.JUMP:
			return "jump"
		CombatState.FALL:
			return "fall"
		CombatState.ATTACK:
			if hero_system != null and hero_system.is_short_blade():
				return "attack_short"
			return "attack_long"
		CombatState.DODGE:
			return "dodge"
		CombatState.QUICK_DASH:
			return "quick_dash"
		CombatState.GRAPPLE:
			return "grapple"
		CombatState.WALL_CLIMB:
			return "wall_climb"
		CombatState.HURT:
			return "hurt"
		CombatState.DEAD:
			return "death"
	return "idle"


func get_visual_context() -> Dictionary:
	# Return a snapshot only; callers must never mutate gameplay state through it.
	return {
		"state": get_visual_state_name(),
		"combat_state": _state_name(state),
		"previous_combat_state": _state_name(previous_state),
		"facing": facing,
		"combo_step": combo_step,
		"weapon": "short_blade" if hero_system != null and hero_system.is_short_blade() else "long_sword",
		"action_kind": active_action_kind,
		"action_elapsed": action_elapsed,
		"vertical_velocity": velocity.y,
		"horizontal_speed": velocity.x,
		"movement_mode": "run" if absf(velocity.x) >= WALK_SPEED + 20.0 and movement_hold_time >= RUN_HOLD_THRESHOLD else ("walk" if absf(velocity.x) > 8.0 else "idle"),
		"grounded": is_on_floor(),
		"attack_time_remaining": attack_time,
		"attack_windup_remaining": attack_windup,
		"invulnerable": invulnerable,
		"hurt_time_remaining": hurt_time,
		"iaijutsu_active": iaijutsu_active
	}

func _spawn_slash_arc() -> void:
	var effect: Node2D = SLASH_ARC_SCRIPT.new()
	effect.global_position = global_position
	get_parent().add_child(effect)
	var variant: String = (debug_iaijutsu_variant if debug_ability_override else hero_system.resolve_iaijutsu_variant()) if hero_system != null and iaijutsu_active else ""
	effect.call("setup", facing, combo_step, hero_system != null and hero_system.is_short_blade(), iaijutsu_active, variant)

func _spawn_hit_spark() -> void:
	var effect := Node2D.new()
	effect.set_script(HIT_SPARK_SCRIPT)
	effect.global_position = global_position + Vector2(0, -34)
	get_parent().add_child(effect)

func _spawn_death_burst() -> void:
	var effect: Node2D = DEATH_BURST_SCRIPT.new()
	effect.global_position = global_position + Vector2(0, -38)
	get_parent().add_child(effect)
	effect.call("setup", 18.0)

func modify_outgoing_damage(base_damage: int) -> int:
	# Consume the riposte only when a hitbox actually connects, not when an attack misses.
	# 只有攻击判定真正命中时才消耗反击奖励，挥空不会消耗。
	if not riposte_bonus_active:
		return base_damage
	riposte_bonus_active = false
	var boosted_damage := int(round(float(base_damage) * RIPOSTE_BONUS_MULTIPLIER))
	_log("COMBAT", "Perfect-dodge riposte confirmed; damage %d -> %d" % [base_damage, boosted_damage])
	queue_redraw()
	return boosted_damage

func _on_attack_hit(damage: int, target: Node) -> void:
	hit_confirm_time = 0.07
	var technique_finisher := active_action_kind == "judgment_slash" or (active_action_kind == "crescent_combo" and technique_hit_index >= 3)
	var finisher: bool = combo_step >= (hero_system.get_combo_limit() if hero_system else 3) or technique_finisher
	var impact_strength: float = 10.0 if technique_finisher else 9.0 if iaijutsu_active else 4.0 + float(combo_step) * 1.0
	var hitstop_duration: float = 0.055 if finisher or iaijutsu_active else 0.038
	var hitstop_scale: float = 0.06 if finisher or iaijutsu_active else 0.08
	WorldState.trigger_hitstop(hitstop_duration, hitstop_scale)
	_shake_camera(impact_strength, 0.08)
	velocity.x = facing * (105.0 if hero_system and hero_system.is_short_blade() else 190.0 if finisher else 145.0)
	attack_landed.emit(damage, target)
	_log("COMBAT", "Attack confirmed; damage=%d target=%s" % [damage, target.name if target else "Unknown"])

func _shake_camera(strength: float, duration: float) -> void:
	camera_shake_strength = max(camera_shake_strength, strength)
	camera_shake_time = max(camera_shake_time, duration)

func _update_camera_shake(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	if camera_shake_time > 0.0:
		camera_shake_time = max(0.0, camera_shake_time - delta)
		var fade: float = clampf(camera_shake_time / 0.10, 0.0, 1.0)
		camera.offset = Vector2(
			randf_range(-camera_shake_strength, camera_shake_strength) * fade,
			randf_range(-camera_shake_strength, camera_shake_strength) * fade * 0.65
		)
	else:
		camera.offset = Vector2.ZERO
		camera_shake_strength = 0.0

func receive_damage(amount: int, source: Node = null) -> void:
	if state == CombatState.DEAD:
		return
	if invulnerable:
		# Only a hit avoided during the opening dodge window counts as a perfect dodge.
		# 只有闪避起始窗口内成功避开攻击，才算精准闪避。
		if dodge_time > 0.0 and perfect_dodge_window_remaining > 0.0:
			riposte_bonus_active = true
			perfect_dodge_window_remaining = 0.0
			if debug_ability_override or WorldState.is_ability_unlocked("witch_time"):
				WorldState.trigger_witch_time(2.4, 0.22)
			_log("COMBAT", "Perfect dodge! Next hit bonus armed")
		else:
			_log("COMBAT", "Hero damage ignored (invulnerable=true)")
		return
	WorldState.clear_witch_time("Hero received damage")
	resonance_sight_time_remaining = 0.0
	WorldState.set_resonance_sight_active(false)
	_cancel_grapple("damage")
	health = max(0, health - amount)
	_spawn_hit_spark()
	WorldState.trigger_hitstop(0.032, 0.10)
	_shake_camera(9.0, 0.12)
	# A confirmed hit interrupts the Hero's current action; never let a stale hitbox resolve after hitstun.
	_cancel_attack_action()
	quick_dash_time = 0.0
	quick_dash_requested = false
	wall_climb_active = false
	perfect_dodge_window_remaining = 0.0
	riposte_bonus_active = false
	attack_requested = false
	technique_requested = false
	weapon_technique_requested = false
	eldritch_requested = false
	dodge_requested = false
	quick_dash_requested = false
	grapple_requested = false
	resonance_sight_requested = false
	jump_requested = false
	jump_buffer = 0.0
	combo_step = 0
	combo_window = 0.0
	dodge_time = 0.0
	_set_dodge_enemy_collision_ignored(false)
	invulnerable = false
	hurt_time = HURT_DURATION
	velocity.y = -120.0
	if source and source is Node2D:
		velocity.x = sign(global_position.x - source.global_position.x) * HURT_KNOCKBACK
	else:
		velocity.x = -facing * HURT_KNOCKBACK
	_set_state(CombatState.HURT)
	var source_name: String = source.name if source else "Unknown"
	_log("COMBAT", "%s -> Hero damage=%d hp=%d" % [source_name, amount, health])
	if health == 0:
		_set_state(CombatState.DEAD)
		_spawn_death_burst()
		_log("HERO", "Hero defeated; resetting vertical slice")
		defeated.emit()
		if defer_death_recovery:
			# The owning level handles this authored defeat; do not run checkpoint respawn in parallel.
			return
		var death_layer: CanvasLayer = await _play_death_fade_out_and_wait()
		health = 100
		global_position = WorldState.checkpoint_position
		velocity = Vector2.ZERO
		air_jumps_used = 0
		coyote_time = 0.0
		jump_buffer = 0.0
		invulnerable = true
		stamina = MAX_STAMINA
		hurt_time = 0.0
		attack_time = 0.0
		attack_windup = 0.0
		attack_hit_registered = false
		iaijutsu_active = false
		active_action_kind = "none"
		action_elapsed = 0.0
		technique_hit_index = 0
		eldritch_cooldown_remaining = 0.0
		dodge_time = 0.0
		_set_dodge_enemy_collision_ignored(false)
		quick_dash_time = 0.0
		quick_dash_cooldown_remaining = 0.0
		quick_dash_requested = false
		grapple_requested = false
		grapple_time_remaining = 0.0
		grapple_cooldown_remaining = 0.0
		resonance_sight_requested = false
		resonance_sight_time_remaining = 0.0
		resonance_sight_cooldown_remaining = 0.0
		wall_climb_active = false
		WorldState.clear_witch_time("Hero death")
		WorldState.set_resonance_sight_active(false)
		stamina_regen_delay = 0.0
		combo_step = 0
		combo_window = 0.0
		_deactivate_attack_hitbox()
		attack_requested = false
		technique_requested = false
		weapon_technique_requested = false
		eldritch_requested = false
		dodge_requested = false
		jump_requested = false
		jump_buffer = 0.0
		_deactivate_attack_hitbox()
		_reset_camera_shake()
		hit_confirm_time = 0.0
		_log("WORLD", "Hero respawned at checkpoint=%s" % WorldState.checkpoint_position)
		# Restore the standing combat/visual state while the screen is still fully black.
		# 在黑屏仍覆盖画面时恢复站立状态，避免复活后闪过倒地姿势。
		_set_state(CombatState.IDLE)
		await _fade_in_and_remove_death_overlay(death_layer)
		get_tree().create_timer(0.75).timeout.connect(_clear_respawn_invulnerability)

## Fade out and move to the checkpoint, returning the still-opaque overlay so gameplay
## state can be fully restored before the fade-in begins.
func _play_death_fade_out_and_wait() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "DeathTransition"
	layer.layer = 100
	# Parent the overlay to the current scene, not the root. A scene change must clean it up.
	var overlay_parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	overlay_parent.add_child(layer)
	var overlay := ColorRect.new()
	overlay.name = "Fade"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	var fade_out := create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(overlay, "color:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	await get_tree().create_timer(0.35).timeout

	# The fade covers the teleport to checkpoint, avoiding a visible snap.
	global_position = WorldState.checkpoint_position
	velocity = Vector2.ZERO
	return layer

func _fade_in_and_remove_death_overlay(layer: CanvasLayer) -> void:
	if not is_instance_valid(layer):
		return
	var overlay := layer.get_node_or_null("Fade") as ColorRect
	if overlay == null:
		layer.queue_free()
		return
	var fade_in := create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(overlay, "color:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	if is_instance_valid(layer):
		layer.queue_free()

func restore_full() -> void:
	WorldState.clear_witch_time("rest point")
	resonance_sight_time_remaining = 0.0
	resonance_sight_cooldown_remaining = 0.0
	WorldState.set_resonance_sight_active(false)
	_cancel_grapple("rest point")
	if hero_system:
		hero_system.recover_abnormal_load(35.0)
	health = 100
	stamina = MAX_STAMINA
	stamina_regen_delay = 0.0
	hurt_time = 0.0
	velocity = Vector2.ZERO
	air_jumps_used = 0
	coyote_time = 0.0
	jump_buffer = 0.0
	invulnerable = false
	attack_time = 0.0
	attack_windup = 0.0
	attack_hit_registered = false
	iaijutsu_active = false
	eldritch_cooldown_remaining = 0.0
	dodge_time = 0.0
	_set_dodge_enemy_collision_ignored(false)
	quick_dash_time = 0.0
	quick_dash_cooldown_remaining = 0.0
	quick_dash_requested = false
	grapple_requested = false
	grapple_cooldown_remaining = 0.0
	resonance_sight_requested = false
	resonance_sight_time_remaining = 0.0
	resonance_sight_cooldown_remaining = 0.0
	WorldState.clear_witch_time("rest point")
	WorldState.set_resonance_sight_active(false)
	wall_climb_active = false
	_reset_camera_shake()
	hit_confirm_time = 0.0
	combo_step = 0
	combo_window = 0.0
	_cancel_attack_action()
	perfect_dodge_window_remaining = 0.0
	riposte_bonus_active = false
	attack_requested = false
	technique_requested = false
	weapon_technique_requested = false
	eldritch_requested = false
	dodge_requested = false
	jump_requested = false
	_set_state(CombatState.IDLE)
	_log("HERO", "Hero fully restored at rest point")

func take_damage(amount: int) -> void:
	receive_damage(amount, null)

func _cancel_attack_action() -> void:
	attack_time = 0.0
	attack_windup = 0.0
	attack_hit_registered = false
	iaijutsu_active = false
	active_action_kind = "none"
	action_elapsed = 0.0
	technique_hit_index = 0
	_deactivate_attack_hitbox()

func _deactivate_attack_hitbox() -> void:
	if is_instance_valid(attack_hitbox) and attack_hitbox.has_method("deactivate"):
		attack_hitbox.deactivate()

func _reset_camera_shake() -> void:
	camera_shake_time = 0.0
	camera_shake_strength = 0.0
	var camera := get_viewport().get_camera_2d()
	if camera:
		camera.offset = Vector2.ZERO

func _clear_respawn_invulnerability() -> void:
	invulnerable = false
	_log("HERO", "Respawn invulnerability ended")

func _log(category: String, message: String) -> void:
	print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
	# Keep the procedural renderer as a live fallback; only one character silhouette is drawn at a time.
	if skeleton_visual_enabled:
		_draw_skeleton_mode_overlay()
		return
	var idle_bob: float = sin(animation_time * 7.0) * 1.5 if state == CombatState.IDLE else 0.0
	var run_step: float = sin(animation_time * 11.0) * 2.5 if state == CombatState.MOVE else 0.0
	var dodging := state == CombatState.DODGE
	var crouch: float = 10.0 if dodging else 0.0
	var lean: float = 8.0 if attack_time > 0.0 and attack_windup <= 0.0 else 0.0
	var bob := idle_bob - crouch
	var armor := Color("#3d3740") if hurt_time <= 0.0 else Color("#8d414b")
	var armor_light := Color("#70616a") if hurt_time <= 0.0 else Color("#d35a62")
	var armor_shadow := Color("#242129")
	var cloak := Color("#252129")
	var metal := Color("#b7a48c")
	var bone := Color("#d6c7b2")

	# Grounding shadow and the cloak silhouette make the pose readable at a glance.
	_draw_shadow_ellipse(Vector2(0, 2), 30.0, 7.0, Color(0.04, 0.03, 0.05, 0.42))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -39 + bob), Vector2(13, -39 + bob),
		Vector2(23 - lean, -5 + run_step), Vector2(36 - lean, 13 + run_step),
		Vector2(3, 8 + run_step), Vector2(-29, 15 - run_step),
		Vector2(-23, -9 - run_step)
	]), armor_shadow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -37 + bob), Vector2(11, -38 + bob),
		Vector2(20 - lean, -6 + run_step), Vector2(27 - lean, 9 + run_step),
		Vector2(2, 5 + run_step), Vector2(-23, 11 - run_step),
		Vector2(-19, -10 - run_step)
	]), cloak)

	# Torn split-cloak tails give the knight a stronger silhouette without changing collision.
	# 破损分叉披风强化骑士轮廓；仅为绘制层，不改变碰撞。
	var cloak_sway := sin(animation_time * (13.0 if state == CombatState.MOVE else 5.0)) * (5.0 if state == CombatState.MOVE else 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -27 + bob), Vector2(-8, -20 + bob),
		Vector2(-13 - cloak_sway, 4 + run_step), Vector2(-22 - cloak_sway, 16 + run_step),
		Vector2(-25 - cloak_sway, 5 + run_step), Vector2(-31, 12 + run_step),
		Vector2(-28, -10 + bob)
	]), Color("#302831"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -24 + bob), Vector2(-10, -18 + bob),
		Vector2(-17 - cloak_sway, 3 + run_step), Vector2(-22 - cloak_sway, 9 + run_step),
		Vector2(-22, -4 + bob)
	]), Color("#51404a"))
	draw_line(Vector2(-15, -20 + bob), Vector2(-20 - cloak_sway, 5 + run_step), Color("#80616a", 0.72), 1.5)
	draw_line(Vector2(-18, -13 + bob), Vector2(-27, 11 + run_step), armor, 8.0)
	draw_line(Vector2(-27, 11 + run_step), Vector2(-34, 13 + run_step), armor_shadow, 5.0)
	draw_line(Vector2(12, -12 + bob), Vector2(19 - lean, 10 - run_step), armor, 8.0)
	draw_line(Vector2(19 - lean, 10 - run_step), Vector2(27 - lean, 12 - run_step), armor_shadow, 5.0)
	draw_line(Vector2(-16, -8 + bob), Vector2(-5, -8 + bob), metal, 2.0)

	# Breastplate, layered pauldrons, belt and engraved edge highlights.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -39 + bob), Vector2(14, -39 + bob),
		Vector2(18 - lean, -12 + bob), Vector2(8 - lean, -4 + bob),
		Vector2(-10, -4 + bob), Vector2(-20, -14 + bob)
	]), armor)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -34 + bob), Vector2(1, -37 + bob),
		Vector2(10 - lean, -14 + bob), Vector2(0, -11 + bob),
		Vector2(-13, -15 + bob)
	]), Color("#514852"))
	draw_line(Vector2(-8, -32 + bob), Vector2(-2, -16 + bob), armor_light, 2.0)
	draw_line(Vector2(3, -31 + bob), Vector2(8 - lean, -17 + bob), armor_shadow, 2.0)
	draw_line(Vector2(-14, -12 + bob), Vector2(13 - lean, -12 + bob), metal, 3.0)
	draw_rect(Rect2(-3 - lean * 0.3, -15 + bob, 7, 6), Color("#241d25"))
	draw_rect(Rect2(-1 - lean * 0.3, -14 + bob, 3, 4), metal)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, -36 + bob), Vector2(-14, -43 + bob),
		Vector2(-5, -37 + bob), Vector2(-10, -28 + bob),
		Vector2(-21, -29 + bob)
	]), armor_light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(9 - lean, -38 + bob), Vector2(17 - lean, -42 + bob),
		Vector2(25 - lean, -35 + bob), Vector2(21 - lean, -27 + bob),
		Vector2(10 - lean, -29 + bob)
	]), armor_light)
	draw_line(Vector2(-20, -35 + bob), Vector2(-12, -37 + bob), bone, 1.5)
	draw_line(Vector2(13 - lean, -36 + bob), Vector2(20 - lean, -34 + bob), bone, 1.5)

	# Closed helm: no visible face, only a narrow cold slit.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -57 + bob), Vector2(-12, -72 + bob),
		Vector2(-3, -78 + bob), Vector2(10, -73 + bob),
		Vector2(16, -62 + bob), Vector2(12, -48 + bob),
		Vector2(-10, -48 + bob)
	]), armor_shadow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -59 + bob), Vector2(-9, -70 + bob),
		Vector2(-2, -74 + bob), Vector2(8, -70 + bob),
		Vector2(12, -61 + bob), Vector2(8, -51 + bob),
		Vector2(-8, -51 + bob)
	]), armor)
	draw_line(Vector2(-10, -63 + bob), Vector2(10, -63 + bob), metal, 2.0)
	draw_line(Vector2(-8, -60 + bob), Vector2(8, -60 + bob), Color("#17151b"), 2.5)
	draw_line(Vector2(-2, -72 + bob), Vector2(1, -65 + bob), armor_light, 1.5)
	draw_line(Vector2(-12, -54 + bob), Vector2(10, -51 + bob), armor_light, 1.5)
	# Three small rivets and a narrow visor glint make the closed helm readable at gameplay scale.
	# 三枚铆钉与狭窄面甲反光，让封闭头盔在实战缩放下仍可辨识。
	for rivet_x in [-7.0, 0.0, 7.0]:
		draw_circle(Vector2(rivet_x, -47 + bob), 1.2, metal)
	var visor_glow := 0.0
	if resonance_sight_time_remaining > 0.0:
		visor_glow = 0.48 + 0.22 * sin(animation_time * 9.0)
	elif invulnerable:
		visor_glow = 0.34
	if visor_glow > 0.0:
		draw_line(Vector2(-7, -60 + bob), Vector2(7, -60 + bob), Color(0.54, 0.84, 0.88, visor_glow), 2.0)
		draw_circle(Vector2(facing * 9, -60 + bob), 2.0, Color(0.54, 0.84, 0.88, visor_glow * 0.48))

	# The blade changes pose between wind-up and active frames, helping attacks read.
	var hand := Vector2(facing * (12.0 - lean * 0.25), -28.0 + bob)
	var blade_tip: Vector2
	if attack_time > 0.0 and attack_windup > 0.0:
		blade_tip = Vector2(-facing * 36.0, -56.0 + bob)
	elif attack_time > 0.0:
		blade_tip = Vector2(facing * (72.0 + combo_step * 4.0), -48.0 - combo_step * 3.0 + bob)
	elif dodging:
		blade_tip = Vector2(facing * 42.0, -18.0 + bob)
	else:
		blade_tip = Vector2(facing * 56.0, -46.0 + bob)
	draw_line(hand, blade_tip, armor_shadow, 8.0)
	draw_line(hand, blade_tip, metal, 4.0)
	draw_line(hand + Vector2(0, -1), blade_tip + Vector2(-facing * 4.0, -2.0), bone, 1.3)
	draw_line(hand + Vector2(-facing * 5.0, 5.0), hand + Vector2(facing * 5.0, -5.0), armor_light, 3.0)
	draw_circle(hand, 4.0, armor_shadow)
	draw_circle(hand, 2.0, metal)
	# A restrained edge glint follows the blade; it intensifies only during the active attack frames.
	# 克制的刃口反光跟随武器，仅在攻击有效帧增强。
	var blade_glint_alpha := 0.20
	if attack_time > 0.0 and attack_windup <= 0.0:
		blade_glint_alpha = 0.72 if combo_step == 3 else 0.48
	draw_line(hand + Vector2(-facing * 2.0, -2.0), blade_tip + Vector2(-facing * 3.0, -2.0), Color(0.92, 0.86, 0.74, blade_glint_alpha), 1.4)

	if WorldState.hidden_resistance_awakened:
		var anchor_color := Color("#aa8d72") if WorldState.mite_control_stage < 2 else Color("#8d6c98")
		draw_circle(Vector2(-13, -1 + bob), 4.0, Color(0.75, 0.66, 0.55, 0.32))
		draw_arc(Vector2(-13, -1 + bob), 7.0, 0.0, TAU, 16, anchor_color, 2.0)

	if hit_confirm_time > 0.0:
		draw_arc(Vector2(facing * 30, -28), 70.0, 0.0, TAU, 24, Color("#efe1c8"), 5.0)
	elif attack_time > 0.0 and attack_windup <= 0.0:
		var arc_start := -1.20 if facing > 0 else 1.20
		var arc_end := 1.20 if facing > 0 else 5.08
		var arc_radius := 64.0 + combo_step * 3.0
		draw_arc(Vector2(facing * 26, -27), arc_radius, arc_start, arc_end, 20, Color(0.88, 0.80, 0.68, 0.92), 5.0)
		draw_arc(Vector2(facing * 28, -27), arc_radius + 8.0, arc_start + 0.08, arc_end - 0.08, 16, Color(0.42, 0.35, 0.38, 0.62), 2.0)
		if combo_step == 3:
			draw_line(Vector2(facing * 18, -24), Vector2(facing * 94, -44), Color("#eee0c8"), 2.0)
	elif attack_time > 0.0:
		draw_arc(Vector2(facing * 24, -28), 42.0, -0.45 if facing > 0 else 3.59, 0.45 if facing > 0 else 4.49, 12, Color("#c3a98d"), 3.0)

	draw_string(ThemeDB.fallback_font, Vector2(-52, -88), "HERO %d" % health, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
	draw_rect(Rect2(-32, -100, 64, 5), Color("#27212a"))
	draw_rect(Rect2(-32, -100, 64.0 * (stamina / MAX_STAMINA), 5), Color("#b7a48c"))
	if combo_step > 0 and attack_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -112), "%d" % combo_step, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e0d6c3"))


## Draw UI and combat feedback that must remain visible when the skeleton replaces the procedural body.
## 骨骼替换程序角色主体时，仍需绘制的状态 UI 与战斗反馈。
func _draw_skeleton_mode_overlay() -> void:
	_draw_shadow_ellipse(Vector2(0, 2), 30.0, 7.0, Color(0.04, 0.03, 0.05, 0.42))
	var hud_color := Color("#d6c7b2")
	draw_string(ThemeDB.fallback_font, Vector2(-52, -88), "HERO %d" % health, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, hud_color)
	draw_rect(Rect2(-32, -100, 64, 5), Color("#27212a"))
	draw_rect(Rect2(-32, -100, 64.0 * (stamina / MAX_STAMINA), 5), Color("#b7a48c"))
	if combo_step > 0 and attack_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -112), "%d" % combo_step, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e0d6c3"))
	if invulnerable:
		draw_arc(Vector2(0, -34), 25.0, 0.0, TAU, 24, Color(0.54, 0.84, 0.88, 0.38), 1.5)
	if WorldState.hidden_resistance_awakened:
		var anchor_color := Color("#aa8d72") if WorldState.mite_control_stage < 2 else Color("#8d6c98")
		draw_arc(Vector2(-13, -1), 7.0, 0.0, TAU, 16, anchor_color, 2.0)
	if hit_confirm_time > 0.0:
		draw_arc(Vector2(facing * 30, -28), 70.0, 0.0, TAU, 24, Color("#efe1c8"), 5.0)
	elif attack_time > 0.0 and attack_windup <= 0.0:
		var arc_start := -1.20 if facing > 0 else 1.20
		var arc_end := 1.20 if facing > 0 else 5.08
		var arc_radius := 64.0 + combo_step * 3.0
		draw_arc(Vector2(facing * 26, -27), arc_radius, arc_start, arc_end, 20, Color(0.88, 0.80, 0.68, 0.82), 4.0)
		if combo_step == 3:
			draw_line(Vector2(facing * 18, -24), Vector2(facing * 94, -44), Color("#eee0c8"), 2.0)
	elif attack_time > 0.0:
		draw_arc(Vector2(facing * 24, -28), 42.0, -0.45 if facing > 0 else 3.59, 0.45 if facing > 0 else 4.49, 12, Color("#c3a98d"), 3.0)


func _draw_shadow_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
