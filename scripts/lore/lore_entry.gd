extends Resource
class_name LoreEntry

## Fragmented narrative data used by weapons, items, regions and characters.

@export var id: String
@export var category: String
@export var title: String
@export_multiline var short_description: String
@export_multiline var full_description: String
@export var related_entities: Array[String] = []
@export var unlock_condition: String
@export var hidden_flags: Array[String] = []
