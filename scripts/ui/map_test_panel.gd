extends Control
## Temporary map acceptance tools. All changes stay in memory while WorldState.debug_map_test_mode is active.
## 临时地图验收工具。开启地图测试模式后，所有调试改动只保留在内存中。


# Natural exploration walkthrough. This is guidance only: it never changes progression or teleports the Hero.
# 自然探索逐步指引：只显示路线建议，不修改进度、不传送主角。
const GUIDE_STEPS: Array[Dictionary] = [
	{"region":"A0","title":"01/31｜逃离手术所","text":"正常完成序章战斗与逃脱，沿真实出口进入 A1。不要使用地图传送。"},
	{"region":"A1","title":"02/31｜确认村庄枢纽","text":"探索村庄、与可交互 NPC 对话并确认可见出口；优先沿正常路线前往 A2。"},
	{"region":"A2","title":"03/31｜调查静止的钟","text":"沿雾林旧朝圣路前进，寻找不会移动的钟并按 V 开启灵视、按 E 调查。确认鸣响／灵视能力正常解锁。"},
	{"region":"A2","title":"04/31｜回看倒响钟室入口","text":"在钟墓附近开启灵视，寻找异常入口；达到鸣响 18 且调查钟的线索后，尝试按 E 开启 H02。若条件不足，先继续主线并记下此处，之后回访。"},
	{"region":"H02","title":"05/31｜倒响钟室往返","text":"若已进入 H02，走到另一端检查远侧出口，再通过入口返回 A2；确认不是单向软锁。未显现则跳过并稍后回访。"},
	{"region":"A3","title":"06/31｜进入被遗忘城区","text":"从 A2 沿真实城区入口进入 A3；调查第三街路牌／不合理的街道结构，记住异常位置。"},
	{"region":"A3","title":"07/31｜寻找被删去的第三街","text":"在城区开启灵视并调查第三街异常；鸣响达到 28 后尝试 H03。进入后必须找到返回 A3 的出口。"},
	{"region":"A4","title":"08/31｜下水道与旧水库","text":"从已发现的真实入口进入 A4，调查新管道下方的古老石层；尝试开启水闸／检查井回路，确认能回到 A1 或旧城区。"},
	{"region":"H01","title":"09/31｜村庄井底回声层","text":"回到 A1 的井口，在鸣响达到 12 后用灵视寻找 H01；进入后走完整段并从远侧返回地表。"},
	{"region":"H04","title":"10/31｜水面背后的楼梯","text":"在 A4 旧水库寻找反射不一致的阶梯；鸣响达到 36 且古神接触至少 1 后尝试 H04，确认隐藏区有回程。"},
	{"region":"A5","title":"11/31｜旧战场与边境堡垒","text":"沿主线进入 A5，检查战壕、堡垒门与尸体朝向；寻找通往 A6 的路，并留意 A2 旧朝圣高路／钟塔的反向捷径。"},
	{"region":"A6","title":"12/31｜修道院与钟塔","text":"进入 A6，调查没有影子的钟与无声钟窗；开启能从钟塔返回城区的下落捷径，之后实际走一次 A6 ↔ A3 回环。"},
	{"region":"H05","title":"13/31｜无声钟室","text":"在 A6 开启灵视，鸣响达到 42 且古神接触至少 1 后调查无声钟窗，尝试进入 H05；从另一端走回 A6。"},
	{"region":"A7","title":"14/31｜监牢与维护竖井","text":"沿主线进入 A7，检查牢门、登记册与维护竖井；寻找供给隧道／监牢侧回路，确认开门后能从两侧通行。"},
	{"region":"A8","title":"15/31｜旧王墓与王名石碑","text":"进入 A8，调查被刮除的王室姓名与墓门；此处是王国深层路线枢纽，记录暂时打不开的侧门，稍后带着 A2 钟线索回来。"},
	{"region":"H06","title":"16/31｜王名抹除廊","text":"鸣响达到 55、古神接触至少 2，并调查 A2 的钟与 A8 王室石碑后，在 A8 开启灵视寻找 H06；进入后确认能返回王墓。"},
	{"region":"A9","title":"17/31｜王城外环与镜街线索","text":"进入 A9，检查王城外环、旧升降机、排水门和雨中倒影；按 V 调查镜街异常。不要把看见入口误当成已开门。"},
	{"region":"H07","title":"18/31｜镜街：雨幕背后","text":"鸣响达到 68、外神接触至少 12 且外神共鸣成立后，调查 A9 镜街异常并尝试进入 H07；走到远端，验证镜街侧门／回程。"},
	{"region":"A10","title":"19/31｜大圣堂与静默侧堂","text":"从 A9 正常进入 A10，探索朝圣阶梯与教会内廷；寻找静默侧堂入口，确认它与 A11 的 C19 连接真实可走。"},
	{"region":"A11","title":"20/31｜深层研究区：王墓入口","text":"优先从 A8 侧验证 C15：鸣响至少 55、古神接触至少 2，并调查 A2 钟与 A8 王室石碑。按 E 开门进入 A11，检查入口落点和回程。"},
	{"region":"A11","title":"21/31｜深层研究区：静默侧堂入口","text":"再从 A10 静默侧堂验证 C19：鸣响至少 68、外神接触至少 12、外神共鸣成立且调查 A9 镜街异常。确认第二入口不是仅有状态标记。"},
	{"region":"H08","title":"22/31｜胎宫／原初空腔","text":"在 A11 达到鸣响 78、古神接触至少 2、外神接触至少 18、外神共鸣成立，并调查 A2 钟、A3 第三街、A4 古老石层后寻找 H08；结局出口还受剧情状态约束。"},
	{"region":"A4","title":"23/31｜补完边境箱庭环","text":"回到 A4，实际走通 A3 → A4 → A1 的水闸／井道回环；检查每个入口的出生点不会压在门或 NPC 身上。"},
	{"region":"A3","title":"24/31｜补完中层箱庭环","text":"从 A6 已开启的钟塔下落捷径返回 A3，再从 A3 回到 A6；确认捷径确实缩短回程，不只是地图标记已开启。"},
	{"region":"A8","title":"25/31｜王国深层环的王墓侧","text":"从 A8 重新走向 A9，并尝试王室运输侧门／王墓侧门；记录哪些必须从另一侧开启。"},
	{"region":"A9","title":"26/31｜王国深层环的外环侧","text":"从 A9 实际打开旧升降机、王室排水道及可用侧门，再走 A9 → A4 的回路；确认从 A4 回到 A8/A9 不会卡在入口。"},
	{"region":"A10","title":"27/31｜教会内廷回访","text":"回访 A10，检查已发现的静默侧堂、侧门和捷径；确认从 A11 返回时出生位置安全，并检查相邻 E 交互提示是否冲突。"},
	{"region":"A12","title":"28/31｜王室内城与王座区","text":"沿 A10 的真实主线出口进入 A12；检查王室内城与王座区的空间连接、回程门及剧情推进，不使用传送跳过主线。"},
	{"region":"H09","title":"29/31｜可选支线：崖下实验窟","text":"在 A6 击败疯狂神职人员后，沿真实出口返回 A1 村庄；确认蜂巢封条发生变化并出现洞口。进入 H09 击败古神实验体，确认第三根脐带残片只计为烈火天罚的一个条件，随后从洞穴出口回到村庄。此支线不得阻塞凡人之墓主线。"},
	{"region":"ALL","title":"30/31｜隐藏区回程复核","text":"按自然探索记录逐个回看已进入的 H01–H08：确认入口已发现、门已开启、实际进入三种状态分离；每个隐藏区都能按设计返回。"},
	{"region":"ALL","title":"31/31｜完成记录与恢复正式存档","text":"确认自然探索实走地图达到 22/22，并在 Output 检查 [NEREIS][MAP][NATURAL_TEST] 记录。然后点击“退出测试并恢复磁盘存档”，回到标题菜单用“继续游戏”确认正式存档未被污染。"}
]

