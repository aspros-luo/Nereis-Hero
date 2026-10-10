# Godot 2D 骨骼迭代与验收清单 / Godot 2D Skeleton Iteration & Acceptance

参考 / Reference:
- https://docs.godotengine.org/zh-cn/4.x/tutorials/animation/2d_skeletons.html
- https://docs.godotengine.org/en/4.4/classes/class_skeleton2d.html

## 设计原则 / Design principles

- 使用 `Skeleton2D` 作为骨骼层级根节点，`Bone2D` 表达父子关节关系。
- 当前角色使用刚性分层（cutout）SVG：每个身体部件保留统一的 192x224 源画布，Sprite2D 放在骨骼局部坐标中，以关节 pivot 旋转。
- Godot 教程中 Polygon2D + 骨骼权重的网格变形适合需要弯曲的披风、肘膝护甲或布料，但不能直接套到当前整张 SVG Sprite 上。需要额外网格、顶点和权重，必须单独制作与验收。
- 不引入实验性的 IK 修改栈作为当前第一步；当前优先稳定确定性的关键帧式姿势。需要武器瞄准或脚底落点修正时，再评估 TwoBoneIK 等修改。
- Rest Pose/默认姿势必须与每个分层部件的 pivot 对齐。由于本项目在运行时创建骨骼，不应照搬仅适用于编辑器手工绑定 Polygon2D 的步骤；后续若改成场景内编辑器骨架，需在编辑器里保存并检查 rest pose。

## 已完成 / Implemented

- `scripts/player/hero_skeleton_visual.gd` 继续复用现有 Skeleton2D/Bone2D 层级。
- 攻击姿势包含起手、挥击和三种差异化的连击弧线。
- 状态变化时使用角度插值，降低 Idle/Move/Attack/Hurt 等状态之间的姿势跳变。
- 长剑与短刃仍通过武器骨骼切换纹理。
- 角色朝向翻转保留在骨架 scale 上，脚底锚点与源画布坐标保持一致。
- 未修改战斗 hitbox、伤害、耐力和冷却逻辑。

## 正反方评审 / Pro-con review

**正方 / Pro**
- 刚性分层方案便于快速迭代，成本远低于完整权重蒙皮。
- 角度插值改善状态切换的观感，且不会改变物理或战斗逻辑。
- 不增加额外骨骼插件或实验性功能，降低 Godot 4.x 版本风险。

**反方 / Con**
- 刚性部件在肘、肩、膝和腰部仍可能出现接缝；插值不能解决源素材的重叠关系错误。
- 当前姿势仍由代码曲线驱动，不是编辑器 AnimationPlayer 动画轨道；精确的逐帧打击节奏仍需下一轮打磨。
- 没有在本执行环境启动 Godot，脚本解析、资源导入与实机视觉尚未验证。

## 下一轮验收 / Acceptance checklist

- [ ] 在 Godot 4.6.1 打开项目并确认无 GDScript parse errors。
- [ ] 检查角色出现时骨骼没有偏移，站立时脚底与碰撞体对齐。
- [ ] 观察 Idle/Move/Jump/Fall/Dodge/Quick Dash/Attack/Hurt/Dead 状态转换。
- [ ] 长剑与短刃各自进行完整三段连击，确认武器不会穿过手部或身体。
- [ ] 左右转向时确认骨架镜像和武器朝向一致。
- [ ] 检查披风、头部、手臂和腿部接缝。
- [ ] 如需软质形变，再单独制作 Polygon2D 网格与权重，不把当前 Sprite2D 刚性骨骼误称为蒙皮。
- [ ] 通过上述验收后，才考虑把当前分层骨骼转为编辑器可调的 AnimationPlayer 动画轨道。

## 状态 / Status

源码变更已提交到 `feature/protagonist-system`。这不是 Godot 实机通过的声明。未完成的项目必须由本地 Godot 运行确认。
