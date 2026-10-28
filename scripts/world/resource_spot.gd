class_name ResourceSpot
extends StaticBody3D
## Stelle, an der man Material bekommt: Laubhaufen unter Bäumen, Spinnweben in
## dunklen Ecken, Kerzenvorrat in der Küche, Lakengespenster in der Wäschekiste, Lichterketten
## in der Dekokiste (Spielkonzept 5.6), alte Deko im Keller (5.7), Getränkedosen in Kühlraum und Lager und – für Geld –
## auf der Bartheke (3.2), ebenso Tassen Kaffee und Tee (3.11, 3.12). Begrenzter Vorrat, wächst langsam nach – außer in den Kisten mit starker Deko
## (regen_time 0, Spielkonzept 5.10): Die leeren sich, und Gäste nehmen aus jeder höchstens ein Stück am Spieltag.
## Mit `pool` gibt es abwechselnd verschiedene Dinge (Dekokiste, alte Deko); `kind` bestimmt nur das Aussehen.
## Brotkrumen für die Krähen (4.25): Kürbiskerne mit Zusatz „brot“ (`extra`), dazu Brett und Brotlaib.
## Spinnweben: lokale +Z zeigt von der Wand weg.

var kind: Item.Kind = Item.Kind.LEAVES
var label := ""
var uses := 3
var max_uses := 3
var regen_time := 90.0
var pool: Array = []
## Zusatz für Item.create (Brotkrumen: „brot“)
var extra := ""
## Kostet so viel Geld je Stück (0 = umsonst)
var price := 0
## Kiste ohne Nachschub: Spieltag, an dem zuletzt ein Gast etwas genommen hat (gespeichert)
var guest_day := 0
## Kerzenvorrat (Spielkonzept 5.12): wächst nicht laufend nach, sondern füllt sich morgens auf – auf halb so viele
## Stück, wie Zimmer bewohnt sind (MonsterDirector.inhabited_rooms). refill_day = Spieltag der letzten Füllung (gespeichert).
var morning_refill := false
var refill_day := 0
## Füllt sich morgens auf genau so viele Stück auf (0 = nach bewohnten Zimmern) – Eierkarton (6.13)
var morning_count := 0

var _timer := 0.0
var _visual: Node3D


func setup(p_kind: Item.Kind, p_label: String, p_max_uses: int, p_regen_time: float) -> ResourceSpot:
	kind = p_kind
	label = p_label
	max_uses = p_max_uses
	uses = p_max_uses
	regen_time = p_regen_time
	return self


## Füllt sich morgens auf statt laufend (Kerzenvorrat, 5.12); count > 0: immer auf so viele Stück (Eier, 6.13).
func refill_mornings(count: int = 0) -> ResourceSpot:
	morning_refill = true
	morning_count = count
	return self


## Zum Kaufen: jedes Stück kostet `p_price` Geld.
func for_sale(p_price: int) -> ResourceSpot:
	price = p_price
	return self


## Mit Zusatz für Item.create (Brotkrumen: „brot“).
func with_extra(p_extra: String) -> ResourceSpot:
	extra = p_extra
	return self


