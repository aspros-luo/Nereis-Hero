extends RefCounted
class_name NereisLocalization

const LANGUAGES := ["zh_cn", "zh_tw", "en", "ja"]

const LANGUAGE_NAMES := {
    "zh_cn": "简体中文",
    "zh_tw": "繁體中文",
    "en": "English",
    "ja": "日本語"
}

const TEXT := {
    "zh_cn": {
        "menu.title": "蜜忒之歌：Nereis Hero",
        "menu.continue": "继续",
        "menu.new_game": "新游戏",
        "menu.save": "存档",
        "menu.resume": "继续游戏",
        "menu.language": "语言",
        "menu.return_title": "返回标题",
        "menu.back": "返回",
        "menu.confirm_new_game": "确定要开始新游戏吗？当前存档将被删除。",
        "menu.confirm": "确定",
        "menu.cancel": "取消",
        "menu.saved": "已保存",
        "menu.paused": "游戏暂停",
        "menu.select_language": "选择语言",
        "menu.no_save": "没有可继续的存档，将从序章开始。",
        "hud.title": "蜜忒之歌：NEREIS HERO",
        "hud.controls": "A/D 移动    SPACE 跳跃    J 攻击    K 闪避    ESC 菜单",
        "hud.hp": "生命",
        "hud.sta": "体力",
        "hud.hum": "人性",
        "narrative.skip": "E / SPACE / ENTER / 鼠标左键：继续",
        "region.village": "偏远村庄",
        "objective.village": "调查村庄为何救下了你",
        "region.mite_house": "蜜忒的房间",
        "objective.mite_house": "再留一会儿",
        "region.graveyard": "村庄墓地",
        "region.rebel_camp": "复国军营地",
        "region.ancient_lab": "远古研究病房",
        "menu.new_game_started": "新的旅程开始了。"
    },
    "zh_tw": {
        "menu.title": "蜜忒之歌：Nereis Hero",
        "menu.continue": "繼續",
        "menu.new_game": "新遊戲",
        "menu.save": "存檔",
        "menu.resume": "繼續遊戲",
        "menu.language": "語言",
        "menu.return_title": "返回標題",
        "menu.back": "返回",
        "menu.confirm_new_game": "確定要開始新遊戲嗎？目前存檔將被刪除。",
        "menu.confirm": "確定",
        "menu.cancel": "取消",
        "menu.saved": "已儲存",
        "menu.paused": "遊戲暫停",
        "menu.select_language": "選擇語言",
        "menu.no_save": "沒有可繼續的存檔，將從序章開始。",
        "hud.title": "蜜忒之歌：NEREIS HERO",
        "hud.controls": "A/D 移動    SPACE 跳躍    J 攻擊    K 閃避    ESC 選單",
        "hud.hp": "生命",
        "hud.sta": "體力",
        "hud.hum": "人性",
        "narrative.skip": "E / SPACE / ENTER / 滑鼠左鍵：繼續",
        "region.village": "偏遠村莊",
        "objective.village": "調查村莊為何救下了你",
        "region.mite_house": "蜜忒的房間",
        "objective.mite_house": "再留一會兒",
        "region.graveyard": "村莊墓地",
        "region.rebel_camp": "復國軍營地",
        "region.ancient_lab": "遠古研究病房",
        "menu.new_game_started": "新的旅程開始了。"
    },
    "en": {
        "menu.title": "Nereis Lullaby: Nereis Hero",
        "menu.continue": "Continue",
        "menu.new_game": "New Game",
        "menu.save": "Save",
        "menu.resume": "Resume",
        "menu.language": "Language",
        "menu.return_title": "Return to Title",
        "menu.back": "Back",
        "menu.confirm_new_game": "Start a new game? Your current save will be deleted.",
        "menu.confirm": "Confirm",
        "menu.cancel": "Cancel",
        "menu.saved": "Saved",
        "menu.paused": "Game Paused",
        "menu.select_language": "Language",
        "menu.no_save": "No save to continue. The prologue will begin.",
        "hud.title": "NEREIS HERO",
        "hud.controls": "A/D MOVE    SPACE JUMP    J ATTACK    K DODGE    ESC MENU",
        "hud.hp": "HP",
        "hud.sta": "STA",
        "hud.hum": "HUM",
        "narrative.skip": "E / SPACE / ENTER / LEFT CLICK: CONTINUE",
        "region.village": "THE REMOTE VILLAGE",
        "objective.village": "LEARN WHY THE VILLAGE SAVED YOU",
        "region.mite_house": "MITE'S HOUSE",
        "objective.mite_house": "STAY A LITTLE LONGER",
        "region.graveyard": "VILLAGE GRAVEYARD",
        "region.rebel_camp": "THE RESTORATION CAMP",
        "region.ancient_lab": "ANCIENT RESEARCH WARD",
        "menu.new_game_started": "A new journey begins."
    },
    "ja": {
        "menu.title": "ミーテの子守歌：Nereis Hero",
        "menu.continue": "続きから",
        "menu.new_game": "ニューゲーム",
        "menu.save": "セーブ",
        "menu.resume": "ゲームに戻る",
        "menu.language": "言語",
        "menu.return_title": "タイトルへ戻る",
        "menu.back": "戻る",
        "menu.confirm_new_game": "新しいゲームを始めますか？現在のセーブデータは削除されます。",
        "menu.confirm": "決定",
        "menu.cancel": "キャンセル",
        "menu.saved": "保存しました",
        "menu.paused": "ゲーム一時停止",
        "menu.select_language": "言語を選択",
        "menu.no_save": "続きから使えるセーブがありません。序章から始まります。",
        "hud.title": "ミーテの子守歌：NEREIS HERO",
        "hud.controls": "A/D 移動    SPACE ジャンプ    J 攻撃    K 回避    ESC メニュー",
        "hud.hp": "HP",
        "hud.sta": "ST",
        "hud.hum": "人間性",
        "narrative.skip": "E / SPACE / ENTER / 左クリック：進む",
        "region.village": "辺境の村",
        "objective.village": "なぜ村があなたを救ったのか調べる",
        "region.mite_house": "ミーテの家",
        "objective.mite_house": "もう少しここにいる",
        "region.graveyard": "村の墓地",
        "region.rebel_camp": "王国復興軍の野営地",
        "region.ancient_lab": "古代研究病棟",
        "menu.new_game_started": "新しい旅が始まる。"
    }
}

