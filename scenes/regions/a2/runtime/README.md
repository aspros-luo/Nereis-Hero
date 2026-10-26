# A2 Runtime Room Wrappers

Target home for playable room wrappers currently located in `scenes/rooms/a2_fog_forest/runtime/`.

A wrapper owns the shared Hero, camera, HUD, narrative layer, room boundaries, and respawn/transition orchestration. It should instance authored terrain rather than recreate terrain or fixed exits in code.

The wrappers are not moved yet: first migrate their scene references and authored exit nodes together to avoid breaking saved room paths and scene loading.