## Kiste mit gemischtem Inhalt: Jedes Mal etwas anderes aus `kinds`.
func with_pool(kinds: Array) -> ResourceSpot:
	pool = kinds
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("resource_spots")
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	_visual = Node3D.new()
	add_child(_visual)
	match kind:
		Item.Kind.LEAVES:
			var rng := RandomNumberGenerator.new()
			for i in 30:
				var r := rng.randf() * 0.45
				var a := rng.randf() * TAU
				var leaf := Geo.mesh(_visual, Geo.box(Vector3(0.1, 0.015, 0.07)), Mat.psx(Item.LEAF_COLORS[i % Item.LEAF_COLORS.size()]),
					Vector3(cos(a) * r, 0.02 + (0.45 - r) * 0.35 * rng.randf(), sin(a) * r))
				leaf.rotation = Vector3(rng.randf() * 0.5, rng.randf() * TAU, 0)
			Geo.add_box_shape(self, Vector3(0.9, 0.25, 0.9), Vector3(0, 0.12, 0))
		Item.Kind.COBWEB:
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.9, 0.9)
			var web := Geo.mesh(_visual, plane, Mat.cobweb(), Vector3.ZERO)
			web.rotation.x = PI / 2.0
			Geo.add_box_shape(self, Vector3(0.6, 0.6, 0.1), Vector3.ZERO)
		Item.Kind.CANDLE:
			Geo.mesh(_visual, Geo.box(Vector3(0.32, 0.08, 0.2)), Mat.psx(Color(0.4, 0.28, 0.16)), Vector3(0, 0.04, 0))
			for i in 3:
				CandleModel.build(_visual, false, false, Vector3(-0.09 + i * 0.09, 0.08, 0))
			Geo.add_box_shape(self, Vector3(0.34, 0.24, 0.22), Vector3(0, 0.12, 0))
		Item.Kind.SHEET_GHOST:
			# Wäschekiste: ein Laken hängt heraus, ein aufgemaltes Auge schaut hervor
			var sheet := Geo.mesh(_visual, Geo.box(Vector3(0.36, 0.05, 0.26)), Mat.psx(Color(0.96, 0.95, 0.9)), Vector3(0, 0.025, 0))
			sheet.rotation.y = 0.15
			Geo.mesh(_visual, Geo.sphere(0.025, 0.05, 6, 3), Mat.psx(Color(0.06, 0.05, 0.06)), Vector3(0.06, 0.05, 0.03))
			Geo.add_box_shape(self, Vector3(0.6, 0.3, 0.5), Vector3(0, 0.1, 0))
		Item.Kind.LIGHT_STRING:
			# Pappkarton mit alter Halloween-Deko, obenauf eine aufgerollte Lichterkette
			Geo.mesh(self, Geo.box(Vector3(0.5, 0.32, 0.38)), Mat.psx(Color(0.55, 0.4, 0.25)), Vector3(0, 0.16, 0))
			var wire := Mat.psx(Color(0.12, 0.22, 0.1))
			Geo.mesh(_visual, Geo.cylinder(0.13, 0.02, 10), wire, Vector3(0, 0.33, 0))
			for i in 6:
				var a := i * TAU / 6.0
				Geo.mesh(_visual, Geo.sphere(0.02, 0.04, 5, 2), Mat.psx(Item.STRING_COLORS[i % Item.STRING_COLORS.size()]), Vector3(cos(a) * 0.11, 0.35, sin(a) * 0.11))
			Geo.add_box_shape(self, Vector3(0.5, 0.38, 0.38), Vector3(0, 0.19, 0))
		Item.Kind.BROOM:
			# Holzkiste mit alter Halloween-Deko im Keller: ein Besenstiel ragt heraus, ein Totenkopf grinst
			Geo.mesh(self, Geo.box(Vector3(0.55, 0.3, 0.4)), Mat.psx(Color(0.3, 0.2, 0.12)), Vector3(0, 0.15, 0))
			var stick := Geo.mesh(_visual, Geo.cylinder(0.018, 0.9, 6), Mat.psx(Color(0.32, 0.2, 0.1)), Vector3(0.12, 0.6, 0))
			stick.rotation.z = -0.35
			var skull := Geo.mesh(_visual, Geo.sphere(0.07, 0.14, 8, 4), Mat.psx(Color(0.88, 0.84, 0.72)), Vector3(-0.12, 0.36, 0.05))
			skull.scale = Vector3(1.0, 0.95, 1.1)
			Geo.add_box_shape(self, Vector3(0.55, 0.5, 0.4), Vector3(0, 0.25, 0))
		Item.Kind.SODA_CAN:
			# Getränkekiste aus rotem Kunststoff mit Dosen darin – zum Kaufen nur ein Tablett mit einer Reihe Dosen
			var cans := 3 if price > 0 else 6
			if price > 0:
				Geo.mesh(self, Geo.box(Vector3(0.3, 0.01, 0.12)), Mat.psx(Color(0.55, 0.5, 0.45)), Vector3(0, 0.005, 0))
			else:
				var crate := Mat.psx(Color(0.6, 0.1, 0.08))
				Geo.mesh(self, Geo.box(Vector3(0.4, 0.03, 0.27)), crate, Vector3(0, 0.015, 0))
				for side in [-1.0, 1.0]:
					Geo.mesh(self, Geo.box(Vector3(0.4, 0.1, 0.02)), crate, Vector3(0, 0.08, side * 0.125))
					Geo.mesh(self, Geo.box(Vector3(0.02, 0.1, 0.27)), crate, Vector3(side * 0.19, 0.08, 0))
			var flavors: Array = Item.SODA_COLORS.keys()
			for i in cans:
				var at := Vector3(-0.1 + i * 0.1, 0.0, 0.0) if price > 0 else Vector3(-0.12 + (i % 3) * 0.12, 0.0, -0.06 + floori(i / 3.0) * 0.12)
				Geo.mesh(_visual, Geo.cylinder(0.033, 0.11, 8), Mat.psx(Item.SODA_COLORS[flavors[i % flavors.size()]]), at + Vector3(0, 0.065, 0))
				Geo.mesh(_visual, Geo.cylinder(0.028, 0.012, 8), Mat.psx(Color(0.75, 0.76, 0.78)), at + Vector3(0, 0.126, 0))
			Geo.add_box_shape(self, Vector3(0.4, 0.14, 0.27) if price == 0 else Vector3(0.3, 0.14, 0.12), Vector3(0, 0.07, 0))
		Item.Kind.EGG:
			# Eierkarton aus grauer Pappe (6.13): zwei Reihen Mulden, so viele Eier darin, wie noch da sind (_update_visual)
			var pulp := Mat.psx(Color(0.62, 0.6, 0.55))
			Geo.mesh(self, Geo.box(Vector3(0.3, 0.035, 0.11)), pulp, Vector3(0, 0.0175, 0))
			for i in maxi(max_uses, morning_count):
				Item.build_egg(_visual, Vector3(-0.12 + (i % 5) * 0.06, 0.045, -0.027 + floori(i / 5.0) * 0.054))
			Geo.add_box_shape(self, Vector3(0.3, 0.08, 0.11), Vector3(0, 0.04, 0))
		Item.Kind.COFFEE, Item.Kind.TEA:
			# Tablett mit drei dampfenden Tassen auf der Bartheke (3.11, Tee 3.12)
			Geo.mesh(self, Geo.box(Vector3(0.32, 0.01, 0.13)), Mat.psx(Color(0.55, 0.5, 0.45)), Vector3(0, 0.005, 0))
			for i in 3:
				Item.build_cup(_visual, kind == Item.Kind.TEA, Vector3(-0.1 + i * 0.1, 0.01, 0.0), [-1.3, -1.75, -1.5][i])   # Henkel quer, zu den Gästen
			Geo.add_box_shape(self, Vector3(0.32, 0.1, 0.13), Vector3(0, 0.05, 0))
		Item.Kind.PUMPKIN_SEEDS:
			# Brotkrumen (4.25): Brett mit dem Rest eines Brotlaibs, Krumen daneben
			Geo.mesh(self, Geo.box(Vector3(0.34, 0.02, 0.2)), Mat.psx(Color(0.55, 0.38, 0.22)), Vector3(0, 0.01, 0))
			var crust := Mat.psx(Color(0.5, 0.3, 0.13))
			var loaf := Geo.mesh(_visual, Geo.sphere(0.07, 0.1, 10, 5), crust, Vector3(-0.05, 0.055, 0))
			loaf.scale = Vector3(1.4, 0.75, 1.0)
			var cut := Geo.mesh(_visual, Geo.cylinder(0.062, 0.006, 10), Mat.psx(Color(0.9, 0.82, 0.62)), Vector3(0.048, 0.055, 0))
			cut.rotation.z = PI / 2.0   # Anschnitt
			var rng := RandomNumberGenerator.new()
			rng.seed = 77
			for i in 10:
				var crumb := Geo.mesh(_visual, Geo.box(Vector3.ONE * rng.randf_range(0.008, 0.015)), crust if i % 3 == 0 else Mat.psx(Color(0.88, 0.8, 0.62)),
					Vector3(rng.randf_range(0.07, 0.15), 0.026, rng.randf_range(-0.07, 0.07)))
				crumb.rotation.y = rng.randf() * TAU
			Geo.add_box_shape(self, Vector3(0.34, 0.12, 0.2), Vector3(0, 0.06, 0))
	_update_visual()


