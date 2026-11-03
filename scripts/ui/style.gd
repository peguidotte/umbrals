extends RefCounted
## Single presentation root. Both native Theme and custom drawing consume this Resource.
const Definition = preload("res://scripts/catalog/visual_style.gd")
const Catalog = preload("res://scripts/catalog/presentation_catalog.gd")
static var current: Definition = Catalog.STYLE