const MAPS: Array[Dictionary] = [
	{"label": "A0｜教会手术所与逃脱通道", "scene": "res://scenes/escape_prologue.tscn"},
	{"label": "A1｜边境村庄", "scene": "res://scenes/village_hub.tscn"},
	{"label": "A2｜雾林、钟墓与旧朝圣路", "scene": "res://scenes/ash_forest.tscn"},
	{"label": "A3｜废弃城区", "scene": "res://scenes/forgotten_city.tscn"},
	{"label": "A4｜下水道、沉积大厅与旧水库", "scene": "res://scenes/sewer_reservoir.tscn"},
	{"label": "A5｜旧战场与边境堡垒", "scene": "res://scenes/old_battlefield.tscn"},
	{"label": "A6｜修道院、回廊与钟塔", "scene": "res://scenes/monastery_tower.tscn"},
	{"label": "A7｜监牢、忏悔井与维护竖井", "scene": "res://scenes/prison_depths.tscn"},
	{"label": "A8｜旧王墓与王室地下道", "scene": "res://scenes/royal_tomb.tscn"},
	{"label": "A9｜王城外环与废弃街区", "scene": "res://scenes/royal_outer_ring.tscn"},
	{"label": "A10｜大圣堂、朝圣阶梯与教会内廷", "scene": "res://scenes/grand_cathedral.tscn"},
	{"label": "A11｜古神遗迹与深层研究区", "scene": "res://scenes/deep_research_depths.tscn"},
	{"label": "A12｜王室内城与王座区", "scene": "res://scenes/inner_city.tscn"},
	{"label": "H01｜井底回声层", "scene": "res://scenes/hidden_well.tscn"},
	{"label": "H02｜倒响钟室", "scene": "res://scenes/hidden_bell_chamber.tscn"},
	{"label": "H03｜被删去的第三街", "scene": "res://scenes/erased_third_street.tscn"},
	{"label": "H04｜水面背后的楼梯", "scene": "res://scenes/reflected_stairwell.tscn"},
	{"label": "H05｜无声钟室", "scene": "res://scenes/silent_bell_room.tscn"},
	{"label": "H06｜王名抹除廊", "scene": "res://scenes/erased_royal_name_corridor.tscn"},
	{"label": "H07｜镜街：雨幕背后", "scene": "res://scenes/mirror_street.tscn"},
	{"label": "H08｜胎宫／原初空腔", "scene": "res://scenes/primordial_hollow.tscn"},
	{"label": "H09｜崖下实验窟", "scene": "res://scenes/cliff_cave_experiment.tscn"}
]


