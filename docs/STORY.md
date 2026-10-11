# Nereis Hero — Story Foundation

> Canonical developer memory: [DEVELOPER_STORY_MEMORY.md](./DEVELOPER_STORY_MEMORY.md)  
> Shared-world canon: [CROSS_GAME_STORY_CANON_CN.md](./CROSS_GAME_STORY_CANON_CN.md) / [CROSS_GAME_STORY_CANON_EN.md](./CROSS_GAME_STORY_CANON_EN.md)

## Core premise

A wounded Kingdom knight escapes Church experimentation with his memories destroyed. A remote village rescues him, and there he meets **Mite**. Mite's early innocence is genuine; she does not consciously understand the Outer-God influence connected to her. Hero does not knowingly learn Mite's true identity during the RPG main story.

The Church studied a sleeping ancient god and used traces of its body to manufacture counterfeit “faith power”. The experiments left ancient-god residue inside Hero. The Church treats people as expendable research material; the Kingdom's political institutions are compromised in different ways.

## Revised catalyst

Hero's ancient-god residue, growing Resonance, and the Outer-God trace connected to Mite can interact. Physical intimacy is one possible emotional and narrative catalyst, and may change Mite's personal scenes and the influence she experiences. **It is not a required event for any ending and is not read by the ending evaluator.**

The Outer God does not depend on one romantic event or one vessel. It can answer a sufficiently strong Resonance signal, exploit accumulated exposure, and continue searching for another vessel if one attempt fails. Mite's early affection is not a planned deception.

## Ending evaluation contract

The ending is chosen from the Hero's accumulated **Resonance, truth-anchor items, and exploration record**. Relationship scenes remain meaningful story content, but never gate the three endings. Prototype thresholds live in scripts/core/ending_evaluator.gd:

- **凡人之墓 / Mortal's Grave** — the combined Resonance and exploration evidence for a cosmic ending is missing. Hero defeats the Church's leadership and the King, helping the Restoration Army remove the Church's immediate control. The victory is real, but the restored order gradually reproduces the corruption it replaced.
- **永恒乐园 / Eternal Paradise** — Resonance reaches the cosmic threshold and exploration exposes Hero to an Outer-God trace, but he has not assembled enough truth anchors and explored enough hidden regions to preserve his individuality. The Outer God turns him into a vessel and draws the world into an eternal dream. A physical relationship with Mite is not required.
- **烈火天罚 / Blazing Judgment** — Resonance reaches the cosmic threshold, Hero finds at least three truth-anchor sources, and explores at least two hidden regions. The assembled anchor preserves enough agency to resist the Outer God's completion. Resistance still comes at a catastrophic cost.

### Prototype thresholds

- Cosmic Resonance threshold: 68.
- Eternal Paradise: Resonance >= 68, the Observer Reaction source is recorded, and at least one hidden region is entered, unless Blazing Judgment requirements are met.
- Blazing Judgment: Resonance >= 68, at least 3 unique truth-anchor sources, and at least 2 hidden regions entered.
- Mortal's Grave: all other combinations.

These are gameplay tuning values, not immutable metaphysical laws.

## Final confrontations

### 凡人之墓
1. Hero confronts the Church's highest authority.
2. The Pope / High Priest transforms through ancient-god power.
3. The King enters the battlefield, believing terrible compromises are necessary to preserve the Kingdom.
4. Hero defeats them; the Restoration Army takes control.
5. The epilogue reveals corruption slowly returning under a new name.

### 永恒乐园
Hero's Resonance becomes a beacon. Without enough evidence to preserve his selfhood, he becomes a vessel. The Church and King become temporary obstacles swallowed by the Outer God's eternal dream. Mite's role depends on the relationship scenes actually experienced; the ending must not assume physical union occurred.

### 烈火天罚
The multi-part truth anchor preserves Hero's agency long enough to resist the Outer God's completion. The Church's authority falls, Outer-God-influenced cultists overwhelm the city, and the final confrontation with Mite is a tragic set-piece rather than a conventional boss loop. Physical intimacy is not a prerequisite.

## Cross-game cycle

The RPG's Mortal's Grave ending is not the world's final answer. After the Church is removed, the Restoration Army gradually becomes another corrupt institution. In **Nereis-Lullaby**, told primarily through Mite's perspective, players can witness Hero's later compromises, his fall into the new order, and the way he abandons Mite or leaves her behind. Mite may understand only fragments. The Outer God is indifferent to human political cycles and continues looking for another vessel.

This continues rather than retcons the RPG's victory: Hero can win the battle and still fail to break the cycle.

## Narrative rules

- Mite's early innocence is genuine.
- Hero does not knowingly identify Mite as an Outer-God proxy during the RPG main story.
- Relationship content changes scenes and emotional meaning; it does not decide the ending.
- Resonance reveals evidence but does not guarantee understanding.
- Hidden sources should initially appear unrelated and later form a larger explanation.
- No ending is a clean happy ending.