func _process(delta: float) -> void:
	if morning_refill:
		_refill()
		return
	if uses >= max_uses or regen_time <= 0.0:
		return
	_timer += delta
	if _timer >= regen_time:
		_timer = 0.0
		uses += 1
		_update_visual()


## Schneller nachwachsen (Spinnen in der Nähe von Spinnweben, Spielkonzept 4.23): so viele Sekunden zusätzlich.
func grow(seconds: float) -> void:
	if uses < max_uses and regen_time > 0.0:
		_timer += seconds


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): so viel wächst nach, wie in dt passt.
func skip_time(dt: float) -> void:
	if morning_refill or uses >= max_uses or regen_time <= 0.0:
		return   # der Kerzenvorrat füllt sich im nächsten Bild auf, wenn der Morgen da ist
	_timer += dt
	var before := uses
	while _timer >= regen_time and uses < max_uses:
		_timer -= regen_time
		uses += 1
	if uses != before:
		_update_visual()


## Morgens (ab 6 Uhr, beim ersten Mal sofort): auf halb so viele Stück, wie Zimmer bewohnt sind – was noch da ist,
## bleibt. Nach Halloween bleibt der Tag beim 31. stehen, dann kommt nichts mehr.
func _refill() -> void:
	var today := Calendar.today()
	if today == refill_day or (refill_day != 0 and Calendar.hour_of(Calendar._elapsed()) < Calendar.PHASE_START[0]):
		return
	refill_day = today
	var target := max_uses
	if morning_count > 0:
		target = morning_count
	elif Game.director:
		target = ceili(Game.director.inhabited_rooms().size() / 2.0)
	max_uses = maxi(target, 1)
	if uses < target:
		uses = target
		_update_visual()
	if Game.tracing:
		print("[Vorrat] %s am %d.: %d Stück" % [label, today, uses])


