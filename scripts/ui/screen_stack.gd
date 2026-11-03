class_name UmbralScreenStack
extends RefCounted
## Only the top screen owns input. Gameplay does not rely on a collection of modal booleans.
const Ids = preload("res://scripts/domain/ids.gd")
signal changed
var entries: Array[String] = [Ids.MENU]

func top() -> String:
	return entries[-1]

func root() -> String:
	return entries[0]

func reset(screen: String) -> void:
	assert(screen in Ids.SCREENS, "Unknown screen ID")
	entries.assign([screen])
	changed.emit()

func push(screen: String) -> void:
	assert(screen in Ids.SCREENS, "Unknown screen ID")
	if top() == screen: return
	entries.append(screen)
	changed.emit()

func pop() -> bool:
	if entries.size() <= 1: return false
	entries.pop_back()
	changed.emit()
	return true
