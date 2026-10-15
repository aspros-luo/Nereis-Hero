# S1.2.5 — Modular Character Customization / 模块化角色自定义系统

## Scope / 范围

This is an isolated visual prototype. It does not change the production Hero's combat, collision, damage, stamina, progression, or main scene.

这是独立的视觉原型，不修改正式 Hero 的战斗、碰撞、伤害、体力、进度或主场景。

## Stages / 阶段

### A — Atlas and part data / 图集与部件数据

- `scripts/debug/hero_atlas_inspector.gd` supports zoom and drag-selection of atlas regions.
- `scripts/character/character_part_data.gd` stores name, atlas rectangle, anchor offset, drawing offset, scale, rotation, z-index, and enabled state.
- `scripts/character/character_atlas_texture_factory.gd` wraps a selected rectangle as an `AtlasTexture` at runtime.
- Keep third-party atlas files local. Expected path: `res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png`.

图集原文件只放在本地。通过检查器拖框确定区域，再创建 CharacterPartData 资源记录准确坐标。

### B — Static rig / 静态拼装骨架

Scene: `res://scenes/characters/customizable_character.tscn`

The scene has separate body, clothes, head, face, hair-back, hair-front, accessory, arm, and leg nodes. All slots use the same atlas. Default crop rectangles are deliberately hidden placeholders; they are not claimed to match the supplied art. Configure actual region rectangles through CharacterPartData before expecting a visible textured character.

场景包含独立身体、服装、头部、表情、前后发、配件、手臂和腿部节点。默认裁切区域是隐藏的占位值，并非对素材的猜测性匹配。必须先配置实际的 CharacterPartData 区域。

### C — Live customization UI / 实时换装 UI

Scene: `res://scenes/ui/character_customization_ui.tscn`

Assign arrays on the CustomizableCharacter instance:
- `hair_options`
- `clothes_options`
- `face_options`
- `accessory_options`

Each array element is a CharacterPartData resource. The OptionButtons are populated from each resource's display_name. Hair is shown in front/back layers using the same crop in this prototype; for complex hairstyles, extend CharacterPartData with separate back/front regions or use a compound hairstyle resource.

将 CharacterPartData 资源加入角色实例的各个数组后，下拉菜单会自动生成选项。此原型用同一发型裁切填充前后层；复杂发型应扩展为独立的前发、后发区域。

### D — Skeleton2D and keyframe animation / 骨骼与关键帧动画

The rig uses Skeleton2D and Bone2D anchors. `scripts/character/character_animation_setup.gd` creates sample AnimationPlayer clips: idle, run, attack, and dodge. These are presentation-only demonstrations and do not control combat.

场景预置 Skeleton2D/Bone2D 层级，并创建 idle、run、attack、dodge 关键帧动画示例。它们只控制视觉，不负责战斗。


## Configure the first part resources / 配置第一批部件资源

1. Open `scenes/debug/character_customization_preview.tscn`.
2. Select the `CustomizableCharacter` instance.
3. In Inspector, expand `hair_options` and set its size to 1 (or more).
4. For each element choose **New CharacterPartData**. Expand the resource and set:
   - `display_name`: e.g. `Short Hair`
   - `atlas_region`: the exact `Rect2(x, y, width, height)` copied from the atlas inspector Output
   - `local_position`: anchor adjustment relative to the head bone
   - `local_offset`: small pixel-level drawing correction only
   - `z_index`: layer ordering
5. Repeat for `clothes_options`, `face_options`, and `accessory_options`.
6. If a part will be reused across characters, save the resource as a `.tres` file under `res://resources/character_parts/` and assign that resource to the array.

建议先只配置一个头发、一个衣服、一个表情和一个配件，确认每个裁切矩形没有带入相邻素材后，再增加选项。不要使用大幅 offset 来补偿错误的裁切边界。

## What is intentionally not auto-guessed / 不自动猜测的内容

The atlas inspector can help select rectangular bounds, but it cannot infer semantic identity, matching character sets, or a correct bone pivot automatically. The project deliberately does not include guessed default crop coordinates or the third-party image. Correct art alignment depends on the local atlas and measured part regions.

图集检查器能辅助选择矩形边界，但无法自动判断素材语义、同一角色的匹配套装或正确的骨骼枢轴。因此项目不伪造默认裁切坐标，也不提交第三方图片。最终对齐需要依据本地素材校准。

## Local test / 本地测试

1. Pull `development`.
2. Keep the third-party atlas at `res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png`; do not commit it.
3. Open `res://scenes/debug/character_customization_preview.tscn` and press **F6**.
4. The preview should open without affecting the boot scene. Press **1** idle, **2** run, **3** attack, **4** dodge.
5. To validate live clothing changes, select the `CustomizableCharacter` node in the preview scene, add CharacterPartData resources to its exported arrays, and set each region from the atlas inspector's drag-selection output.
6. Check Output for parser/runtime errors. Empty arrays are expected to leave OptionButtons disabled until part resources are configured.

## Validation boundary / 验证边界

Source files have been committed and read back from GitHub. The connected session cannot run the user's Godot 4.6.1 editor, so local F6 runtime acceptance is still required. The actual third-party atlas is not committed, and this implementation intentionally does not fabricate crop coordinates.

源码已提交并通过 GitHub 回读；当前会话不能运行用户本地 Godot 4.6.1，因此仍需本地 F6 验收。第三方图集未提交，代码没有伪造素材坐标。