## Kiste mit starker Deko, die nicht nachwächst (5.10)?
func runs_out() -> bool:
	return regen_time <= 0.0


## Darf ein Gast jetzt etwas nehmen? Aus einer Kiste ohne Nachschub nur ein Stück am Spieltag.
func guest_can_take() -> bool:
	return uses > 0 and (not runs_out() or guest_day != Calendar.today())


## Ein Stück für den Spieler, ohne Gegenstand (er bekommt ihn geteilt, DecoSearch). false = leer.
func consume() -> bool:
	if uses <= 0:
		return false
	uses -= 1
	_update_visual()
	return true


## Ein Gast nimmt ein Stück (den Gegenstand baut er selbst, Guest.stock_item) – zählt das Tageslimit der Kisten.
## false = leer oder heute schon genommen.
func guest_consume() -> bool:
	if not guest_can_take():
		return false
	if runs_out():
		guest_day = Calendar.today()
	uses -= 1
	_update_visual()
	return true


## Gibt ein neues Item zurück (noch nicht in der Szene) oder null, wenn leer.
func take() -> Item:
	if uses <= 0:
		return null
	uses -= 1
	_update_visual()
	return Item.create(pool.pick_random() if not pool.is_empty() else kind, extra)


func get_prompt(player: Player) -> String:
	if uses <= 0:
		return ("%s – leer" if runs_out() else "%s – gerade nichts zu holen") % label
	if not player.can_take(kind):
		return "Hände voll"
	if price > 0:
		return "%s kaufen – %d Geld [E]" % [label, price] if Game.money >= price else "%s – %d Geld, so viel hast du nicht" % [label, price]
	return "%s nehmen [E]" % label


## Aktions-Symbol über dem Hinweis (IconArt): Kaffee und Tee an der Bar.
func get_icon(_player: Player) -> String:
	return IconArt.drink_icon(kind)


func interact(player: Player) -> void:
	if uses <= 0 or not player.can_take(kind) or Game.money < price:
		return
	Game.money -= price
	player.receive_item(take())


func _update_visual() -> void:
	_visual.visible = uses > 0
	if kind == Item.Kind.EGG:
		for i in _visual.get_child_count():
			(_visual.get_child(i) as Node3D).visible = i < uses
	if kind == Item.Kind.LEAVES:
		_visual.scale = Vector3.ONE * lerpf(0.5, 1.0, float(uses) / max_uses)
