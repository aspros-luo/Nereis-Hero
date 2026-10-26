# A2 Authored Room Terrain

Target home for the authored terrain scenes currently located in `scenes/rooms/a2_fog_forest/`.

Each room terrain scene owns its static geometry, collision, visual layers, and `RoomMarkers`. Fixed doors and drop triggers should become child instances of their corresponding markers (or explicitly positioned scene nodes) so their placement is inspectable in the editor.

Do not duplicate room terrain here while the legacy paths remain active. Move the six scenes only as a coordinated change with every dependent `ExtResource`, preload, room-scene map, and documentation reference updated.