# Navigation data mirrors the authored exit and clue positions in the playable graybox scenes.
# 导航坐标对应可玩灰盒场景中实际生成的出口与线索位置。
const OBJECTIVE_POINTS: Dictionary = {
	"A0": [{"x":620.0,"name":"手术托盘线索"},{"x":2040.0,"name":"最右侧逃脱出口"}],
	"A2": [{"x":735.0,"name":"从未移动的钟"},{"x":1530.0,"name":"第二道回声"},{"x":2300.0,"name":"倒响钟室异常入口"}],
	"A3": [{"x":900.0,"name":"第三街路牌异常"}],
	"A4": [{"x":980.0,"name":"管道下的古老石层"},{"x":1780.0,"name":"水面背后的阶梯入口"}],
	"A5": [{"x":1100.0,"name":"迟于死者抵达的命令"}],
	"A6": [{"x":850.0,"name":"疯狂神职人员"},{"x":1125.0,"name":"无声之窗"},{"x":1660.0,"name":"无声钟室入口"}],
	"A7": [{"x":1070.0,"name":"无名者名册"}],
	"A8": [{"x":1530.0,"name":"被刮去的王室姓名"},{"x":1870.0,"name":"王名抹除廊入口"},{"x":2310.0,"name":"深层研究区王室竖井"}],
	"A9": [{"x":1380.0,"name":"水洼中的镜街异常"},{"x":1850.0,"name":"镜街入口"}],
	"A10": [{"x":700.0,"name":"双重封印的圣物匣"},{"x":1900.0,"name":"静默侧堂入口"}],
	"A11": [{"x":1450.0,"name":"第二位观测者"},{"x":2300.0,"name":"胎宫入口"}],
	"A12": [{"x":1070.0,"name":"国王未曾拆开的信"}],
	"H01": [{"x":1600.0,"name":"井中无水"}],
	"H02": [{"x":1650.0,"name":"声音之后的钟"}],
	"H03": [{"x":2020.0,"name":"跳过三号的门牌"}],
	"H04": [{"x":1740.0,"name":"向下攀升的阶梯"}],
	"H05": [{"x":1960.0,"name":"无影档案"}],
	"H06": [{"x":1980.0,"name":"石头记得的名字"}],
	"H07": [{"x":2200.0,"name":"多出来的一盏灯"}],
	"H08": [{"x":1850.0,"name":"空摇篮"}],
	"H09": [{"x":1450.0,"name":"古神实验体"},{"x":1850.0,"name":"银线束缚环"}]
}
const STEP_OBJECTIVE_POINTS: Dictionary = {
	3: {"region":"A2","x":2300.0,"name":"倒响钟室异常入口","condition":"鸣响达到 18，并调查静止的钟"},
	6: {"region":"A3","x":1120.0,"name":"被删去的第三街入口","condition":"鸣响达到 28，并调查第三街路牌"}
}
const EXIT_HINTS: Dictionary = {
	"A0": [{"target":"A1","x":2040.0,"name":"最右侧逃脱出口","condition":"先击败三名守卫，出口开启后按 E"}],
	"A1": [{"target":"A2","x":2440.0,"name":"最右侧北门／旧朝圣路","condition":"村庄防卫章节完成后开放"},{"target":"A3","x":100.0,"name":"最左侧旧排水通道","condition":"村庄防卫章节完成后开放"},{"target":"H01","x":1555.0,"name":"村庄中右部的井口异常","condition":"鸣响达到 12 并开启灵视"},{"target":"H09","x":2260.0,"name":"东侧屋顶下方的崖下实验窟","condition":"击败 A6 疯狂神职人员，并从其他区域实际返回村庄"}],
	"A2": [{"target":"A1","x":72.0,"name":"最左侧村庄出口","condition":""},{"target":"A3","x":2240.0,"name":"东侧树冠高台上的城区主路出口","condition":"沿上层平台连续攀升后按 E"},{"target":"H02","x":2300.0,"name":"东侧地面的倒响钟室异常入口","condition":"鸣响达到 18，并调查静止的钟"},{"target":"A5","x":1880.0,"name":"右侧旧朝圣高路捷径","condition":"须先从 A5 侧开启"}],
	"A3": [{"target":"A2","x":72.0,"name":"最左侧旧朝圣路出口","condition":""},{"target":"A4","x":1480.0,"name":"中右部下水道入口","condition":""},{"target":"A5","x":2240.0,"name":"东侧高台上的战场出口","condition":"沿残墙平台跳上高路后按 E"},{"target":"H03","x":1120.0,"name":"第三街路牌旁的异常入口","condition":"鸣响达到 28，并调查第三街路牌"},{"target":"A6","x":1710.0,"name":"右侧钟塔落差捷径","condition":"须先从 A6 侧开启"}],
	"A4": [{"target":"A3","x":72.0,"name":"最左侧城区检修舱口","condition":"首次互动开启舱口，再按 E 通行"},{"target":"A1","x":2350.0,"name":"最右侧村庄井道水闸","condition":"首次互动开闸，再按 E 通行"},{"target":"A7","x":1050.0,"name":"左半区监牢补给隧道","condition":"须先从 A7 侧开启"},{"target":"A8","x":1250.0,"name":"中部王墓水道","condition":"须先从 A8 侧开启"},{"target":"A9","x":1450.0,"name":"中右部王城排水道","condition":"须先从 A9 侧开启"},{"target":"H04","x":1780.0,"name":"右侧倒影阶梯异常入口","condition":"鸣响达到 36、古神接触达到 1"},{"target":"H01","x":2510.0,"name":"最右侧井道暗门","condition":"鸣响达到 12 且开启灵视"}],
	"A5": [{"target":"A3","x":72.0,"name":"最左侧城区出口","condition":""},{"target":"A6","x":2528.0,"name":"最右侧修道院入口","condition":""},{"target":"A2","x":520.0,"name":"左侧旧朝圣高路门","condition":"首次互动开启，再按 E 通行"}],
	"A6": [{"target":"A5","x":72.0,"name":"最左侧战场出口","condition":""},{"target":"A7","x":2528.0,"name":"最右侧监牢入口","condition":""},{"target":"A3","x":2110.0,"name":"右侧钟塔落差捷径","condition":"首次互动开启，再按 E 通行"},{"target":"H05","x":1660.0,"name":"右半区无声钟室入口","condition":"鸣响达到 42、古神接触达到 1"}],
	"A7": [{"target":"A6","x":72.0,"name":"最左侧修道院出口","condition":""},{"target":"A8","x":2528.0,"name":"最右侧旧王墓入口","condition":""},{"target":"A4","x":520.0,"name":"左侧补给隧道","condition":"首次互动开启，再按 E 通行"}],
	"A8": [{"target":"A7","x":72.0,"name":"最左侧监牢出口","condition":""},{"target":"A9","x":2528.0,"name":"最右侧王城外环出口","condition":""},{"target":"A4","x":520.0,"name":"左侧王墓水道","condition":"首次互动开启，再按 E 通行"},{"target":"H06","x":1870.0,"name":"右侧王名抹除廊入口","condition":"鸣响 55、古神接触 2，调查 A2 静止的钟与本区王名石碑"},{"target":"A11","x":2310.0,"name":"最右侧王室竖井入口","condition":"同样要求钟线索与王名石碑线索"}],
	"A9": [{"target":"A8","x":72.0,"name":"最左侧王墓出口","condition":""},{"target":"A10","x":2528.0,"name":"最右侧大圣堂入口","condition":""},{"target":"A3","x":520.0,"name":"左侧旧升降梯","condition":"首次互动开启，再按 E 通行"},{"target":"A4","x":720.0,"name":"左半区王城排水门","condition":"首次互动开启，再按 E 通行"},{"target":"H07","x":1850.0,"name":"右半区镜街异常入口","condition":"鸣响 68、外神接触 12、外神共鸣成立并调查镜街异常"},{"target":"H06","x":2200.0,"name":"最右侧王室运输门","condition":"须先发现并开启王名抹除廊"}],
	"A10": [{"target":"A9","x":72.0,"name":"最左侧王城外环出口","condition":""},{"target":"A12","x":2528.0,"name":"最右侧王室内城入口","condition":""},{"target":"A11","x":1900.0,"name":"右半区静默侧堂入口","condition":"鸣响 68、外神接触 12、外神共鸣成立并调查 A9 镜街异常"}],
	"A11": [{"target":"A8","x":72.0,"name":"最左侧王室竖井回程","condition":"须从 A8 侧开启 C15"},{"target":"A10","x":2528.0,"name":"最右侧大圣堂回程","condition":"须从 A10 侧开启 C19"},{"target":"H08","x":2300.0,"name":"右侧胎宫入口","condition":"鸣响 78、古神接触 2、外神接触 18、外神共鸣，并调查 A2/A3/A4 三处线索"}],
	"A12": [{"target":"A10","x":72.0,"name":"最左侧大圣堂出口","condition":""},{"target":"A9","x":520.0,"name":"左侧内城侧门","condition":"须先沿主线抵达内城并开启"},{"target":"H07","x":2250.0,"name":"右侧镜街侧门","condition":"须先发现并开启镜街侧门"},{"target":"ENDING","x":2528.0,"name":"最右侧王座区出口","condition":"按当前剧情状态进入结局"}],
	"H01": [{"target":"A1","x":72.0,"name":"最左侧地表出口","condition":""},{"target":"A4","x":2495.0,"name":"最右侧井道闸门","condition":"须从 A4 侧解锁"}],
	"H02": [{"target":"A2","x":72.0,"name":"最左侧旧朝圣路出口","condition":""},{"target":"A5","x":2495.0,"name":"最右侧钟塔通路","condition":"须从 A5 侧开启"}],
	"H03": [{"target":"A3","x":72.0,"name":"最左侧城区出口","condition":""},{"target":"A9","x":2495.0,"name":"最右侧旧服务门","condition":"须从 A9 侧开启"}],
	"H04": [{"target":"A4","x":72.0,"name":"最左侧水库出口","condition":""},{"target":"A8","x":2495.0,"name":"最右侧王墓侧门","condition":"须从 A8 侧开启"}],
	"H05": [{"target":"A6","x":72.0,"name":"最左侧修道院出口","condition":""},{"target":"A3","x":2495.0,"name":"最右侧钟塔落差通路","condition":"须从 A6 侧开启"}],
	"H06": [{"target":"A8","x":72.0,"name":"最左侧王墓出口","condition":""},{"target":"A9","x":2495.0,"name":"最右侧王室运输门","condition":"须从 A9 侧开启"}],
	"H07": [{"target":"A9","x":72.0,"name":"最左侧镜街出口","condition":""},{"target":"A12","x":2495.0,"name":"最右侧内城侧门","condition":"须从内城侧开启"}],
	"H08": [{"target":"A11","x":72.0,"name":"最左侧深层研究区出口","condition":""},{"target":"ENDING","x":2528.0,"name":"最右侧梦境出口","condition":"需要满足物理结合剧情状态"}],
	"H09": [{"target":"A1","x":72.0,"name":"返回村庄山崖","condition":""}]
}

