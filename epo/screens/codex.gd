extends Control
## Encyclopédie : toutes les unités, les grades, les livres et le glossaire.

const GLOSSARY := [
	["Logistique", "Tout ce qui permet à une armée de vivre et de combattre : transport, vivres, munitions, carburant, soins, réparations. « Les amateurs parlent de tactique, les professionnels de logistique », dit un adage militaire."],
	["Stratégie", "L'art de conduire la guerre dans son ensemble pour atteindre un but politique : où, quand et pourquoi combattre."],
	["Tactique", "L'art de mener le combat lui-même : disposer ses troupes, choisir le terrain, combiner les armes."],
	["Opératif (niveau)", "Le niveau intermédiaire entre stratégie et tactique : la conduite d'une campagne, d'une suite de batailles."],
	["Interarmes", "Combiner infanterie, blindés, artillerie, génie, aviation… pour que les forces de chacun couvrent les faiblesses des autres."],
	["Double enveloppement", "Manœuvre qui encercle l'ennemi par les deux ailes, comme Hannibal à Cannes en 216 av. J.-C."],
	["Levée en masse", "Mobilisation de toute la nation pour la guerre, décrétée en France en août 1793."],
	["Conscription", "Service militaire obligatoire. En France, elle est instituée par la loi Jourdan (1798) et suspendue en 1997."],
	["Guerre d'usure", "Stratégie qui cherche à épuiser l'adversaire (hommes, matériel, moral) plutôt qu'à le battre d'un coup, comme à Verdun."],
	["Dissuasion", "Empêcher l'adversaire d'attaquer en le menaçant de représailles inacceptables, notamment nucléaires."],
	["Guérilla", "« Petite guerre » : un adversaire faible évite la bataille rangée, harcèle, se cache dans la population ou le terrain."],
	["Contre-insurrection", "Ensemble des méthodes militaires, politiques et sociales pour lutter contre une guérilla en gagnant le soutien de la population."],
	["Cartouche intermédiaire", "Munition plus faible qu'une cartouche de fusil classique mais plus forte qu'une cartouche de pistolet : elle permet le tir en rafale contrôlable (StG 44, AK-47)."],
	["Fusil d'assaut", "Arme individuelle tirant une cartouche intermédiaire, au coup par coup ou en rafale. Le StG 44 allemand puis l'AK-47 popularisent le concept."],
	["Emprunt de gaz", "Système d'arme automatique : une partie des gaz de la poudre est prélevée dans le canon pour actionner le mécanisme de rechargement."],
	["Charge creuse", "Explosif en forme de cône qui projette un jet de métal capable de percer un blindage épais."],
	["Économie de guerre", "Réorganisation de l'industrie, de l'agriculture et des finances d'un pays pour soutenir l'effort militaire."],
	["Propagande", "Information orientée pour influencer l'opinion : maintenir le moral de son camp et affaiblir celui de l'ennemi."],
	["Noria", "À Verdun, rotation régulière des divisions pour qu'aucune ne s'épuise complètement au front."],
	["Brouillard de la guerre", "Expression liée à Clausewitz : en guerre, l'information est toujours incomplète, incertaine ou trompeuse."],
	["Friction", "Pour Clausewitz, tout ce qui fait qu'à la guerre « même la chose la plus simple est difficile » : fatigue, météo, erreurs, hasard."],
]

var _content: VBoxContainer
var _tab := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	add_child(UI.map_background())
	add_child(UI.top_bar("Encyclopédie", func(): Nav.goto("hub" if Game.has_profile() else "title")))
	var v := UI.vbox(12)
	var m := UI.margin(v, 50, 90, 50, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var tabs := UI.hbox(8)
	v.add_child(tabs)
	var names := ["Unités", "Grades", "Livres", "Glossaire"]
	for i in names.size():
		tabs.add_child(UI.button(names[i], func(): _show(i), 20))
	_content = UI.vbox(8)
	v.add_child(UI.scroll(_content))
	_show(0)


func _show(i: int) -> void:
	_tab = i
	for c in _content.get_children():
		c.queue_free()
	match i:
		0:
			for e in Content.eras:
				_content.add_child(UI.label("%02d · %s" % [int(e.num), String(e.name).to_upper()], 22, Color(e.color).lightened(0.3), UI.font_ui_bold))
				for u in Content.units_for_era(e.id):
					var a: Dictionary = u.attack
					var txt := "[b]%s[/b] — ◉ %d · PV %d · vitesse %s m/s · %s\n[color=#a8a48c]%s[/color]" % [u.name, int(u.cost), int(u.hp), UI.dec(float(u.speed)), "corps à corps" if a.kind == "melee" else "portée %d m" % int(a.get("range", 0)), u.get("desc", "")]
					var p := UI.panel(10, Color(UI.PANEL, 0.9))
					p.add_child(UI.rich(txt, false, 17))
					_content.add_child(p)
		1:
			_content.add_child(UI.wrap_label("Les grades de l'armée française, que tu gagnes avec l'XP. En vrai, on ne devient pas maréchal en jouant : c'est une « dignité » accordée à de rares généraux victorieux.", 18, UI.MUTED))
			for r in Game.RANKS:
				var cur: bool = r[0] == Game.rank_name()
				_content.add_child(UI.label("%s%s — %d XP" % ["▶ " if cur else "", r[0], r[1]], 20, UI.GOLD if cur else UI.TEXT, UI.font_ui_bold if cur else null))
		2:
			for e in Content.eras:
				var b: Dictionary = Content.history(e.id).get("book", {})
				if b.is_empty():
					continue
				var p := UI.panel(12, Color(UI.PANEL, 0.9))
				p.add_child(UI.rich("[b]%s[/b] — %s (%s)\n[color=#a8a48c]%s · %s[/color]" % [b.title, b.author, b.year, e.name, b.get("why", "")], false, 17))
				_content.add_child(p)
		3:
			for g in GLOSSARY:
				var p := UI.panel(10, Color(UI.PANEL, 0.9))
				p.add_child(UI.rich("[b]%s[/b] — %s" % [g[0], g[1]], false, 17))
				_content.add_child(p)
