extends Node
## Simule les batailles avec le placement automatique pour équilibrer la difficulté.
## godot --headless --path . res://tests/runner.tscn -- balance [ids séparés par des virgules] [nombre]


func run(args: PackedStringArray) -> void:
	if not Game.has_profile():
		Game.new_profile("Simulation", "france")
	var ids: Array = []
	if args.size() > 1 and args[1] != "all":
		ids = Array(args[1].split(","))
	else:
		ids = Content.battles.map(func(b): return b.id)
	var n := int(args[2]) if args.size() > 2 else 3
	var summary := []
	for id in ids:
		var wins := 0
		var details := []
		for i in n:
			var b = Nav.goto_now("battle", {"battle": id, "nointro": true})
			await get_tree().process_frame
			b.auto_place(0)
			var spent: int = b.spent[0]
			b.start_battle()
			Engine.time_scale = 2.0
			var guard := 0
			while not b.result_shown and guard < 200000:
				guard += 1
				await get_tree().process_frame
			var won: bool = b._alive(1) == 0 and b._alive(0) > 0
			if won:
				wins += 1
			details.append("%s %d/%d vs %d/%d %ds (dépensé %d)" % ["V" if won else "D", b._alive(0), b.start_count[0], b._alive(1), b.start_count[1], int(b.fight_time), spent])
		var line := "%-16s victoires %d/%d  |  %s" % [id, wins, n, " ; ".join(details)]
		print("BAL ", line)
		summary.append(line)
	print("==== RÉSUMÉ ====")
	for l in summary:
		print(l)