const ALL_PATH_IDS := [
	"C04", "C05", "C06", "C07", "C10", "C12", "C15", "C16", "C18", "C19",
	"C21", "C22", "C23", "C24", "H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09"
]
const ALL_ANOMALIES := [
	"anomaly_bell_retiming", "anomaly_old_pilgrim_echo", "anomaly_erased_street_sign",
	"anomaly_old_stone_layer", "anomaly_battlefield_late_orders", "anomaly_silent_bell_window",
	"anomaly_prisoner_register", "anomaly_erased_royal_name", "anomaly_mirror_street_echo",
	"anomaly_double_sealed_reliquary", "anomaly_observer_reaction", "anomaly_kings_unopened_letter",
	"hidden_well_no_water", "hidden_bell_after_sound", "hidden_third_street_numbers",
	"hidden_stair_reflection", "hidden_bell_shadowless_record", "hidden_royal_name_scrape",
	"hidden_mirror_lamp_count", "hidden_primordial_cradle"
]
const PROGRESSION_FLAGS := [
	"village_defense_survived", "reached_A5", "reached_A7", "reached_A8_via_A7",
	"defeated_mad_cleric", "returned_to_village_after_mad_cleric", "cliff_cave_hint_seen", "cliff_cave_experiment_defeated", "third_umbilical_cord_fragment_acquired", "village_intro_seen",
	"reached_A9_via_A8", "reached_A10_via_A9", "reached_A12_via_A10",
	"opened_old_pilgrim_highroad", "opened_sewer_inspection_hatch_from_A4",
	"opened_watergate_and_village_well_exit", "opened_royal_tomb_gate",
	"opened_bell_tower_drop", "opened_supply_tunnel", "opened_old_lift_from_A9",
	"opened_inner_city_side_gate", "opened_royal_drain_from_outer_ring",
	"reached_A5_and_opened_old_pilgrim_highroad", "reached_A7_then_opened_supply_tunnel",
	"reached_A8_via_A7_then_opened_royal_tomb_gate", "reached_A9_via_A8_then_opened_old_lift_from_A9",
	"reached_A9_then_opened_royal_drain_from_outer_ring", "reached_A9_via_A8_then_opened_royal_transport_side_door",
	"reached_A8_then_opened_royal_tomb_side_door", "reached_A5_then_opened_old_bell_tower_connection",
	"reached_A9_then_opened_old_service_door", "opened_royal_transport_side_door",
	"opened_royal_tomb_side_door", "opened_old_bell_tower_connection", "opened_old_service_door",
	"opened_mirror_street_side_gate", "discovered_royal_tomb_maintenance_shaft_after_reaching_A8",
	"discovered_and_opened_silent_side_chapel_in_A10", "ending_state_allows_deep_dream_entry",
	"ending_state_allows_throne_entry", "outer_god_resonance"
]

