extends "res://tests/ui_flow_test.gd"
const CardCatalog = preload("res://scripts/assets/card_visual_catalog.gd")

func _before_run() -> void:
	CardCatalog.preview_enabled = true
	expect(CardCatalog.active() != null, "Run the real keyboard/controller/stack contracts with the new card renderer")
