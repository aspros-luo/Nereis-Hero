extends RefCounted

const ITEMS: Dictionary = {
    "protagonist_long_sword": {
        "item_id": "protagonist_long_sword",
        "display_name": "长剑",
        "category": "weapon",
        "description": "一柄还算顺手的长剑，剑锋上还有未干涸的血渍，剑柄上有个相当模糊的符号，被随意的扔在地上。",
        "stackable": false,
        "max_stack": 1
    },
    "protagonist_short_blade": {
        "item_id": "protagonist_short_blade",
        "display_name": "短刃",
        "category": "weapon",
        "description": "一柄短刃。",
        "stackable": false,
        "max_stack": 1
    },
    "church_bandage": {
        "item_id": "church_bandage",
        "display_name": "染血的绷带",
        "category": "consumable",
        "description": "一卷被血浸透的绷带。布料边缘残留着难以洗净的黑色污迹。污迹的来源无法仅凭外观判断。",
        "stackable": true,
        "max_stack": 5
    },
    "surgery_record_fragment": {
        "item_id": "surgery_record_fragment",
        "display_name": "手术记录残页",
        "category": "lore",
        "description": "纸页上只剩几行尚能辨认的记录：\n\n“受试者仍保有战斗本能。”\n\n其余文字被撕去，纸边沾着暗色污渍。记录没有写明受试者的姓名。",
        "stackable": false,
        "max_stack": 1
    },
    "bell_tower_winch_key": {
        "item_id": "bell_tower_winch_key",
        "display_name": "钟塔绞盘钥匙",
        "category": "key_item",
        "description": "沉重的铁钥匙，齿口沾着新鲜润滑脂。它不适配普通门锁；齿形与钟塔落差口旁的旧绞盘锁相合。",
        "stackable": false,
        "max_stack": 1
    },
    "charred_church_seal": {
        "item_id": "charred_church_seal",
        "display_name": "烧黑的教会封条",
        "category": "lore",
        "description": "薄铜片上的教会印记已经烧黑。反面刻着一串编号，末尾的符号与林中路标上的刻痕相同。",
        "stackable": false,
        "max_stack": 1
    },
    "old_pilgrim_waybill": {
        "item_id": "old_pilgrim_waybill",
        "display_name": "旧朝圣路程单",
        "category": "lore",
        "description": "一张被雨水浸硬的路程单。标注的钟楼与林中石碑都仍在原处，但路线终点被反复涂改；最后留下的方向，指向一条从未出现在村庄地图上的高路。",
        "stackable": false,
        "max_stack": 1
    },
    "third_street_survey": {
        "item_id": "third_street_survey",
        "display_name": "第三街测绘残页",
        "category": "lore",
        "description": "测绘线条显示第三街曾与两条主街相接。纸张背面却只有两组门牌编号；被撕去的部分留下三道相互平行的压痕。",
        "stackable": false,
        "max_stack": 1
    },
    "royal_mortuary_register": {
        "item_id": "royal_mortuary_register",
        "display_name": "王室墓葬登记册",
        "category": "lore",
        "description": "登记册列出了数代王室成员的安葬日期。几处姓名被刀刃刮去，刮痕却晚于墓穴封闭记录；纸页仍保留着被压在下方的笔画。",
        "stackable": false,
        "max_stack": 1
    },
    "bellgrave_burial_token": {
        "item_id": "bellgrave_burial_token",
        "display_name": "钟墓守路人的骨牌",
        "category": "lore",
        "description": "一枚磨平的骨牌，边缘刻着两条互相交错的道路。一条指向钟墓坑底，另一条指向树冠高路；两条线在地图上本不应相交。",
        "stackable": false,
        "max_stack": 1
    },
    "canopy_waymarker_fragment": {
        "item_id": "canopy_waymarker_fragment",
        "display_name": "树冠路标残片",
        "category": "lore",
        "description": "残片背面留有一串旧路标编号。编号从林地地面一路延伸到高处，最后几笔却被刻意刮去，像是有人不愿让后来者知道高路的终点。",
        "stackable": false,
        "max_stack": 1
    }
}

static func has_item(item_id: String) -> bool:
    return ITEMS.has(item_id)

static func get_definition(item_id: String) -> Dictionary:
    if not ITEMS.has(item_id):
        return {}
    return ITEMS[item_id].duplicate(true)
