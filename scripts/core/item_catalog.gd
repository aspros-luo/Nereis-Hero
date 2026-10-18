extends RefCounted

const ITEMS: Dictionary = {
    "church_bandage": {
        "item_id": "church_bandage",
        "display_name": "染血的绷带",
        "category": "consumable",
        "description": "一卷被血浸透的绷带。布料边缘残留着难以洗净的黑色污迹。它仍可用于包扎，但污迹的来源无法仅凭外观判断。",
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
    }
}

static func has_item(item_id: String) -> bool:
    return ITEMS.has(item_id)

static func get_definition(item_id: String) -> Dictionary:
    if not ITEMS.has(item_id):
        return {}
    return ITEMS[item_id].duplicate(true)
