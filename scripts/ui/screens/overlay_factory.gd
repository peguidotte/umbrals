extends RefCounted
const Ids = preload("res://scripts/domain/ids.gd")
const Modal = preload("res://scripts/ui/screens/modal_view.gd")
const General = preload("res://scripts/ui/screens/overlay_view.gd")
const Settings = preload("res://scripts/ui/screens/settings_screen.gd")
const Rewards = preload("res://scripts/ui/screens/reward_screen.gd")
const Inventory = preload("res://scripts/ui/screens/inventory_screen.gd")
const Information = preload("res://scripts/ui/screens/information_screen.gd")

static func create(screen: String) -> Modal:
	match screen:
		Ids.INVENTORY: return Inventory.new()
		Ids.SETTINGS: return Settings.new()
		Ids.REWARD, Ids.REPLACEMENT: return Rewards.new()
		Ids.CODEX, Ids.INSPECT: return Information.new()
		_: return General.new()
