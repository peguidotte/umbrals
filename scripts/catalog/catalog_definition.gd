extends Resource
const Species = preload("res://scripts/catalog/species_definition.gd")
## Explicit append-only order preserves seeded capture rolls; no filesystem discovery at runtime.
@export var species: Array[Species] = []