var panel: PanelContainer
var map_picker: OptionButton
var status_label: Label
var exploration_label: Label
var mode_button: Button
var natural_start_button: Button
var full_sight_button: Button
var all_routes_button: Button
var teleport_button: Button
var restore_button: Button
var guide_label: Label
var guide_step_index := 0
var guide_prev_button: Button
var guide_next_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_update_guide()
	visible = false

func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(260, 24)
	panel.size = Vector2(820, 672)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "地图测试模式"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var warning := Label.new()
	warning.text = "仅用于地图验收。开启后不会写入或覆盖正式存档；关闭游戏前可恢复磁盘存档。"
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(warning)

	mode_button = _make_button("1. 开启地图测试模式（保护正式存档）")
	mode_button.pressed.connect(_enable_test_mode)
	column.add_child(mode_button)

	natural_start_button = _make_button("自然探索验收：从 A0 开始（无传送／无作弊解锁）")
	natural_start_button.pressed.connect(_start_natural_exploration)
	column.add_child(natural_start_button)

	var map_label := Label.new()
	map_label.text = "选择要直接进入的区域："
	column.add_child(map_label)

	map_picker = OptionButton.new()
	map_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in MAPS:
		map_picker.add_item(str(entry["label"]))
	column.add_child(map_picker)

	teleport_button = _make_button("进入所选区域")
	teleport_button.pressed.connect(_teleport_to_selected_map)
	column.add_child(teleport_button)

	full_sight_button = _make_button("2. 灵视条件测试：鸣响与接触值拉满（不自动开门）")
	full_sight_button.pressed.connect(_apply_full_sight_profile)
	column.add_child(full_sight_button)

	all_routes_button = _make_button("3. 全地图连通测试：开启隐藏门与捷径")
	all_routes_button.pressed.connect(_apply_all_routes_profile)
	column.add_child(all_routes_button)

	restore_button = _make_button("退出测试并恢复磁盘存档")
	restore_button.pressed.connect(_restore_disk_save)
	column.add_child(restore_button)

	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.custom_minimum_size = Vector2(0, 116)
	column.add_child(guide_label)

	var guide_buttons := HBoxContainer.new()
	guide_buttons.add_theme_constant_override("separation", 8)
	column.add_child(guide_buttons)
	guide_prev_button = _make_button("上一步指引")
	guide_prev_button.pressed.connect(_previous_guide_step)
	guide_buttons.add_child(guide_prev_button)
	guide_next_button = _make_button("下一步指引")
	guide_next_button.pressed.connect(_next_guide_step)
	guide_buttons.add_child(guide_next_button)

	exploration_label = Label.new()
	exploration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exploration_label.text = "自然探索记录：未启动"
	column.add_child(exploration_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "F10：打开／关闭本面板。自然探索会重置当前内存进度并从 A0 开始，但不删除或覆盖磁盘正式存档。"
	column.add_child(status_label)

	var controls := Label.new()
	controls.text = "地图验收：A／D 移动；V 激活灵视；E 调查／开门；F3 调试信息；F10 本面板。"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(controls)

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _update_guide() -> void:
	if guide_label == null:
		return
	guide_step_index = clampi(guide_step_index, 0, GUIDE_STEPS.size() - 1)
	var step: Dictionary = GUIDE_STEPS[guide_step_index]
	var current_scene_path := ""
	if get_tree().current_scene != null:
		current_scene_path = str(get_tree().current_scene.scene_file_path)
	var current_region := "未知"
	for entry in MAPS:
		if str(entry["scene"]) == current_scene_path:
			current_region = str(entry["label"]).split("｜")[0]
			break
	var target := str(step["region"])
	var location_note := "当前位置：%s" % current_region
	if target != "ALL" and current_region != target:
		location_note += "；本步目标区域：%s" % target
	else:
		location_note += "；本步目标位于当前区域或为全图检查"
	var direction_note := _get_navigation_hint(current_region, target)
	guide_label.text = "自然探索路线指引（仅提示，不传送／不解锁）\\n%s\\n%s\\n%s\\n%s" % [
		str(step["title"]), str(step["text"]), location_note, direction_note
	]
	guide_prev_button.disabled = guide_step_index <= 0
	guide_next_button.text = "下一步指引" if guide_step_index < GUIDE_STEPS.size() - 1 else "已到最后一步"

func _get_navigation_hint(current_region: String, target_region: String) -> String:
	var scene := get_tree().current_scene
	var hero := scene.get_node_or_null("Hero") if scene != null else null
	var hero_x := float(hero.position.x) if hero is Node2D else -1.0
	var candidates: Array = []
	if STEP_OBJECTIVE_POINTS.has(guide_step_index):
		var step_point: Dictionary = STEP_OBJECTIVE_POINTS[guide_step_index]
		if str(step_point["region"]) == current_region:
			return _format_direction(hero_x, float(step_point["x"]), str(step_point["name"]), str(step_point["condition"]))
	if target_region == current_region:
		candidates = OBJECTIVE_POINTS.get(current_region, [])
		if not candidates.is_empty() and hero_x >= 0.0:
			var nearest: Dictionary = candidates[0]
			var nearest_distance := absf(float(nearest["x"]) - hero_x)
			for candidate in candidates:
				var distance := absf(float(candidate["x"]) - hero_x)
				if distance < nearest_distance:
					nearest = candidate
					nearest_distance = distance
			var clue_name := str(nearest["name"])
			return _format_direction(hero_x, float(nearest["x"]), clue_name, "")
	var exits: Array = EXIT_HINTS.get(current_region, [])
	for exit_info in exits:
		if str(exit_info["target"]) == target_region:
			candidates.append(exit_info)
	if candidates.is_empty():
		for exit_info in exits:
			if str(exit_info["target"]) in ["A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A11", "A12"]:
				candidates.append(exit_info)
				break
	if candidates.is_empty():
		return "方向提示：当前区域没有已配置的坐标提示；按 F10 查看本步目标，并寻找带 E 提示的真实出口。"
	var chosen: Dictionary = candidates[0]
	if hero_x >= 0.0:
		var best_distance := absf(float(chosen["x"]) - hero_x)
		for candidate in candidates:
			var distance := absf(float(candidate["x"]) - hero_x)
			if distance < best_distance:
				chosen = candidate
				best_distance = distance
	var condition := str(chosen.get("condition", ""))
	return _format_direction(hero_x, float(chosen["x"]), str(chosen["name"]), condition)

func _format_direction(hero_x: float, destination_x: float, destination_name: String, condition: String) -> String:
	var direction := "未知方向"
	var distance_text := ""
	if hero_x >= 0.0:
		var delta_x := destination_x - hero_x
		if absf(delta_x) < 90.0:
			direction = "就在附近，微调位置并按 E"
		elif delta_x > 0.0:
			direction = "向右走（D）"
		else:
			direction = "向左走（A）"
		distance_text = "；距离约 %d 像素" % int(absf(delta_x))
	var result := "实际导航：%s，目标「%s」（地图坐标 x≈%d%s）" % [direction, destination_name, int(destination_x), distance_text]
	if not condition.is_empty():
		result += "；条件：%s" % condition
	return result

func _previous_guide_step() -> void:
	guide_step_index = maxi(0, guide_step_index - 1)
	_update_guide()

func _next_guide_step() -> void:
	guide_step_index = mini(GUIDE_STEPS.size() - 1, guide_step_index + 1)
	_update_guide()

func _process(_delta: float) -> void:
	if exploration_label == null:
		return
	_update_guide()
	if not WorldState.debug_natural_test_active:
		exploration_label.text = "自然探索记录：未启动"
		return
	var visited := " → ".join(PackedStringArray(WorldState.debug_natural_test_visited_regions))
	exploration_label.text = "自然探索实走地图：%d/22\n%s" % [
		WorldState.debug_natural_test_visited_regions.size(),
		visited if not visited.is_empty() else "尚未抵达地图区域"
	]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		visible = not visible
		get_viewport().set_input_as_handled()

func _ensure_test_mode() -> void:
	if WorldState.debug_map_test_mode:
		return
	WorldState.debug_map_test_mode = true
	status_label.text = "地图测试模式已开启：正式存档写入已暂停。地图测试不会额外生成调试平台或敌人。"

func _enable_test_mode() -> void:
	_ensure_test_mode()
	status_label.text = "已开启地图测试模式。正式存档不会被调试状态覆盖；可直接选择区域传送。"

func _start_natural_exploration() -> void:
	# Reset only the in-memory WorldState. Enable save protection again before loading A0.
	# 只重置内存中的游戏状态；进入 A0 前重新开启存档保护，绝不删除或覆盖正式存档。
	WorldState.reset()
	WorldState.begin_natural_test_session()
	WorldState.debug_ability_override_active = false
	WorldState.pending_region_spawn_side = "west"
	WorldState.resume_spawn_side = "west"
	guide_step_index = 0
	_update_guide()
	status_label.text = "自然探索已启动：从 A0 正常开始；未解锁灵视、未开放隐藏门、未启用传送。正式存档写入保持关闭。全程不要使用区域传送或状态预设。"
	print("[NEREIS][MAP][NATURAL_TEST] Started clean in-memory run from A0; disk save protected.")
	SceneTransition.fade_to_scene("res://scenes/escape_prologue.tscn")

func _teleport_to_selected_map() -> void:
	_ensure_test_mode()
	var index := clampi(map_picker.selected, 0, MAPS.size() - 1)
	var scene_path := str(MAPS[index]["scene"])
	if not ResourceLoader.exists(scene_path):
		status_label.text = "目标场景不存在：" + scene_path
		return
	WorldState.pending_region_spawn_side = "west"
	status_label.text = "正在进入：" + str(MAPS[index]["label"])
	SceneTransition.fade_to_scene(scene_path)

func _apply_full_sight_profile() -> void:
	_ensure_test_mode()
	WorldState.hero_resonance = 100
	WorldState.ancient_exposure = 100
	WorldState.outer_exposure = 100
	WorldState.outer_god_resonance = true
	WorldState.ancient_residue_awakened = true
	WorldState.set_resonance_sight_active(false)
	for anomaly_id in ALL_ANOMALIES:
		if anomaly_id not in WorldState.resonance_sources:
			WorldState.resonance_sources.append(anomaly_id)
	for flag in PROGRESSION_FLAGS:
		if flag not in WorldState.achievement_flags:
			WorldState.achievement_flags.append(flag)
	if "resonance_sight" not in WorldState.unlocked_abilities:
		WorldState.unlocked_abilities["resonance_sight"] = {"source_type": "debug", "source_id": "map_test"}
	WorldState.refresh_resonance_reveals(false)
	status_label.text = "灵视测试条件已设置：鸣响／古神接触／外神接触均为 100，已补齐常见异常来源与主线到达标记；隐藏门仍需按 E 开启。"

func _apply_all_routes_profile() -> void:
	_apply_full_sight_profile()
	for path_id in ALL_PATH_IDS:
		if path_id not in WorldState.opened_hidden_paths:
			WorldState.opened_hidden_paths.append(path_id)
	for hidden_id in ["H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09", "A11"]:
		if hidden_id not in WorldState.discovered_hidden_regions:
			WorldState.discovered_hidden_regions.append(hidden_id)
		if hidden_id not in WorldState.entered_hidden_regions:
			WorldState.entered_hidden_regions.append(hidden_id)
	status_label.text = "全地图连通测试条件已设置：常见隐藏门状态已开放。请逐条实际走过入口、回程与捷径；本预设不代表这些路线已经通过验收。"

func _restore_disk_save() -> void:
	WorldState.debug_map_test_mode = false
	WorldState.debug_natural_test_active = false
	WorldState.debug_natural_test_visited_regions.clear()
	guide_step_index = 0
	WorldState.debug_ability_override_active = false
	WorldState.load_game()
	WorldState.prepare_scene_runtime()
	get_tree().change_scene_to_file("res://scenes/boot.tscn")
	visible = false
