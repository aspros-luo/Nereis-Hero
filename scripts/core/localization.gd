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

const SOURCE_TRANSLATIONS := {
    "MITE": {
        "zh_cn": "蜜忒",
        "zh_tw": "蜜忒",
        "ja": "ミーテ"
    },
    "OLD HUNTER": {
        "zh_cn": "老猎人",
        "zh_tw": "老獵人",
        "ja": "老狩人"
    },
    "THE PATH OPENS": {
        "zh_cn": "道路开启",
        "zh_tw": "道路開啟",
        "ja": "道が開く"
    },
    "THE ROAD AWAITS": {
        "zh_cn": "道路在等待",
        "zh_tw": "道路在等待",
        "ja": "道が待っている"
    },
    "THE ASHEN KNIGHT": {
        "zh_cn": "灰烬骑士",
        "zh_tw": "灰燼騎士",
        "ja": "灰の騎士"
    },
    "A BETTER GRIP": {
        "zh_cn": "更好的握剑姿势",
        "zh_tw": "更好的握劍姿勢",
        "ja": "より良い握り"
    },
    "A MEMORY THAT DOES NOT FEEL LIKE YOURS": {
        "zh_cn": "一段不属于你的记忆",
        "zh_tw": "一段不屬於你的記憶",
        "ja": "自分のものではない記憶"
    },
    "THE ROAD REMEMBERS YOU": {
        "zh_cn": "道路记得你",
        "zh_tw": "道路記得你",
        "ja": "道は君を覚えている"
    },
    "THE CHURCH SEAL": {
        "zh_cn": "教会印记",
        "zh_tw": "教會印記",
        "ja": "教会の印"
    },
    "THE LULLABY": {
        "zh_cn": "摇篮曲",
        "zh_tw": "搖籃曲",
        "ja": "子守歌"
    },
    "AN EMPTY CHAIR": {
        "zh_cn": "一张空椅子",
        "zh_tw": "一張空椅子",
        "ja": "空の椅子"
    },
    "THE LOCKED DOOR": {
        "zh_cn": "上锁的门",
        "zh_tw": "上鎖的門",
        "ja": "鍵のかかった扉"
    },
    "THE CLOSED DOOR": {
        "zh_cn": "紧闭的门",
        "zh_tw": "緊閉的門",
        "ja": "閉ざされた扉"
    },
    "THE TAVERN": {
        "zh_cn": "酒馆",
        "zh_tw": "酒館",
        "ja": "酒場"
    },
    "THE CHURCH": {
        "zh_cn": "教会",
        "zh_tw": "教會",
        "ja": "教会"
    },
    "BACK TO THE VILLAGE": {
        "zh_cn": "回到村庄",
        "zh_tw": "回到村莊",
        "ja": "村へ戻る"
    },
    "THE ARCHIVES": {
        "zh_cn": "档案室",
        "zh_tw": "檔案室",
        "ja": "書庫"
    },
    "THE BACK ROAD": {
        "zh_cn": "后路",
        "zh_tw": "後路",
        "ja": "裏道"
    },
    "THE LOCKED STAIR": {
        "zh_cn": "上锁的阶梯",
        "zh_tw": "上鎖的階梯",
        "ja": "閉ざされた階段"
    },
    "THE EMPTY TABLE": {
        "zh_cn": "空桌",
        "zh_tw": "空桌",
        "ja": "空のテーブル"
    },
    "A MOMENT OF QUIET": {
        "zh_cn": "片刻宁静",
        "zh_tw": "片刻寧靜",
        "ja": "静かなひととき"
    },
    "THE LAST ROOM": {
        "zh_cn": "最后的房间",
        "zh_tw": "最後的房間",
        "ja": "最後の部屋"
    },
    "THE LAST PRAYER": {
        "zh_cn": "最后的祈祷",
        "zh_tw": "最後的祈禱",
        "ja": "最後の祈り"
    },
    "THE LAST CROWN": {
        "zh_cn": "最后的王冠",
        "zh_tw": "最後的王冠",
        "ja": "最後の王冠"
    },
    "NO MORE KINGDOMS": {
        "zh_cn": "不再有王国",
        "zh_tw": "不再有王國",
        "ja": "もう王国はない"
    },
    "NO MORE DISTANCE": {
        "zh_cn": "不再有距离",
        "zh_tw": "不再有距離",
        "ja": "もう距離はない"
    },
    "ETERNAL PARADISE": {
        "zh_cn": "永恒乐园",
        "zh_tw": "永恆樂園",
        "ja": "永遠の楽園"
    },
    "THE RESONANCE": {
        "zh_cn": "共鸣",
        "zh_tw": "共鳴",
        "ja": "共鳴"
    },
    "THE VESSEL": {
        "zh_cn": "容器",
        "zh_tw": "容器",
        "ja": "器"
    },
    "THE RESEARCH WARD": {
        "zh_cn": "研究病房",
        "zh_tw": "研究病房",
        "ja": "研究病棟"
    },
    "THE CHURCH BREAKS": {
        "zh_cn": "教会崩塌",
        "zh_tw": "教會崩塌",
        "ja": "教会が崩れる"
    },
    "FALSE FAITH": {
        "zh_cn": "虚假的信仰",
        "zh_tw": "虛假的信仰",
        "ja": "偽りの信仰"
    },
    "THE KING'S BURDEN": {
        "zh_cn": "国王的重负",
        "zh_tw": "國王的重負",
        "ja": "王の重荷"
    },
    "NO KINGDOM": {
        "zh_cn": "没有王国",
        "zh_tw": "沒有王國",
        "ja": "王国はない"
    },
    "THE LAST CHURCH": {
        "zh_cn": "最后的教会",
        "zh_tw": "最後的教會",
        "ja": "最後の教会"
    },
    "DIRECTOR TEST COMPLETE": {
        "zh_cn": "导演测试完成",
        "zh_tw": "導演測試完成",
        "ja": "ディレクターテスト完了"
    },
    "THE CITY IS ALREADY DEAD": {
        "zh_cn": "这座城市已经死去",
        "zh_tw": "這座城市已經死去",
        "ja": "この街はもう死んでいる"
    },
    "烈火天罚": {
        "zh_cn": "烈火天罚",
        "zh_tw": "烈火天罰",
        "ja": "烈火の天罰"
    },
    "THE VILLAGE": {
        "zh_cn": "村庄",
        "zh_tw": "村莊",
        "ja": "村"
    },
    "THE VILLAGE GRAVEYARD": {
        "zh_cn": "村庄墓地",
        "zh_tw": "村莊墓地",
        "ja": "村の墓地"
    },
    "THE BELL": {
        "zh_cn": "钟",
        "zh_tw": "鐘",
        "ja": "鐘"
    },
    "THE SILENT BELL": {
        "zh_cn": "寂静之钟",
        "zh_tw": "寂靜之鐘",
        "ja": "静かな鐘"
    },
    "THE VILLAGE LIGHTS": {
        "zh_cn": "村庄的灯火",
        "zh_tw": "村莊的燈火",
        "ja": "村の灯り"
    },
    "THE OLD CHURCH": {
        "zh_cn": "旧教会",
        "zh_tw": "舊教會",
        "ja": "古い教会"
    },
    "THE LULLABY PATH": {
        "zh_cn": "摇篮曲之路",
        "zh_tw": "搖籃曲之路",
        "ja": "子守歌の道"
    },
    "THE CHURCH ROAD": {
        "zh_cn": "教会之路",
        "zh_tw": "教會之路",
        "ja": "教会への道"
    },
    "THE ATTACK": {
        "zh_cn": "袭击",
        "zh_tw": "襲擊",
        "ja": "襲撃"
    },
    "THE FIRST WAVE": {
        "zh_cn": "第一波",
        "zh_tw": "第一波",
        "ja": "第一波"
    },
    "THE SECOND WAVE": {
        "zh_cn": "第二波",
        "zh_tw": "第二波",
        "ja": "第二波"
    },
    "AFTER THE FIRE": {
        "zh_cn": "火焰之后",
        "zh_tw": "火焰之後",
        "ja": "火の後"
    },
    "THE VILLAGE FALLS QUIET": {
        "zh_cn": "村庄归于寂静",
        "zh_tw": "村莊歸於寂靜",
        "ja": "村が静まり返る"
    },
    "THE RESTORATION CAMP": {
        "zh_cn": "复国军营地",
        "zh_tw": "復國軍營地",
        "ja": "王国復興軍の野営地"
    },
    "NO KING / NO CHURCH": {
        "zh_cn": "没有国王 / 没有教会",
        "zh_tw": "沒有國王 / 沒有教會",
        "ja": "王なし / 教会なし"
    },
    "THE QUIET HOUSE": {
        "zh_cn": "寂静的房间",
        "zh_tw": "寂靜的房間",
        "ja": "静かな家"
    },
    "A NIGHT WITHOUT A NAME": {
        "zh_cn": "无名之夜",
        "zh_tw": "無名之夜",
        "ja": "名もなき夜"
    },
    "THE ROOM REMEMBERS": {
        "zh_cn": "房间记得",
        "zh_tw": "房間記得",
        "ja": "部屋は覚えている"
    },
    "THE SURGICAL WARD": {
        "zh_cn": "外科病房",
        "zh_tw": "外科病房",
        "ja": "手術病棟"
    },
    "THE ROAD OUT": {
        "zh_cn": "出口之路",
        "zh_tw": "出口之路",
        "ja": "外へ続く道"
    },
    "SURGICAL WARD": {
        "zh_cn": "外科病房",
        "zh_tw": "外科病房",
        "ja": "手術病棟"
    },
    "THE ROAD": {
        "zh_cn": "道路",
        "zh_tw": "道路",
        "ja": "道"
    },
    "THE ASHEN ROAD": {
        "zh_cn": "灰烬之路",
        "zh_tw": "灰燼之路",
        "ja": "灰の道"
    },
    "VILLAGE OUTSKIRTS": {
        "zh_cn": "村庄郊外",
        "zh_tw": "村莊郊外",
        "ja": "村の外れ"
    },
    "ASH GATE": {
        "zh_cn": "灰烬之门",
        "zh_tw": "灰燼之門",
        "ja": "灰の門"
    },
    "SAFE GROUND": {
        "zh_cn": "安全区域",
        "zh_tw": "安全區域",
        "ja": "安全地帯"
    },
    "CHECKPOINT": {
        "zh_cn": "检查点",
        "zh_tw": "檢查點",
        "ja": "チェックポイント"
    },
    "EXIT": {
        "zh_cn": "出口",
        "zh_tw": "出口",
        "ja": "出口"
    },
    "ROUTE END": {
        "zh_cn": "路线终点",
        "zh_tw": "路線終點",
        "ja": "ルート終点"
    },
    "ROUTE CHECKPOINT": {
        "zh_cn": "路线检查点",
        "zh_tw": "路線檢查點",
        "ja": "ルートのチェックポイント"
    },
    "E  Talk": {
        "zh_cn": "E  对话",
        "zh_tw": "E  對話",
        "ja": "E  話す"
    },
    "E  Speak": {
        "zh_cn": "E  交谈",
        "zh_tw": "E  交談",
        "ja": "E  話す"
    },
    "E  Examine": {
        "zh_cn": "E  调查",
        "zh_tw": "E  調查",
        "ja": "E  調べる"
    },
    "E  Enter": {
        "zh_cn": "E  进入",
        "zh_tw": "E  進入",
        "ja": "E  入る"
    },
    "F  Open Door": {
        "zh_cn": "F  开门",
        "zh_tw": "F  開門",
        "ja": "F  扉を開く"
    },
    "ASHEN KNIGHT %d": {
        "zh_cn": "灰烬骑士 %d",
        "zh_tw": "灰燼騎士 %d",
        "ja": "灰の騎士 %d"
    },
    "HERO %d": {
        "zh_cn": "英雄 %d",
        "zh_tw": "英雄 %d",
        "ja": "英雄 %d"
    },
    "BELL KEEPER": {
        "zh_cn": "守钟人",
        "zh_tw": "守鐘人",
        "ja": "鐘守"
    },
    "TAVERN HALL": {
        "zh_cn": "酒馆大厅",
        "zh_tw": "酒館大廳",
        "ja": "酒場ホール"
    },
    "CHURCH NAVE": {
        "zh_cn": "教堂中殿",
        "zh_tw": "教堂中殿",
        "ja": "教会の身廊"
    },
    "VILLAGE EXIT": {
        "zh_cn": "村庄出口",
        "zh_tw": "村莊出口",
        "ja": "村の出口"
    },
    "A ROOM WITH TWO PLACES": {
        "zh_cn": "容得下两个人的房间",
        "zh_tw": "容得下兩個人的房間",
        "ja": "二人の居場所がある部屋"
    },
    "THE WORLD FORGETS HOW TO HURT": {
        "zh_cn": "世界忘记了如何伤害",
        "zh_tw": "世界忘記了如何傷害",
        "ja": "世界は傷つけ方を忘れる"
    },
    "THE VILLAGE BURNS AT THE EDGES": {
        "zh_cn": "村庄边缘燃起火焰",
        "zh_tw": "村莊邊緣燃起火焰",
        "ja": "村の縁が燃え始める"
    },
    "BELL TOWER": {
        "zh_cn": "钟楼",
        "zh_tw": "鐘樓",
        "ja": "鐘楼"
    },
    "MITE'S HOUSE": {
        "zh_cn": "蜜忒的房间",
        "zh_tw": "蜜忒的房間",
        "ja": "ミーテの家"
    },
    "GRAVEYARD": {
        "zh_cn": "墓地",
        "zh_tw": "墓地",
        "ja": "墓地"
    },
    "RESTORATION CAMP": {
        "zh_cn": "复国军营地",
        "zh_tw": "復國軍營地",
        "ja": "王国復興軍の野営地"
    },
    "NORTH GATE": {
        "zh_cn": "北门",
        "zh_tw": "北門",
        "ja": "北門"
    },
    "CHURCH": {
        "zh_cn": "教会",
        "zh_tw": "教會",
        "ja": "教会"
    },
    "OPEN": {
        "zh_cn": "开启",
        "zh_tw": "開啟",
        "ja": "開く"
    },
    "ASHEN ARENA": {
        "zh_cn": "灰烬竞技场",
        "zh_tw": "灰燼競技場",
        "ja": "灰の闘技場"
    },
    "AWAKENING": {
        "zh_cn": "苏醒",
        "zh_tw": "甦醒",
        "ja": "覚醒"
    },
    "CORE COMBAT DEMO COMPLETE": {
        "zh_cn": "核心战斗演示完成",
        "zh_tw": "核心戰鬥演示完成",
        "ja": "コア戦闘デモ完了"
    },
    "The girl kneels beside the old wooden table.\n\n\"You're awake. Good.\"\n\nShe studies your bandaged hands, then looks at the sword.\n\n\"Were you always this quiet?\"\n\nThere is no fear in her voice. Only curiosity.": {
        "zh_cn": "女孩跪在旧木桌旁。\n\n“你醒了。很好。”\n\n她打量着你缠着绷带的双手，又看向那把剑。\n\n“你一直都这么安静吗？”\n\n她的声音里没有恐惧，只有好奇。",
        "zh_tw": "女孩跪在舊木桌旁。\n\n「你醒了。很好。」\n\n她打量著你纏著繃帶的雙手，又看向那把劍。\n\n「你一直都這麼安靜嗎？」\n\n她的聲音裡沒有恐懼，只有好奇。",
        "ja": "少女は古い木のテーブルのそばに跪く。\n\n「目が覚めた。よかった。」\n\n包帯を巻いたあなたの手、それから剣を見る。\n\n「ずっと、こんなに静かな人だったの？」\n\n声に恐怖はない。ただ好奇心だけがある。"
    },
    "She pushes a warm bowl toward you.\n\n\"Eat before you leave.\"\n\nA small pause.\n\n\"You can tell me later where you are going.\"\n\nShe says it as though there is no reason you should refuse.": {
        "zh_cn": "她把一碗热腾腾的食物推到你面前。\n\n“走之前先吃点。”\n\n她停了一下。\n\n“等你想说的时候，再告诉我你要去哪里。”\n\n她说得很自然，仿佛你没有理由拒绝。",
        "zh_tw": "她把一碗熱騰騰的食物推到你面前。\n\n「走之前先吃點。」\n\n她停了一下。\n\n「等你想說的時候，再告訴我你要去哪裡。」\n\n她說得很自然，彷彿你沒有理由拒絕。",
        "ja": "少女は温かな食事をあなたの前へ押し出す。\n\n「行く前に食べて。」\n\n少し間を置く。\n\n「どこへ行くのかは、あとで話して。」\n\n断る理由などないと言うように、自然な声だった。"
    },
    "Mite sits beside the doorway instead of looking at the road.\n\n\"You keep staring at the church path.\"\n\nShe looks at you.\n\n\"You don't have to go yet.\"\n\nShe pats the empty space beside her.": {
        "zh_cn": "蜜忒没有望向道路，而是坐在门边。\n\n“你一直盯着通往教会的路。”\n\n她看着你。\n\n“你还不用走。”\n\n她拍了拍身旁空着的位置。",
        "zh_tw": "蜜忒沒有望向道路，而是坐在門邊。\n\n「你一直盯著通往教會的路。」\n\n她看著你。\n\n「你還不用走。」\n\n她拍了拍身旁空著的位置。",
        "ja": "ミーテは道を見る代わりに、戸口のそばに座る。\n\n「ずっと教会への道を見てるね。」\n\n彼女はあなたを見る。\n\n「まだ行かなくてもいいよ。」\n\n隣の空いた場所を軽く叩いた。"
    },
    "The light is fading from the village.\n\n\"You came back.\"\n\nMite smiles, almost relieved.\n\n\"I thought you might forget the way.\"\n\nShe does not explain why that thought bothered her.": {
        "zh_cn": "村庄的灯火渐渐暗下。\n\n“你回来了。”\n\n蜜忒微笑着，像是终于松了口气。\n\n“我还以为你会忘记路。”\n\n她没有解释，为什么这件事会让她如此在意。",
        "zh_tw": "村莊的燈火漸漸暗下。\n\n「你回來了。」\n\n蜜忒微笑著，像是終於鬆了口氣。\n\n「我還以為你會忘記路。」\n\n她沒有解釋，為什麼這件事會讓她如此在意。",
        "ja": "村の灯が薄れていく。\n\n「帰ってきた。」\n\nミーテは、安堵したように微笑む。\n\n「道を忘れちゃうかと思った。」\n\nなぜそんなことが気になったのか、彼女は説明しなかった。"
    },
    "Mite pauses beside the window.\n\n\"Did you hear something in your sleep?\"\n\nShe smiles when you shake your head.\n\n\"I did.\"": {
        "zh_cn": "蜜忒在窗边停下。\n\n“你睡着的时候，有听见什么吗？”\n\n你摇头，她便笑了。\n\n“我听见了。”",
        "zh_tw": "蜜忒在窗邊停下。\n\n「你睡著的時候，有聽見什麼嗎？」\n\n你搖頭，她便笑了。\n\n「我聽見了。」",
        "ja": "ミーテは窓辺で足を止める。\n\n「眠っている間、何か聞こえた？」\n\nあなたが首を振ると、彼女は笑った。\n\n「私は聞こえたよ。」"
    },
    "She watches the fire for a long time.\n\n\"Do you think two people can have the same dream?\"\n\nShe asks as if the answer should be obvious.": {
        "zh_cn": "她长久地望着火焰。\n\n“你觉得两个人会做同一个梦吗？”\n\n她问得像是答案本来就显而易见。",
        "zh_tw": "她長久地望著火焰。\n\n「你覺得兩個人會做同一個夢嗎？」\n\n她問得像是答案本來就顯而易見。",
        "ja": "彼女は長い間、炎を見つめる。\n\n「二人が同じ夢を見ることって、あると思う？」\n\n答えは明らかだと言うように尋ねた。"
    },
    "Mite takes your hand.\n\n\"Don't go to the Church tonight.\"\n\nHer fingers tighten.\n\n\"I don't want you to leave me alone.\"": {
        "zh_cn": "蜜忒牵起你的手。\n\n“今晚别去教会。”\n\n她的手指收紧。\n\n“我不想再一个人。”",
        "zh_tw": "蜜忒牽起你的手。\n\n「今晚別去教會。」\n\n她的手指收緊。\n\n「我不想再一個人。」",
        "ja": "ミーテはあなたの手を取る。\n\n「今夜は教会へ行かないで。」\n\n指に力がこもる。\n\n「もう、一人になりたくない。」"
    },
    "The chair beside the fire is empty.\n\nA cup has been left on the table. It is still warm.\n\nNo one is home.": {
        "zh_cn": "火边的椅子空着。\n\n桌上留着一个杯子，还是温的。\n\n家里没有人。",
        "zh_tw": "火邊的椅子空著。\n\n桌上留著一個杯子，還是溫的。\n\n家裡沒有人。",
        "ja": "火のそばの椅子は空いている。\n\nテーブルには、まだ温かいカップが残されている。\n\n誰もいない。"
    },
    "The cup is still warm.\n\nYou are certain you did not leave it here.": {
        "zh_cn": "杯子仍然温热。\n\n你确定不是你把它留在这里的。",
        "zh_tw": "杯子仍然溫熱。\n\n你確定不是你把它留在這裡的。",
        "ja": "カップはまだ温かい。\n\nここへ置いたのは自分ではない。"
    },
    "The road ends where the village begins.\n\nThe Hero recognizes none of it. The village recognizes him.\n\nSomeone has left a place for him by the fire.": {
        "zh_cn": "道路在村庄开始的地方终止。\n\n英雄什么都不认识，但村庄认识他。\n\n有人在火边为他留下了一个位置。",
        "zh_tw": "道路在村莊開始的地方終止。\n\n英雄什麼都不認識，但村莊認識他。\n\n有人在火邊為他留下了一個位置。",
        "ja": "道は村の始まりで途切れる。\n\n英雄は何も覚えていない。だが村は彼を知っている。\n\n誰かが、火のそばに彼の席を残していた。"
    },
    "The chair near the window is empty.\n\nSomeone has left a cup there anyway.": {
        "zh_cn": "窗边的椅子空着。\n\n可那里还是留下了一只杯子。",
        "zh_tw": "窗邊的椅子空著。\n\n可那裡還是留下了一只杯子。",
        "ja": "窓辺の椅子は空いている。\n\nそれでも、そこにはカップが置かれている。"
    },
    "The room is warmer than the road.\n\nSomewhere behind the bar, a glass is placed down by a hand you cannot see.": {
        "zh_cn": "房间比道路温暖。\n\n吧台后方，某只看不见的手放下了一只玻璃杯。",
        "zh_tw": "房間比道路溫暖。\n\n吧檯後方，某隻看不見的手放下了一只玻璃杯。",
        "ja": "部屋は道より暖かい。\n\nカウンターの奥で、見えない手がグラスを置く音がする。"
    },
    "Incense clings to the stone.\n\nThe Hero's footsteps are familiar to the room.": {
        "zh_cn": "焚香的气息粘在石墙上。\n\n英雄的脚步声，对这个房间而言并不陌生。",
        "zh_tw": "焚香的氣息黏在石牆上。\n\n英雄的腳步聲，對這個房間而言並不陌生。",
        "ja": "石に香の匂いが染みついている。\n\n英雄の足音は、この部屋にとって見慣れたものだった。"
    },
    "The room remains quiet.\n\nNothing follows you into sleep.": {
        "zh_cn": "房间依旧安静。\n\n没有任何东西跟着你进入梦乡。",
        "zh_tw": "房間依舊安靜。\n\n沒有任何東西跟著你進入夢鄉。",
        "ja": "部屋は静かなまま。\n\n眠りについてくるものは何もない。"
    },
    "Mite looks toward the empty half of the room.\n\n\"You should get some rest.\"": {
        "zh_cn": "蜜忒看向房间里空着的另一半。\n\n“你该休息了。”",
        "zh_tw": "蜜忒看向房間裡空著的另一半。\n\n「你該休息了。」",
        "ja": "ミーテは部屋の空いた半分を見る。\n\n「少し休んだほうがいいよ。」"
    },
    "The village has gone quiet.\n\nThere is nowhere either of you needs to be tonight.": {
        "zh_cn": "村庄已经安静下来。\n\n今晚，你们谁也没有必须前往的地方。",
        "zh_tw": "村莊已經安靜下來。\n\n今晚，你們誰也沒有必須前往的地方。",
        "ja": "村は静まり返っている。\n\n今夜、二人が向かわなければならない場所はどこにもない。"
    },
    "No voice speaks.\n\nOnly warmth beneath Hero's skin.\n\nMite opens her eyes.\n\n\"Did you hear that?\"": {
        "zh_cn": "没有声音说话。\n\n只有英雄皮肤之下传来一丝温热。\n\n蜜忒睁开眼睛。\n\n“你听见了吗？”",
        "zh_tw": "沒有聲音說話。\n\n只有英雄皮膚之下傳來一絲溫熱。\n\n蜜忒睜開眼睛。\n\n「你聽見了嗎？」",
        "ja": "声はない。\n\nただ、英雄の皮膚の下に熱がある。\n\nミーテが目を開く。\n\n「今の、聞こえた？」"
    },
    "The village is asleep.\n\nHero and Mite are alone in the room.\n\nNothing outside asks either of them to be a knight, a vessel or a god.": {
        "zh_cn": "村庄已经睡去。\n\n英雄和蜜忒独自在房间里。\n\n外面的世界暂时没有要求他们成为骑士、容器或神。",
        "zh_tw": "村莊已經睡去。\n\n英雄和蜜忒獨自在房間裡。\n\n外面的世界暫時沒有要求他們成為騎士、容器或神。",
        "ja": "村は眠っている。\n\n英雄とミーテだけが部屋にいる。\n\n外の世界は、二人に騎士や器や神であることを求めない。"
    },
    "There is no explosion.\n\nOnly a brief warmth beneath Hero's skin.\n\nMite opens her eyes.\n\nShe is smiling. She does not know why.": {
        "zh_cn": "没有爆炸。\n\n只有英雄皮肤之下短暂的一阵温暖。\n\n蜜忒睁开眼。\n\n她在微笑，却不知道为什么。",
        "zh_tw": "沒有爆炸。\n\n只有英雄皮膚之下短暫的一陣溫暖。\n\n蜜忒睜開眼。\n\n她在微笑，卻不知道為什麼。",
        "ja": "爆発はない。\n\nただ、英雄の皮膚の下に一瞬だけ温もりが走る。\n\nミーテが目を開く。\n\n微笑んでいる。なぜなのか、自分でも分からない。"
    },
    "\"I dreamed you were still here.\"\n\nA pause.\n\n\"We don't have to leave anymore, do we?\"": {
        "zh_cn": "“我梦见你还在这里。”\n\n她停了一下。\n\n“我们已经不用再离开了，对吧？”",
        "zh_tw": "「あなたがまだここにいる夢を見た。」\n\n少しの間。\n\n「もう、出ていかなくてもいいよね？」",
        "ja": "「まだここにいる夢を見た。」\n\n一拍置いて。\n\n「もう、出ていかなくてもいいんだよね？」"
    },
    "\"Outside feels very far away.\"\n\nShe looks toward Hero.\n\n\"I don't want to be alone again.\"": {
        "zh_cn": "“外面的世界感觉好远。”\n\n她望向英雄。\n\n“我不想再一个人了。”",
        "zh_tw": "「外面的世界感覺好遠。」\n\n她望向英雄。\n\n「我不想再一個人了。」",
        "ja": "「外の世界が、ずっと遠く感じる。」\n\n彼女は英雄を見る。\n\n「もう一人にはなりたくない。」"
    },
    "The thing collapses.\n\nBeneath its ribs, a metal hook remains embedded in bone.\n\nThe hook is shaped for something much larger than the body it came from.": {
        "zh_cn": "那东西倒下了。\n\n肋骨下面，一枚金属钩仍嵌在骨头里。\n\n那枚钩子的形状，原本属于远比这具身体更庞大的东西。",
        "zh_tw": "那東西倒下了。\n\n肋骨下面，一枚金屬鉤仍嵌在骨頭裡。\n\n那枚鉤子的形狀，原本屬於遠比這具身體更龐大的東西。",
        "ja": "それは崩れ落ちる。\n\n肋骨の奥には、金属の鉤が骨に食い込んでいる。\n\nその鉤は、この身体よりはるかに大きな何かのための形をしていた。"
    },
    "Black fluid vial\n\nWhen light crosses it, the color inside becomes red.": {
        "zh_cn": "液体并非真正的黑色。\n\n光穿过时，里面的颜色会变成红色。",
        "zh_tw": "液體並非真正的黑色。\n\n光穿過時，裡面的顏色會變成紅色。",
        "ja": "液体は完全な黒ではない。\n\n光が通ると、中の色は赤へ変わる。"
    },
    "Names are listed with dates, weights and survival percentages.\n\nOne line has been underlined in red:\n\n'Knight-class subjects demonstrate superior retention.'": {
        "zh_cn": "名字、日期、重量和存活率被逐一记录。\n\n其中一行被红笔划了线：\n\n“骑士级实验体表现出更强的留存能力。”",
        "zh_tw": "名字、日期、重量和存活率被逐一記錄。\n\n其中一行被紅筆劃了線：\n\n「騎士級實驗體表現出更強的留存能力。」",
        "ja": "名前、日付、体重、生存率が並んでいる。\n\n赤い線で一行だけ強調されていた。\n\n「騎士級被験体は優れた保持性を示す。」"
    },
    "The High Priest falls.\n\nThe flesh beneath the robes still twitches.\n\nThen the royal seal appears at the far end of the nave.": {
        "zh_cn": "大祭司倒下。\n\n长袍下面的血肉仍在抽搐。\n\n随后，王室印记出现在中殿尽头。",
        "zh_tw": "大祭司倒下。\n\n長袍下面的血肉仍在抽搐。\n\n隨後，王室印記出現在中殿盡頭。",
        "ja": "大神官が倒れる。\n\n法衣の下の肉はまだ痙攣している。\n\nそして身廊の奥に、王家の印が現れた。"
    },
    "The relics in the sanctuary begin to pulse.\n\nThe High Priest's prayers continue after his mouth has stopped moving.": {
        "zh_cn": "圣所中的遗物开始搏动。\n\n即使大祭司的嘴已经停止动作，他的祷告仍在继续。",
        "zh_tw": "聖所中的遺物開始搏動。\n\n即使大祭司的嘴已經停止動作，他的禱告仍在繼續。",
        "ja": "聖所の遺物が脈打ち始める。\n\n大神官の口が止まった後も、祈りだけが続いている。"
    },
    "The crown cracks.\n\nHe does not kneel.": {
        "zh_cn": "王冠裂开。\n\n他没有跪下。",
        "zh_tw": "王冠裂開。\n\n他沒有跪下。",
        "ja": "王冠がひび割れる。\n\n彼は跪かない。"
    },
    "The King falls.\n\nThe Church is defeated.\n\nThe Kingdom is not saved.": {
        "zh_cn": "国王倒下。\n\n教会被击败了。\n\n王国却没有得救。",
        "zh_tw": "國王倒下。\n\n教會被擊敗了。\n\n王國卻沒有得救。",
        "ja": "王が倒れる。\n\n教会は敗れた。\n\nだが王国は救われない。"
    },
    "The doors open.\n\n\"You think I did not know?\"\n\n\"I knew what they were doing. I knew what the Church had become.\nI only knew the alternative: the Kingdom falls.\"": {
        "zh_cn": "门打开了。\n\n“你以为我不知道？”\n\n“我知道他们做了什么。我知道教会已经变成什么样。\n我只知道另一种结果：王国会毁灭。”",
        "zh_tw": "門打開了。\n\n「你以為我不知道？」\n\n「我知道他們做了什麼。我知道教會已經變成什麼樣。\n我只知道另一種結果：王國會毀滅。」",
        "ja": "扉が開く。\n\n「私が知らなかったと思うか？」\n\n「あいつらが何をしていたか、教会が何に変わったか。すべて知っていた。\n私に分かっていたのは一つだけだ。別の道を選べば、王国は滅びる。」"
    },
    "One hundred cultists.\n\nNo hidden lore is attached to the count.\n\nKeep moving.": {
        "zh_cn": "一百名教徒。\n\n这个数量本身没有隐藏设定。\n\n继续前进。",
        "zh_tw": "一百名教徒。\n\n這個數量本身沒有隱藏設定。\n\n繼續前進。",
        "ja": "百人の信徒。\n\nこの人数自体に隠された意味はない。\n\n進み続けろ。"
    },
    "The blade enters.\n\nFor one breath, she is only herself again.": {
        "zh_cn": "刀刃刺入。\n\n在那一口气的时间里，她重新只是她自己。",
        "zh_tw": "刀刃刺入。\n\n在那一口氣的時間裡，她重新只是她自己。",
        "ja": "刃が入る。\n\nひと呼吸の間だけ、彼女はただの彼女に戻る。"
    },
    "The city disappears beneath the fire.\n\nThere is no victory.": {
        "zh_cn": "城市沉入火焰。\n\n这里没有胜利。",
        "zh_tw": "城市沉入火焰。\n\n這裡沒有勝利。",
        "ja": "街は炎の下へ消える。\n\n勝利などない。"
    },
    "The world has become quiet.\n\nMite reaches for Hero's hand.\n\n\"We can stay.\"": {
        "zh_cn": "世界变得安静。\n\n蜜忒伸手握住英雄。\n\n“我们可以留下。”",
        "zh_tw": "世界變得安靜。\n\n蜜忒伸手握住英雄。\n\n「我們可以留下。」",
        "ja": "世界は静かになった。\n\nミーテが英雄の手を取る。\n\n「ここにいられるよ。」"
    },
    "The two figures stand together.\n\nThe edges of the room soften.\n\nThe village outside stops making noise.": {
        "zh_cn": "两个人站在一起。\n\n房间的边缘逐渐柔软。\n\n外面的村庄不再发出声音。",
        "zh_tw": "兩個人站在一起。\n\n房間的邊緣逐漸柔軟。\n\n外面的村莊不再發出聲音。",
        "ja": "二人の姿が並ぶ。\n\n部屋の輪郭がゆっくりと溶けていく。\n\n外の村から音が消える。"
    },
    "No one is lonely.\n\nNo one is separate.\n\nNo one wakes.": {
        "zh_cn": "没有人孤独。\n\n没有人分离。\n\n没有人醒来。",
        "zh_tw": "沒有人孤獨。\n\n沒有人分離。\n\n沒有人醒來。",
        "ja": "誰も孤独ではない。\n\n誰も離れていない。\n\n誰も目を覚まさない。"
    }
}

static func translate_text(value: String) -> String:
    if value.is_empty() or str(WorldState.language) == "en":
        return value
    var entry: Variant = SOURCE_TRANSLATIONS.get(value, null)
    if entry is Dictionary:
        return str(entry.get(str(WorldState.language), value))
    return value

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
