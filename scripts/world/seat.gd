class_name Seat
extends Node3D
## Sitzmöbel (Spielkonzept 3.1, entschieden 2026-10-23): Sofas, Bänke, Stühle, Bettkanten und Toiletten haben feste
## Plätze, auf die sich der Spieler mit [E] setzt (Player.sit_down). Jeder Platz ist ein Marker3D am Boden unter der
## Sitzmitte, lokal −Z = Blickrichtung. Hängt unter dem Möbelkörper; der trägt Meta „interactable“ → dieser Seat
## (Betten bleiben Versteck – HideSpot fragt seinen Seat selbst).

## Augen über der Sitzfläche
const EYE_ABOVE := 0.72
## So breit ist ein Platz auf Sofa, Bank und Bettkante
const SPOT_WIDTH := 0.6
## Katze, Puppe oder Gast so nah am Platz (waagerecht) → besetzt
const BLOCK_RANGE := 0.35

var top := 0.45            ## Sitzhöhe über dem Boden
var stand_out := 0.6       ## so weit vor dem Platz steht man auf
var prompt := "Hinsetzen [E]"
var kind := ""             ## sofa, bank, stuhl, bett, klo – für --sitzen
var spots: Array[Marker3D] = []


## Sitzreihe am Möbel `body`: `base` = Boden unter der Sitzmitte (lokal zu body), `forward` = Blickrichtung,
## `length` = nutzbare Länge der Sitzfläche quer dazu – je SPOT_WIDTH ein Platz, mindestens einer.
static func attach(body: Node3D, p_kind: String, p_top: float, base: Vector3, forward: Vector3, length: float,
		p_stand_out: float) -> Seat:
	var seat := Seat.new()
	seat.kind = p_kind
	seat.top = p_top
	seat.stand_out = p_stand_out
	body.add_child(seat)
	seat.add_to_group("seats")
	var along := Vector3.UP.cross(forward).normalized()
	var n := maxi(1, floori(length / SPOT_WIDTH + 0.001))
	for i in n:
		var m := Marker3D.new()
		m.position = base + along * ((i + 0.5) * length / n - length / 2.0)
		m.basis = Basis.looking_at(forward)
		seat.add_child(m)
		seat.spots.append(m)
	if not body.has_meta("interactable"):
		body.set_meta("interactable", seat)
	return seat


func get_prompt(player: Player) -> String:
	if player.seat == self:
		return ""
	return prompt if free_spot(player.aim_point()) else "Besetzt"


func interact(player: Player) -> void:
	if player.seat == self:
		return
	var spot := free_spot(player.aim_point())
	if spot:
		player.sit_down(self, spot)


## Freier Platz, der `near` am nächsten liegt (null = alle besetzt).
func free_spot(near: Vector3) -> Marker3D:
	var best: Marker3D = null
	for m in spots:
		if _taken(m):
			continue
		if best == null or m.global_position.distance_to(near) < best.global_position.distance_to(near):
			best = m
	return best


## Ist der Platz frei – außer für `except` (ein Gast auf dem Weg dorthin, Spielkonzept 3.1)?
func is_free(m: Marker3D, except: Node = null) -> bool:
	return not _taken(m, except)


## Sitzt oder liegt dort schon jemand – Gast, Katze, die Puppe, der sitzende Spieler?
func _taken(m: Marker3D, except: Node = null) -> bool:
	var at := m.global_position
	var others: Array = get_tree().get_nodes_in_group("cats") + get_tree().get_nodes_in_group("jury_doll")
	if Game.social:
		others += Game.social.living_guests().filter(func(g: Guest) -> bool: return g.hiding == null)   # nicht unterm Bett
	if Game.player and Game.player.seat:
		others.append(Game.player)
	for node in others:
		if node == except:
			continue
		var p := (node as Node3D).global_position
		if Vector2(p.x - at.x, p.z - at.z).length() < BLOCK_RANGE and absf(p.y - at.y) < 1.2:
			return true
	return false
