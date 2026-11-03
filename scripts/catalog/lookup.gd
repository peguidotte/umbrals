extends RefCounted
## Pure lookups over one authored package; returned values never alias resources.

static func form(package: Resource, id: String) -> Dictionary:
	for definition in package.forms:
		if str(definition.id) == id: return definition.duplicate(true)
	return {}

static func edges(package: Resource, id: String) -> Array:
	var result: Array = []
	for edge in package.evolutions:
		if str(edge.from) == id: result.append(edge.duplicate(true))
	return result
