# 地图—剧情整合执行稿 / Map–Narrative Integration Pass 1

> Branch: `development`  
> Scope: box-world traversal and environmental storytelling; art assets remain frozen.  
> Verification boundary: design/code cross-reference only; no Godot 4.6.x runtime acceptance is claimed.

## 中文

### 本轮裁定

地图不是剧情发生的背景板，而是玩家调查真相的证据链。当前优先把已有地图、路线门槛、异常调查点和角色关系统一成可执行的探索节奏；不新增大段对白，不用数值化好感度，不把隐藏区域当作强制主线。

工作顺序：

1. 先保证每个主区域的入口、出口、分层路线和回程具有空间意义。
2. 再让玩家沿路线自然发现相互印证的环境证据。
3. 最后才把证据与主线剧情事实、角色事件、结局条件接线。
4. 每次修改都分别记录拓扑、场景脚本、存档状态和实机验收状态；静态通过不能替代实机通过。

### 区域叙事链

| 区域 | 空间记忆点 / 探索动机 | 已有证据方向 | 叙事作用与下一步 |
|---|---|---|---|
| A0 教会手术所 | 维护高路、手术台与封锁门 | 主角被作为实验对象；残留古神物质 | 序章只让玩家感到“被处理”，不解释古神与外神的关系；高路不能绕过守卫锁 |
| A1 边境村庄 | 地面聚落、屋顶高路、炉火休整点、排水替代路线 | 村民救起失忆骑士；教会与劫掠者威胁村庄 | 以日常物件与村民行为建立归属感；玩家可以先探索，也可以急于离开，后者会错过与蜜忒相处的机会 |
| A2 雾林／钟墓 | 树冠主路与地面钟墓分流 | 无舌之钟仍发声；旧朝圣路的第二道回声 | 第一次建立“感知不可信”的规则；钟墓是可选调查，不应成为进入 A3 的硬性前置 |
| A3 被遗忘城区 | 市场地面路、屋顶回环、旧排水支路 | 第三街被从城市记录中抹除 | 把“删去道路”呈现为制度性抹除的第一个样本；H03 是更深层的空间异常，不是普通地下室 |
| A4 下水道／旧水库 | 地面安全路、抬高管线、多个高低层捷径 | 教会管道安装在更古老的石层上 | 让玩家先看见教会利用遗迹，而不是一开始就知道其目的；A4 应作为可回访枢纽，不应变成单线长廊 |
| A5 旧战场 | 战壕安全路、破损城墙高路 | 尸体朝向被安排；官方将屠杀改写为信仰奇迹 | 第一次把教会的宣传机器与实体暴力连接起来；玩家应能从地面与高路看到不同现场细节 |
| A6 修道院／钟塔 | 主阶梯、侧回廊、钟塔落差捷径 | 无声之窗与异常钟影；疯狂神职人员的低语 | 教会内部已出现被异象侵蚀的人员，但不能把所有教士都写成知情恶人；C10 必须独立于 H05 |
| A7 监牢 | 牢房地面与维修栈道 | 转送记录充足，处决记录稀少，目的地写作“观测区” | 把村民失踪、教会研究和王国行政系统连起来；避免一次性解释整个实验体系 |
| A8 旧王墓 | 石棺地面路与被抹名的上层墓廊 | 王室名字被封存后再凿除 | 玩家开始怀疑王室也参与掩盖；H06 与通往 A11 的 C15 必须保持不同用途 |
| A9 王城外环 | 街面安全路、屋顶回环、排水高路 | 水洼中的街灯多于现实；废弃街区保存异常回声 | 作为低压力交通枢纽，让玩家有空间整合证据；H07 需要剧情事实与 R07，不能只靠数值开门 |
| A10 大圣堂 | 朝圣阶梯、侧礼拜堂、唱诗席高廊 | 双重封印的圣物匣：教会印记覆盖更古老符号 | 把“教会借用古老力量并重新命名为信仰”具体化；进入大圣堂本身记录主线到达事实 |
| A11 深层研究区 | 观测桥、实验层、通往 H08 的深层路线 | 观测记录彼此矛盾；R08 揭示非人接触的累积 | 证据应证明教会在研究一种早于自身的存在，但不能替玩家完整解释外神；H08 仍是可选深层探索 |
| A12 王室内城 | 王室大道、城墙高路、王座入口 | 国王未拆开的信承认知情，却把保全王国置于真相之上 | 将政治冲突收束到“明知有罪仍选择维持国家”的困境；不可把国王简化成纯粹幕后恶人 |
| A13 终局异象 | 断裂上升路径、没有普通回程的终局门槛 | 结局状态决定最后的现实解释 | A13 已有独立场景；它是结局汇流层，不是普通探索区，也不能因进入场景就默认玩家掌握全部真相 |
| H01–H05 | 井底、倒响钟、删去的街、倒影阶梯、无影窗 | 时间、空间与记录互相矛盾 | 每个隐藏区提供一个独立异常，不给免费休整点；返回主区后应能重新理解对应地标 |
| H06–H08 | 王名抹除廊、镜街、胎宫／原初空腔 | 王室删名、外神共鸣、原初容器与接触证据 | 逐步逼近宇宙层真相，但不把“蜜忒就是代理者”作为可直接读取的文本答案；H08 结局出口仍需身体交融事实 |
| H09 候选区 | 崖下实验窟 | 临时实验体与候选遗物 | 目前不属于正式世界设定与核心验收范围；在正式剧情裁定前，不得把其遗物加入烈火天罚必要条件 |

### 三条剧情证据链

**链 A：教会如何制造“信仰奇迹”**

