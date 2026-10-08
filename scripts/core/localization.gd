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
        "hud.controls": "A/D 移动    SPACE 跳跃    J 攻击    K 闪避    Q 切换武器    ESC 菜单",
        "hud.hp": "生命",
        "hud.sta": "体力",
        "hud.hum": "人性",
        "narrative.skip": "E / SPACE / ENTER / J / 鼠标点击：继续",
        "narrative.continue": "继续",
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
        "hud.controls": "A/D 移動    SPACE 跳躍    J 攻擊    K 閃避    Q 切換武器    ESC 選單",
        "hud.hp": "生命",
        "hud.sta": "體力",
        "hud.hum": "人性",
        "narrative.skip": "E / SPACE / ENTER / J / 滑鼠點擊：繼續",
        "narrative.continue": "繼續",
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
        "hud.controls": "A/D MOVE    SPACE JUMP    J ATTACK    K DODGE    Q SWITCH WEAPON    ESC MENU",
        "hud.hp": "HP",
        "hud.sta": "STA",
        "hud.hum": "HUM",
        "narrative.skip": "E / SPACE / ENTER / J / CLICK TO CONTINUE",
        "narrative.continue": "CONTINUE",
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
        "hud.controls": "A/D 移動    SPACE ジャンプ    J 攻撃    K 回避    Q 武器切替    ESC メニュー",
        "hud.hp": "HP",
        "hud.sta": "ST",
        "hud.hum": "人間性",
        "narrative.skip": "E / SPACE / ENTER / J / クリックで進む",
        "narrative.continue": "続ける",
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