static func t(key: String) -> String:
    var language: String = str(WorldState.language)
    if not TEXT.has(language):
        language = "zh_cn"
    var table: Dictionary = TEXT[language]
    if table.has(key):
        return str(table[key])
    return key

static func language_name(language: String) -> String:
    return str(LANGUAGE_NAMES.get(language, language))

static func all_language_names() -> Array[String]:
    var result: Array[String] = []
    for language in LANGUAGES:
        result.append(language_name(language))
    return result

static func language_index(language: String) -> int:
    return maxi(0, LANGUAGES.find(language))

static func next_language() -> String:
    var index := language_index(str(WorldState.language))
    return LANGUAGES[(index + 1) % LANGUAGES.size()]

static func key_for_region(value: String) -> String:
    match value:
        "THE REMOTE VILLAGE":
            return "region.village"
        "MITE'S HOUSE":
            return "region.mite_house"
        "VILLAGE GRAVEYARD":
            return "region.graveyard"
        "THE RESTORATION CAMP":
            return "region.rebel_camp"
        "ANCIENT RESEARCH WARD":
            return "region.ancient_lab"
        _:
            return ""

static func key_for_objective(value: String) -> String:
    match value:
        "LEARN WHY THE VILLAGE SAVED YOU":
            return "objective.village"
        "STAY A LITTLE LONGER":
            return "objective.mite_house"
        _:
            return ""