A0 手术残留 → A4 古老石层上的教会管道 → A5 被改写的战场记录 → A7 “观测区”转送账册 → A10 双重封印圣物匣 → A11 深层研究记录。

设计规则：每个节点只补充一块证据。玩家应先怀疑官方叙述，再逐步意识到教会在研究早于它的力量；不让任何单条调查直接讲完真相。

**链 B：王国如何参与掩盖**

A5 战场宣传 → A7 监牢转送 → A8 王室删名 → A12 国王未拆开的信。

设计规则：国王知道教会实验，却把王国存续当作最高理由。证据应呈现他的责任与恐惧，而不是将其写成单纯的邪恶反派。最终由玩家在战斗和结局中裁定，而不是由档案替玩家下结论。

**链 C：蜜忒与外神的悲剧**

A1 村庄生活与相处机会 → 关系是否自然成长 → 中后期身体交融 → 主角体内古神残留与蜜忒关联的外神影响发生共鸣 → 蜜忒逐渐失去自主性 → 三种结局。

设计规则：蜜忒前期的纯真必须真实；她最初并不理解外神，也没有从头到尾策划末日。主角在主线中不会主动得知她的真实身份。关系通过共同时间、记忆、帮助、错过和回访体现，不增加可见的“好感度条”。

### 地图结构下一轮优先级

- **P0 — 场景与拓扑一致：** 逐条对照 C01–C24、H01–H08 的实体门、开启条件、目标场景和回程出生侧。优先 A3/A4/A8/A9 这些高连接度枢纽。
- **P0 — 分层路线真实有用：** 高位门只能从对应平台触发；高路必须有可辨认的接近路线，不能从连续地面直接互动；捷径开启后要真实缩短回程。
- **P1 — 线索与空间绑定：** 关键证据放在玩家自然会停留或绕路的地标附近，不把所有调查点堆在出生点附近；可选路线提供补充视角，不阻断主线。
- **P1 — 回访产生新意义：** 开门或记录事实后，允许玩家从另一侧重新理解路线；不为每次回访弹出重复开场文字。
- **P2 — 剧情状态回归：** 检查来源 ID 的一次性奖励、旧存档修复、蜜忒关系错过状态、外神共鸣顺序与结局门槛。
- **实机验收：** 由本地 Godot 4.6.x 按矩阵逐图走测；未实测项保持“待验收”。

### 本轮完成标准

- [x] 将 A0–A13、H01–H08 的空间记忆点与剧情证据方向统一记录。
- [x] 明确教会、王国、蜜忒三条证据链及不可越界的剧情事实。
- [x] 明确 H09 的候选状态与 A13 独立场景定位。
- [x] 记录地图拓扑、实体场景、剧情状态、实机验收四层必须分开检查。
- [ ] 按 P0 对高连接度区域执行逐门场景级审计。
- [ ] 在 Godot 中完成实际走图、隐藏区往返、死亡与存档恢复验收。

---

## English

### Decision

The map is not a backdrop for the plot; it is the player's evidence chain. This pass aligns existing regions, route gates, anomaly investigations, and relationship beats into an executable exploration rhythm. It does not add exposition-heavy dialogue, a numeric affection meter, or mandatory hidden areas.

### Three evidence chains

1. **How the Church manufactures “miracles”:** A0 surgical residue → A4 church pipes over older stonework → A5 rewritten battlefield history → A7 prisoner transfers to the “observation sector” → A10 double-sealed reliquary → A11 deep-research records.
2. **How the Kingdom helps conceal the truth:** A5 propaganda → A7 transfers → A8 erased royal names → A12 the King's unopened letter. The King is responsible, but not a simplistic evil mastermind; he knowingly places the Kingdom's survival above truth.
3. **The tragedy of Hero and Mite:** village life and missed opportunities → relationship growth or separation → later physical union → contact between Hero's ancient-god residue and the Outer-God influence associated with Mite → gradual loss of Mite's agency → the three canonical endings. Mite's early innocence is genuine, and Hero does not knowingly learn her true identity in the main story.

### Region-level implementation intent

- **A0–A1:** establish the experiment and the village worth returning to. The high catwalk must not bypass the warden lock; village life should make missed relationship opportunities feel natural, not like a failed quest.
- **A2–A4:** establish unreliable perception and reveal that the Church built over older structures. Optional bell-grave exploration must not block the main route.
- **A5–A8:** connect rewritten military history, prisoner transfers, and erased royal names without explaining the whole conspiracy in a single clue.
- **A9–A12:** use the outer ring as a low-pressure hub, the cathedral as proof of repurposed ancient power, and the King's letter to expose the political dilemma.
- **A13:** an existing standalone ending-convergence scene, not an ordinary exploration region and not proof that the Hero understands every secret.
- **H01–H08:** each hidden area contributes one distinct anomaly and should reinterpret a landmark in its parent region. H08 remains optional, with its ending exit gated by the physical-union story fact.
- **H09:** provisional only; do not make its relic a required ending item until its story status is formally decided.

### Next priorities

- **P0:** reconcile C01–C24 and H01–H08 with actual scene doors, unlock gates, target scenes, and return spawns; prioritize the high-degree hubs A3/A4/A8/A9.
- **P0:** make elevated routes function spatially, and ensure shortcuts genuinely shorten backtracking.
- **P1:** place clues beside meaningful landmarks, not all beside spawn points; optional routes should deepen the story without blocking the main path.
- **P1:** let return visits change the player's interpretation without replaying the same introduction.
- **P2:** regress one-time source rewards, legacy-save repair, missed Mite relationship states, resonance event ordering, and ending gates.
- **Runtime:** local Godot 4.6.x traversal is still required. Static checks are not runtime acceptance.
