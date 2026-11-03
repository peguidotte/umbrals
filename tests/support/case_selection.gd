extends RefCounted
## Explicit test-case dispatch; unknown filters fail rather than report an empty pass.
static var active_case: String = ""
static var executed: Array[String] = []

static func run(cases: Dictionary) -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--case")
	var selected: String = args[index + 1] if index >= 0 and index + 1 < args.size() else ""
	if index >= 0 and (selected.is_empty() or not cases.has(selected)):
		printerr("Unknown case: " + selected)
		return false
	active_case = selected
	executed.clear()
	for name in cases:
		if selected.is_empty() or selected == name:
			executed.append(name)
			cases[name].call()
	return true
