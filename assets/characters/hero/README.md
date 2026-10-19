# Hero Character Art Pipeline

## Source priority

The committed texture assets are the primary development source:

- `tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png` — preferred inspection/runtime candidate.
- `tex1_512x512_544f6621d3d7aae2_f32cd14fd4d9e265_9.dds` — alternate source to compare for dimensions and visual/content equivalence.
- `153143.png` — reference image only. It must not become the animation frame source or substitute for the texture atlas.

## Current state

The current Hero skeleton controller still draws a temporary line-art character. The atlas inspector and texture lab help inspect the source texture, but they do not yet constitute a texture-backed character rig.

The shared helpers are available:

- `CharacterPartData` describes a validated atlas rectangle and its local transform.
- `CharacterAtlasTextureFactory` creates an `AtlasTexture` and applies it to a `Sprite2D`, rejecting regions that fall outside the source texture.

No semantic atlas regions have been approved yet. Do not label arbitrary rectangles as head, torso, arm, or leg without inspecting the actual texture and confirming their intended meaning.

## Migration acceptance

The texture-backed rig is considered ready only when all of these are true:

1. The PNG and DDS sources have been compared and the chosen source is documented.
2. Exact regions and pivots are identified from the actual texture/source data.
3. Real atlas-backed `Sprite2D` parts are attached to the existing `Bone2D` hierarchy.
4. An isolated Godot 4.6.1 scene visibly validates idle, movement, and an attack without placeholder line art standing in for the textured body.
5. Runtime validation results are recorded honestly; a successful script edit alone is not visual acceptance.

Gameplay code must remain independent of the visual implementation.