const SOURCE_TRANSLATIONS_EXTRA := {
    "The old hunter looks at your face and goes pale.\n\n\"You used to come here before the church took you. You always asked whether the song was still playing.\"\n\nSomewhere beyond the village, a lullaby answers.": {
        "zh_cn": "老猎人看着你的脸，脸色骤然变白。\n\n“在教会带走你之前，你以前常来这里。你总会问，那首歌是不是还在响。”\n\n村庄之外，摇篮曲回应了。",
        "zh_tw": "老獵人看著你的臉，臉色驟然變白。\n\n「在教會帶走你之前，你以前常來這裡。你總會問，那首歌是不是還在響。」\n\n村莊之外，搖籃曲回應了。",
        "ja": "老狩人はあなたの顔を見て青ざめる。\n\n「教会に連れていかれる前、お前はよくここへ来た。いつもあの歌はまだ聞こえるのかと聞いていた。」\n\n村の向こうで、子守歌が答える。"
    },
    "You have already heard this memory.": {
        "zh_cn": "你已经听过这段记忆了。",
        "zh_tw": "你已經聽過這段記憶了。",
        "ja": "この記憶はもう聞いた。"
    },
    "You close your hand around the seal.\n\nThe metal is warm. Someone, somewhere, expected you to come back.": {
        "zh_cn": "你握紧手中的印记。\n\n金属是温热的。某个地方的某个人，早就料到你会回来。",
        "zh_tw": "你握緊手中的印記。\n\n金屬是溫熱的。某個地方的某個人，早就料到你會回來。",
        "ja": "印を手の中で握りしめる。\n\n金属は温かい。どこかの誰かが、あなたの帰還を待っていた。"
    },
    "You turn toward the song.\n\nFor one heartbeat, you remember the village before the church found you.": {
        "zh_cn": "你转向那首歌。\n\n在一瞬间，你想起教会找到你之前的村庄。",
        "zh_tw": "你轉向那首歌。\n\n在一瞬間，你想起教會找到你之前的村莊。",
        "ja": "歌の方へ振り向く。\n\nほんの一瞬、教会に見つかる前の村を思い出す。"
    },
    "The old hunter corrects your stance.\n\n\"You keep fighting like you remember dying.\"\n\nYour sword cuts deeper now.": {
        "zh_cn": "老猎人纠正了你的姿势。\n\n“你战斗的样子，就像你记得自己曾经死过。”\n\n你的剑锋因此更加锋利。",
        "zh_tw": "老獵人糾正了你的姿勢。\n\n「你戰鬥的樣子，就像你記得自己曾經死過。」\n\n你的劍鋒因此更加鋒利。",
        "ja": "老狩人が構えを直す。\n\n「まるで、自分が死んだことを覚えているような戦い方だ。」\n\n剣の切れ味が増している。"
    },
    "The blade is as sharp as it needs to be. For now.": {
        "zh_cn": "这把剑现在已经足够锋利了。暂时如此。",
        "zh_tw": "這把劍現在已經足夠鋒利了。暫時如此。",
        "ja": "この剣は、今は十分に鋭い。今のところは。"
    },
    "The cultist falls. Somewhere beyond the iron gate, something hears the silence.": {
        "zh_cn": "教徒倒下了。铁门之外，某个东西听见了这片寂静。",
        "zh_tw": "教徒倒下了。鐵門之外，某個東西聽見了這片寂靜。",
        "ja": "信徒が倒れる。鉄門の向こうで、何かがこの静寂を聞いている。"
    },
    "The first road is behind you.\n\nThe church seal is warm in one hand. The lullaby is still somewhere behind the hills.\n\nVERTICAL SLICE 001 COMPLETE": {
        "zh_cn": "第一条道路已经留在身后。\n\n一只手中的教会印记仍然温热。山丘背后，摇篮曲还在响。\n\n核心试玩章节 001 完成",
        "zh_tw": "第一條道路已經留在身後。\n\n一隻手中的教會印記仍然溫熱。山丘背後，搖籃曲還在響。\n\n核心試玩章節 001 完成",
        "ja": "最初の道は背後にある。\n\n片手の教会印はまだ温かい。丘の向こうでは子守歌が続いている。\n\nバーティカルスライス001 完了"
    },
    "The armor falls without a body inside.\n\nFor a moment, the Hero remembers kneeling before the church. Then the memory tears itself away.": {
        "zh_cn": "铠甲倒下，里面却没有尸体。\n\n有那么一瞬间，英雄记起自己曾跪在教会面前。随后，这段记忆再次撕裂。",
        "zh_tw": "鎧甲倒下，裡面卻沒有屍體。\n\n有那麼一瞬間，英雄記起自己曾跪在教會面前。隨後，這段記憶再次撕裂。",
        "ja": "鎧が倒れる。中には死体がない。\n\n一瞬だけ、英雄は教会の前で跪いていたことを思い出す。そして記憶は再び引き裂かれる。"
    },
    "Inside the fallen armor you find a church seal.\n\nFrom the village, the lullaby begins again. You can follow the seal, or follow the song.\n\n[1] Follow the church seal\n[2] Follow the lullaby": {
        "zh_cn": "倒下的铠甲里藏着一枚教会印记。\n\n村庄方向再次传来摇篮曲。你可以跟随印记，也可以跟随歌声。\n\n[1] 跟随教会印记\n[2] 跟随摇篮曲",
        "zh_tw": "倒下的鎧甲裡藏著一枚教會印記。\n\n村莊方向再次傳來搖籃曲。你可以跟隨印記，也可以跟隨歌聲。\n\n[1] 跟隨教會印記\n[2] 跟隨搖籃曲",
        "ja": "倒れた鎧の中から教会の印を見つける。\n\n村の方から、また子守歌が聞こえる。印を追うか、歌を追うか。\n\n[1] 教会の印を追う\n[2] 子守歌を追う"
    },
    "The straps are broken. The room smells of iron and incense.\n\nSomewhere behind the walls, a bell keeps ringing.": {
        "zh_cn": "束缚带已经断裂。房间里弥漫着铁锈和熏香的气味。\n\n墙壁后方，有一口钟一直在响。",
        "zh_tw": "束縛帶已經斷裂。房間裡瀰漫著鐵鏽和薰香的氣味。\n\n牆壁後方，有一口鐘一直在響。",
        "ja": "拘束具は壊れている。部屋には鉄と香の匂いが満ちている。\n\n壁の向こうでは、鐘が鳴り続けている。"
    },
    "A metal tray holds dried black residue beneath a layer of blood.\n\nThe Hero touches it.\n\nSomething inside his arm answers.\n\nThe sensation stops before it becomes a memory.": {
        "zh_cn": "金属托盘里，血迹下面残留着干涸的黑色物质。\n\n英雄伸手触碰。\n\n手臂深处有什么东西回应了。\n\n感觉在成为记忆之前便消失。",
        "zh_tw": "金屬托盤裡，血跡下面殘留著乾涸的黑色物質。\n\n英雄伸手觸碰。\n\n手臂深處有什麼東西回應了。\n\n感覺在成為記憶之前便消失。",
        "ja": "金属のトレイには、血の下に乾いた黒い残留物がある。\n\n英雄が触れる。\n\n腕の奥の何かが応える。\n\n感覚は記憶になる前に消えた。"
    },
    "There are no prayers here.\n\nOnly instruments polished often enough to look sacred.": {
        "zh_cn": "这里没有祷告。\n\n只有被擦拭得足够干净、以至于看起来像圣物的器械。",
        "zh_tw": "這裡沒有禱告。\n\n只有被擦拭得足夠乾淨，以至於看起來像聖物的器械。",
        "ja": "ここに祈りはない。\n\nあるのは、聖なる物に見えるほど磨かれた器具だけ。"
    },
    "The liquid is not quite black.\n\nWhen light crosses it, the color inside becomes red.\n\nThe label contains only one word: 'SAINT.'": {
        "zh_cn": "液体并非纯黑。\n\n当光线穿过它时，里面的颜色变成红色。\n\n标签上只有一个词：“圣者”。",
        "zh_tw": "液體並非純黑。\n\n當光線穿過它時，裡面的顏色變成紅色。\n\n標籤上只有一個詞：「聖者」。",
        "ja": "液体は完全な黒ではない。\n\n光が通ると、中の色が赤く変わる。\n\nラベルには一語だけある。「聖人」。"
    },
    "A bundle of pale hair floats inside a glass cylinder.\n\nThere is no body attached to it.\n\nThe wax seal bears an older Kingdom crest.": {
        "zh_cn": "一束苍白的头发漂浮在玻璃筒中。\n\n它没有连接任何尸体。\n\n蜡封上印着更古老的王国徽章。",
        "zh_tw": "一束蒼白的頭髮漂浮在玻璃筒中。\n\n它沒有連接任何屍體。\n\n蠟封上印著更古老的王國徽章。",
        "ja": "淡い髪の束がガラス筒の中に浮かんでいる。\n\nそこには身体がない。\n\n封蝋には、より古い王国の紋章が刻まれている。"
    },
    "The thing collapses.\n\nBeneath its ribs, a metal hook remains embedded in bone.\n\nThe hook is shaped for something much larger than the body it came from.": {
        "zh_cn": "那东西倒下。\n\n肋骨下面，一枚金属钩仍嵌在骨头里。\n\n那枚钩子原本属于远比这具身体庞大的东西。",
        "zh_tw": "那東西倒下。\n\n肋骨下面，一枚金屬鉤仍嵌在骨頭裡。\n\n那枚鉤子原本屬於遠比這具身體龐大的東西。",
        "ja": "それは崩れ落ちる。\n\n肋骨の下に、金属の鉤が骨へ食い込んでいる。\n\nその鉤は、この身体よりはるかに大きな何かのものだ。"
    },
    "The captain studies your church-marked blade.\n\n\"We are not here because we are righteous.\"\n\n\"We are here because the throne is ours.\"\n\nThere is no pride in the last sentence.": {
        "zh_cn": "队长打量着你那把带有教会印记的剑。\n\n“我们来到这里，不是因为我们正义。”\n\n“只是因为王座本来就属于我们。”\n\n最后一句里没有任何骄傲。",
        "zh_tw": "隊長打量著你那把帶有教會印記的劍。\n\n「我們來到這裡，不是因為我們正義。」\n\n「只是因為王座本來就屬於我們。」\n\n最後一句裡沒有任何驕傲。",
        "ja": "隊長は教会の印が刻まれた剣を見る。\n\n「俺たちは正しいからここにいるんじゃない。」\n\n「王座が俺たちのものだからだ。」\n\n最後の言葉に、誇りはなかった。"
    },
    "The quartermaster counts bandages twice.\n\n\"If the Kingdom returns, food still has to be bought.\"\n\n\"People forget that when they start talking about crowns.\"": {
        "zh_cn": "军需官把绷带数了两遍。\n\n“王国就算回来，食物还是要花钱买。”\n\n“人们一谈起王冠，就会忘记这一点。”",
        "zh_tw": "軍需官把繃帶數了兩遍。\n\n「王國就算回來，食物還是要花錢買。」\n\n「人們一談起王冠，就會忘記這一點。」",
        "ja": "補給係は包帯を二度数える。\n\n「王国が戻ってきても、食料は買わなきゃならない。」\n\n「王冠の話を始めると、人はそれを忘れる。」"
    },
    "The old soldier never looks toward the campfire.\n\n\"The Church taught us obedience.\"\n\n\"The rebels will teach us loyalty.\"\n\nHe spits into the dirt.": {
        "zh_cn": "老兵从不看向篝火。\n\n“教会教我们服从。”\n\n“复国军会教我们忠诚。”\n\n他朝泥土里吐了一口唾沫。",
        "zh_tw": "老兵從不看向篝火。\n\n「教會教我們服從。」\n\n「復國軍會教我們忠誠。」\n\n他朝泥土裡吐了一口唾沫。",
        "ja": "老兵は焚き火を見ようとしない。\n\n「教会は服従を教えた。」\n\n「反乱軍は忠誠を教えるだろう。」\n\n彼は土に唾を吐いた。"
    },
    "There is no banner over the fire.\n\nOnly stolen weapons, borrowed horses and people waiting for a kingdom that no longer exists.": {
        "zh_cn": "篝火上没有旗帜。\n\n只有偷来的武器、借来的马，以及等待一个已经不存在的王国归来的人们。",
        "zh_tw": "篝火上沒有旗幟。\n\n只有偷來的武器、借來的馬，以及等待一個已經不存在的王國歸來的人們。",
        "ja": "焚き火の上に旗はない。\n\nあるのは盗んだ武器、借りた馬、そしてもう存在しない王国を待ち続ける人々だけ。"
    },
    "The camp keeps breathing behind you.": {
        "zh_cn": "营地在你身后继续呼吸。",
        "zh_tw": "營地在你身後繼續呼吸。",
        "ja": "背後で野営地は息づき続けている。"
    },
    "The merchant studies your face for a long moment.\n\n\"You walked this road before. You were carrying someone then. Not a sword.\"": {
        "zh_cn": "商人久久端详着你的脸。\n\n“你以前走过这条路。那时候你抱着的是某个人，而不是一把剑。”",
        "zh_tw": "商人久久端詳著你的臉。\n\n「你以前走過這條路。那時候你抱著的是某個人，而不是一把劍。」",
        "ja": "商人は長い間あなたの顔を見る。\n\n「お前は以前この道を歩いた。その時、お前が抱えていたのは剣じゃない。誰かだった。」"
    },
    "The young man touches the church seal and recoils.\n\n\"They told me you died inside the church. I remember hearing your name after the screaming stopped.\"": {
        "zh_cn": "年轻人碰到教会印记，猛地缩回手。\n\n“他们告诉我，你死在了教会里。我记得尖叫停止之后，还听见过你的名字。”",
        "zh_tw": "年輕人碰到教會印記，猛地縮回手。\n\n「他們告訴我，你死在了教會裡。我記得尖叫停止之後，還聽見過你的名字。」",
        "ja": "青年は教会の印に触れ、身を引く。\n\n「教会の中で死んだと聞いた。叫び声が止んだあと、お前の名前を聞いたのを覚えている。」"
    },
    "The road ends at a cluster of warm windows.\n\nYou recognize the tavern before you recognize why.": {
        "zh_cn": "道路尽头是一片温暖的窗灯。\n\n你先认出了酒馆，随后才想起自己为什么认得。",
        "zh_tw": "道路盡頭是一片溫暖的窗燈。\n\n你先認出了酒館，隨後才想起自己為什麼認得。",
        "ja": "道の先に、温かな窓明かりが集まっている。\n\nなぜ知っているのか思い出す前に、酒場だと分かった。"
    },
    "The bell is silent. Your name is not.\n\nSomewhere beyond the doors, someone has been waiting for you.": {
        "zh_cn": "钟是寂静的，但你的名字不是。\n\n门后某处，有人在等你。",
        "zh_tw": "鐘是寂靜的，但你的名字不是。\n\n門後某處，有人在等你。",
        "ja": "鐘は沈黙している。だが、あなたの名は違う。\n\n扉の向こうで、誰かがあなたを待っている。"
    },
    "The bell rings without moving.\n\nA child hums a melody you remember from before you were born.": {
        "zh_cn": "钟没有移动，却响了起来。\n\n一个孩子哼着你出生之前就已经记得的旋律。",
        "zh_tw": "鐘沒有移動，卻響了起來。\n\n一個孩子哼著你出生之前就已經記得的旋律。",
        "ja": "鐘は動いていないのに鳴っている。\n\n子供が、生まれる前から知っているような旋律を口ずさむ。"
    },
    "Your name is written in the margin three times.\n\nThe first is dated seven years ago. The second is yesterday. The third has no date.": {
        "zh_cn": "页边写着你的名字，一共三次。\n\n第一次是七年前，第二次是昨天，第三次没有日期。",
        "zh_tw": "頁邊寫著你的名字，一共三次。\n\n第一次是七年前，第二次是昨天，第三次沒有日期。",
        "ja": "余白には、あなたの名が三度書かれている。\n\n最初は七年前。次は昨日。最後には日付がない。"
    },
    "Torches appear beyond the fields.\n\nThe Church came with the bandits.\n\nNo one asks the Hero to fight. He simply draws his sword.": {
        "zh_cn": "田野之外出现火把。\n\n教会和强盗一起来了。\n\n没人要求英雄战斗，他只是拔出了剑。",
        "zh_tw": "田野之外出現火把。\n\n教會和強盜一起來了。\n\n沒人要求英雄戰鬥，他只是拔出了劍。",
        "ja": "野の向こうに松明が現れる。\n\n教会は盗賊を連れてきた。\n\n誰も英雄に戦えとは言わない。彼はただ剣を抜く。"
    },
    "They are coming for the houses behind you.": {
        "zh_cn": "他们正朝着你身后的房屋而来。",
        "zh_tw": "他們正朝著你身後的房屋而來。",
        "ja": "奴らは、君の背後の家々を狙っている。"
    },
    "The first line breaks.\n\nThere are more behind it.": {
        "zh_cn": "第一道防线被突破。\n\n后面还有更多。",
        "zh_tw": "第一道防線被突破。\n\n後面還有更多。",
        "ja": "第一線が崩れる。\n\nその後ろには、まだいる。"
    },
    "The attackers retreat.\n\nThe village is still standing.\n\nFor tonight, that is enough.": {
        "zh_cn": "袭击者撤退了。\n\n村庄还站着。\n\n至少今晚，这就够了。",
        "zh_tw": "襲擊者撤退了。\n\n村莊還站著。\n\n至少今晚，這就夠了。",
        "ja": "襲撃者は退いていく。\n\n村はまだ立っている。\n\n今夜は、それで十分だ。"
    },
    "The Hero rises again.\n\nThe attack has not ended.": {
        "zh_cn": "英雄再次站起。\n\n袭击还没有结束。",
        "zh_tw": "英雄再次站起。\n\n襲擊還沒有結束。",
        "ja": "英雄は再び立ち上がる。\n\n襲撃はまだ終わっていない。"
    },
    "The stone carries your name, but the date is wrong.\n\nSomeone carved a second line beneath it: \"He came back after the bell stopped.\"": {
        "zh_cn": "石碑刻着你的名字，但日期不对。\n\n有人在下面又刻了一行：“钟停止之后，他回来了。”",
        "zh_tw": "石碑刻著你的名字，但日期不對。\n\n有人在下面又刻了一行：「鐘停止之後，他回來了。」",
        "ja": "石碑にはあなたの名がある。だが日付が違う。\n\nその下に、誰かが一行彫っていた。「鐘が止まったあと、彼は帰ってきた。」"
    },
    "The bell tower is quiet now.\n\nYou are certain it rang after you left.": {
        "zh_cn": "钟楼现在很安静。\n\n但你确定，在你离开之后它曾经响过。",
        "zh_tw": "鐘樓現在很安靜。\n\n但你確定，在你離開之後它曾經響過。",
        "ja": "鐘楼は今、静まり返っている。\n\nだが、君が去ったあとに鳴ったはずだ。"
    },
    "The graves are too old for the names carved into them.\n\nThe bell tower is silent. Something beneath it is not.": {
        "zh_cn": "这些墓碑太古老，不该刻着这些人的名字。\n\n钟楼寂静无声，但它下面有什么东西并不安静。",
        "zh_tw": "這些墓碑太古老，不該刻著這些人的名字。\n\n鐘樓寂靜無聲，但它下面有什麼東西並不安靜。",
        "ja": "墓は古すぎて、刻まれた名に合わない。\n\n鐘楼は沈黙している。その下にある何かだけが違う。"
    },
    "Both wraiths collapse.\n\nThe silent tower rings once. No bell moves.": {
        "zh_cn": "两只怨灵同时倒下。\n\n寂静的钟楼响了一声，却没有一口钟移动。",
        "zh_tw": "兩隻怨靈同時倒下。\n\n寂靜的鐘樓響了一聲，卻沒有一口鐘移動。",
        "ja": "二体の亡霊が崩れる。\n\n静かな鐘楼が一度だけ鳴る。鐘はどれも動かない。"
    },
    "The cemetery gate closes behind you.": {
        "zh_cn": "墓地大门在你身后合上。",
        "zh_tw": "墓地大門在你身後合上。",
        "ja": "墓地の門が背後で閉じる。"
    },
    "The gatekeeper studies the church seal.\n\n\"They told us you would never return. Why did they send the same man back?\"": {
        "zh_cn": "守门人盯着教会印记。\n\n“他们告诉我们你永远不会回来。为什么他们又把同一个人送回来？”",
        "zh_tw": "守門人盯著教會印記。\n\n「他們告訴我們你永遠不會回來。為什麼他們又把同一個人送回來？」",
        "ja": "門番は教会の印を見つめる。\n\n「二度と戻らないと聞いていた。同じ男を、なぜまた送り返した？」"
    },
    "The gatekeeper hears the lullaby on the wind and shuts the tavern door halfway.\n\n\"Don't sing that here. Not unless you want the village to remember.\"": {
        "zh_cn": "守门人听见风中的摇篮曲，只把酒馆门关上一半。\n\n“别在这里唱。除非你想让整个村庄想起来。”",
        "zh_tw": "守門人聽見風中的搖籃曲，只把酒館門關上一半。\n\n「別在這裡唱。除非你想讓整個村莊想起來。」",
        "ja": "門番は風の子守歌を聞き、酒場の扉を半分だけ閉じる。\n\n「ここでは歌うな。村に思い出させたくないなら。」"
    },
    "The young man takes one step back.\n\n\"I know that look. Something in you already left.\"": {
        "zh_cn": "年轻人后退一步。\n\n“我知道那种眼神。你身体里已经有什么东西离开了。”",
        "zh_tw": "年輕人後退一步。\n\n「我知道那種眼神。你身體裡已經有什麼東西離開了。」",
        "ja": "青年は一歩下がる。\n\n「その目を知っている。お前の中の何かは、もう去っている。」"
    },
    "The young man touches your church seal and goes pale.\n\n\"I remember you kneeling there. They told me not to remember.\"": {
        "zh_cn": "年轻人碰到你的教会印记，脸色变白。\n\n“我记得你曾跪在那里。他们告诉我不要记住。”",
        "zh_tw": "年輕人碰到你的教會印記，臉色變白。\n\n「我記得你曾跪在那裡。他們告訴我不要記住。」",
        "ja": "青年は教会の印に触れ、青ざめる。\n\n「お前がそこで跪いていたのを覚えている。忘れろと言われた。」"
    },
    "The young man stares toward the tavern.\n\n\"You came back carrying someone once. I don't know who it was. I only remember the singing.\"": {
        "zh_cn": "年轻人望向酒馆。\n\n“你以前回来过一次，怀里抱着某个人。我不知道是谁，只记得那歌声。”",
        "zh_tw": "年輕人望向酒館。\n\n「你以前回來過一次，懷裡抱著某個人。我不知道是誰，只記得那歌聲。」",
        "ja": "青年は酒場を見る。\n\n「昔、お前は誰かを抱えて戻ってきた。誰だったかは分からない。ただ歌声だけを覚えている。」"
    },
    "The merchant stops smiling.\n\n\"You should not be able to hear the song anymore.\"": {
        "zh_cn": "商人不再微笑。\n\n“你现在本不该还能听见那首歌。”",
        "zh_tw": "商人不再微笑。\n\n「你現在本不該還能聽見那首歌。」",
        "ja": "商人の笑みが消える。\n\n「もう、その歌が聞こえるはずはない。」"
    },
    "The merchant turns a silver token between two fingers.\n\n\"Church roads are safe only until the bells start. Then even the stones lie.\"": {
        "zh_cn": "商人在两指之间转动一枚银币。\n\n“教会的路只有在钟声响起之前才安全。那以后，连石头都会撒谎。”",
        "zh_tw": "商人在兩指之間轉動一枚銀幣。\n\n「教會的路只有在鐘聲響起之前才安全。那之後，連石頭都會撒謊。」",
        "ja": "商人は銀の札を指で回す。\n\n「教会の道が安全なのは、鐘が鳴るまでだ。それからは石まで嘘をつく。」"
    },
    "The merchant smiles without humor.\n\n\"I saw the village seven years ago. Your face was already on the church door.\"": {
        "zh_cn": "商人毫无笑意地笑了。\n\n“七年前我就见过这个村庄。那时，教会门上已经有你的脸。”",
        "zh_tw": "商人毫無笑意地笑了。\n\n「七年前我就見過這個村莊。那時，教會門上已經有你的臉。」",
        "ja": "商人は笑みだけを浮かべる。\n\n「七年前にもこの村を見た。その時には、教会の扉にもうお前の顔があった。」"
    },
    "The tavern door is warm beneath your hand.\n\nFor a moment you hear a lullaby from inside. The voice stops when you touch the handle.": {
        "zh_cn": "酒馆门在你的掌心下是温热的。\n\n有那么一刻，你听见里面传来摇篮曲。手碰到门把手时，歌声却停了。",
        "zh_tw": "酒館門在你的掌心下是溫熱的。\n\n有那麼一刻，你聽見裡面傳來搖籃曲。手碰到門把手時，歌聲卻停了。",
        "ja": "酒場の扉は手のひらに温かい。\n\n一瞬、内側から子守歌が聞こえる。取っ手に触れた途端、声が止まった。"
    },
    "The cemetery gate is open.\n\nThe bell tower has not rung in years. Something inside still answers when you call.": {
        "zh_cn": "墓地大门敞开着。\n\n钟楼已经多年没有响过，但你呼唤时，里面仍有东西回应。",
        "zh_tw": "墓地大門敞開著。\n\n鐘樓已經多年沒有響過，但你呼喚時，裡面仍有東西回應。",
        "ja": "墓地の門は開いている。\n\n鐘楼は何年も鳴っていない。それでも呼びかければ、中の何かが応える。"
    },
    "A small fire burns behind the hill.\n\nSomeone has pitched a camp without a flag.\n\nYou hear soldiers arguing about the throne.": {
        "zh_cn": "山丘后燃着一小堆火。\n\n有人扎起了一个没有旗帜的营地。\n\n你听见士兵正在争论王座。",
        "zh_tw": "山丘後燃著一小堆火。\n\n有人紮起了一個沒有旗幟的營地。\n\n你聽見士兵正在爭論王座。",
        "ja": "丘の向こうで小さな火が燃えている。\n\n旗のない野営地がある。\n\n兵士たちが王座について言い争っている。"
    },
    "Fresh axe marks scar the gate.\n\nBeyond it, the road is too quiet.\n\nYou hear distant metal.": {
        "zh_cn": "新留下的斧痕割裂了大门。\n\n门外的道路安静得反常。\n\n远处传来金属碰撞声。",
        "zh_tw": "新留下的斧痕割裂了大門。\n\n門外的道路安靜得反常。\n\n遠處傳來金屬碰撞聲。",
        "ja": "新しい斧跡が門を傷つけている。\n\nその向こうの道は、静かすぎる。\n\n遠くで金属の音がした。"
    },
    "The church door bears your name beneath layers of newer paint.\n\nSomeone has tried to erase it many times.": {
        "zh_cn": "教会门上，新漆覆盖的下面仍有你的名字。\n\n有人试过很多次想把它抹掉。",
        "zh_tw": "教會門上，新漆覆蓋的下面仍有你的名字。\n\n有人試過很多次想把它抹掉。",
        "ja": "教会の扉には、新しい塗料の下にあなたの名が残っている。\n\n何度も消そうとした跡がある。"
    },
    "The door was never meant for the faithful.\n\nYour name is scratched into the stone beside the lock.": {
        "zh_cn": "这扇门从来不是为信徒准备的。\n\n锁旁的石头上刻着你的名字。",
        "zh_tw": "這扇門從來不是為信徒準備的。\n\n鎖旁的石頭上刻著你的名字。",
        "ja": "この扉は信徒のためのものではなかった。\n\n鍵の横の石には、あなたの名が刻まれている。"
    },
    "Behind the tavern is a path no map remembers.\n\nYou can hear the song again.": {
        "zh_cn": "酒馆后面有一条没有地图记载的路。\n\n你又听见了那首歌。",
        "zh_tw": "酒館後面有一條沒有地圖記載的路。\n\n你又聽見了那首歌。",
        "ja": "酒場の裏には、どの地図にも記されていない道がある。\n\nまた、あの歌が聞こえる。"
    },
    "The stone gives way beneath your hand.\n\nThere should not be a room underneath a village church.": {
        "zh_cn": "石墙在你的手下裂开。\n\n村庄教会下面，本不该存在一个房间。",
        "zh_tw": "石牆在你的手下裂開。\n\n村莊教會下面，本不該存在一個房間。",
        "ja": "手を触れた石が崩れる。\n\n村の教会の地下に部屋など、あるはずがない。"
    },
    "The room is warmer than the road.\n\nSomewhere behind the bar, a glass is placed down by a hand you cannot see.": {
        "zh_cn": "房间比道路温暖。\n\n吧台后方，有只看不见的手放下了一只玻璃杯。",
        "zh_tw": "房間比道路溫暖。\n\n吧檯後方，有隻看不見的手放下了一只玻璃杯。",
        "ja": "部屋は道より暖かい。\n\nカウンターの奥で、見えない手がグラスを置いた。"
    },
    "For once, nothing asks you to remember.": {
        "zh_cn": "这一次，没有任何东西要求你记起什么。",
        "zh_tw": "這一次，沒有任何東西要求你記起什麼。",
        "ja": "今だけは、何も思い出せと迫ってこない。"
    },
    "The room has gone quiet.\n\nThere are two places at the table.\n\nOne bed.": {
        "zh_cn": "房间很小。\n\n桌边有两个位置。\n\n只有一张床。",
        "zh_tw": "房間很小。\n\n桌邊有兩個位置。\n\n只有一張床。",
        "ja": "部屋は小さい。\n\nテーブルには二つの席。\n\nベッドは一つ。"
    },
    "The keeper touches the bell rope.\n\nIt stopped years ago.\n\nBut sometimes I hear it when someone who should be dead walks past.\n\nHis eyes settle on you.": {
        "zh_cn": "守钟人碰了碰钟绳。\n\n它已经停止多年。\n\n但有时，本该死去的人经过时，我仍会听见它响。\n\n他的目光落在你身上。",
        "zh_tw": "守鐘人碰了碰鐘繩。\n\n它已經停止多年。\n\n但有時，本該死去的人經過時，我仍會聽見它響。\n\n他的目光落在你身上。",
        "ja": "鐘守が鐘縄に触れる。\n\n何年も前に止まった。\n\nだが、本来死んでいる者が通る時だけ、聞こえることがある。\n\n彼の目があなたを見る。"
    },
    "The keeper looks toward the tower.\n\nIt rang after you left.\n\nNot because of the dead.\n\nBecause something came back.": {
        "zh_cn": "守钟人望向钟楼。\n\n你离开后，它确实响过。\n\n不是为了死者。\n\n因为有什么东西回来了。",
        "zh_tw": "守鐘人望向鐘樓。\n\n你離開後，它確實響過。\n\n不是為了死者。\n\n因為有什麼東西回來了。",
        "ja": "鐘守は鐘楼を見る。\n\n君が去ったあと、確かに鳴った。\n\n死者のためではない。\n\n何かが戻ってきたからだ。"
    },
    "The keeper has no more answers.\n\nHe only watches the silent bell.": {
        "zh_cn": "守钟人已经没有更多答案。\n\n他只是望着那口寂静的钟。",
        "zh_tw": "守鐘人已經沒有更多答案。\n\n他只是望著那口寂靜的鐘。",
        "ja": "鐘守にはもう答えがない。\n\nただ、沈黙する鐘を見つめている。"
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
    var language_id := str(WorldState.language)
    var entry: Variant = SOURCE_TRANSLATIONS.get(value, null)
    if not (entry is Dictionary):
        entry = SOURCE_TRANSLATIONS_EXTRA.get(value, null)
    if entry is Dictionary:
        return str(entry.get(language_id, value))
    if value.begins_with("HIT  "):
        var damage_text := value.trim_prefix("HIT  ")
        var hit_label: String = str({"zh_cn": "命中  ", "zh_tw": "命中  ", "ja": "命中  "}.get(language_id, "HIT  "))
        return "%s%s" % [hit_label, damage_text]
    if value == "DEFEATED  //  RETURNING TO CHECKPOINT":
        return {"zh_cn": "击败 // 返回检查点", "zh_tw": "擊敗 // 返回檢查點", "ja": "撃破 // チェックポイントへ戻る"}.get(language_id, value)
    if value == "A WARMTH UNDER THE SKIN":
        return {"zh_cn": "皮肤之下的温热", "zh_tw": "皮膚之下的溫熱", "ja": "皮膚の下の温もり"}.get(language_id, value)
    if value == "CORE COMBAT":
        return {"zh_cn": "核心战斗", "zh_tw": "核心戰鬥", "ja": "コア戦闘"}.get(language_id, value)
    if value == "ASHEN ROAD":
        return {"zh_cn": "灰烬之路", "zh_tw": "灰燼之路", "ja": "灰の道"}.get(language_id, value)
    if value == "DEFEAT SMALL ENEMIES    %d / 3":
        return {"zh_cn": "击败小型敌人    %d / 3", "zh_tw": "擊敗小型敵人    %d / 3", "ja": "小型の敵を倒す    %d / 3"}.get(language_id, value)
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
