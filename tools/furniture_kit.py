# Gemeinsamer Bausatz für Möbel im Holz der Vertäfelung (Mat.hotel_wood, Spielkonzept 9.2) – Kleiderschrank
# (tools/build_wardrobe.py), später die Kommode im selben Look. Für Blender 4.3, wird von den Bauskripten importiert.
#
# Wie bei der Zimmertür (tools/build_room_door.py): Jedes Holzteil trägt zwei UV-Sätze – „UVMap“ in Metern für das
# Holzfoto (Faser je Stück wie beim Schreiner, jedes Stück mit eigenem Versatz) und „atlas“ für gebackene Karten.
# Neu gegenüber der Tür: Neben der Verschattung (AO) wird auch die Normale in den Atlas gebacken (Objektraum,
# umgerechnet auf Godot-Achsen) – darin malt paint_details feine Formen, die nicht modelliert sind (Furchen, Lamellen):
# Normale und Verschattung je Pixel aus einer Formel. Im Spiel liest psx_photo die Normale über UV2 (detail_tex).
#
# Flächen tragen eine Gruppe (Ganzzahl): 0 gewöhnlich, sonst ein Muster bzw. eine andere Dichte im Atlas
# (atlas_uv: Faktor je Gruppe). Flächen einer Gruppe ≠ 0 werden von ihren Nachbarn getrennt (eigene Insel).
import bpy, bmesh, math, random
import numpy as np
from mathutils import Vector

SHARP = math.radians(35)


## Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück.
def B(x, y, z):
	return Vector((x, -z, y))


def G(v):
	return Vector((v.x, v.z, -v.y))


## Punkte (Abstand, Höhe) auf einem Kreisbogen um (cx, cy) mit Radius r von a0 bis a1 Grad, ohne den Startpunkt
def arc(cx, cy, r, a0, a1, steps):
	out = []
	for i in range(1, steps + 1):
		a = math.radians(a0 + (a1 - a0) * i / steps)
		out.append((round(cx + r * math.cos(a), 6), round(cy + r * math.sin(a), 6)))
	return out


class Part:
	"""Ein Mesh im Bau. face() legt Vierecke in Godot-Koordinaten an, mit Holz-UVs: u entlang der Faser (Achse
	„x“, „y“ oder „z“), v = Summe der beiden anderen Koordinaten (wie bei der Tür), dazu der Versatz des Stücks."""

	def __init__(self, name, grain_shift=2.0):
		self.name = name
		self.bm = bmesh.new()
		self.uv = self.bm.loops.layers.uv.new("UVMap")
		self.group = self.bm.faces.layers.int.new("group")
		self.offsets = {}
		self.shift = grain_shift

	def face(self, pts, normal, piece, axis, group=0):
		vs = [self.bm.verts.new(B(*p)) for p in pts]
		f = self.bm.faces.new(vs)
		f.normal_update()
		if f.normal.dot(B(*normal)) < 0:
			f.normal_flip()
		if piece not in self.offsets:
			self.offsets[piece] = (random.random() * self.shift, random.random() * self.shift)
		ou, ov = self.offsets[piece]
		k = "xyz".index(axis)
		for loop in f.loops:
			p = G(loop.vert.co)
			u = p[k]
			v = sum(p[i] for i in range(3) if i != k)
			loop[self.uv].uv = (u + ou, v + ov)
		f[self.group] = group
		return f

	## Fertig: gleiche Ecken verschmelzen, Gruppen ≠ 0 abtrennen, weich bis auf Kanten über SHARP
	def finish(self, location=(0, 0, 0)):
		bm = self.bm
		bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
		cut = [e for e in bm.edges if len(e.link_faces) == 2
			and e.link_faces[0][self.group] != e.link_faces[1][self.group]
			and (e.link_faces[0][self.group] != 0 or e.link_faces[1][self.group] != 0)]
		bmesh.ops.split_edges(bm, edges=cut)
		bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
		bm.normal_update()
		for f in bm.faces:
			f.smooth = True
		for e in bm.edges:
			if len(e.link_faces) == 2 and e.link_faces[0].normal.angle(e.link_faces[1].normal) > SHARP:
				e.smooth = False
		me = bpy.data.meshes.new(self.name)
		bm.to_mesh(me)
		bm.free()
		ob = bpy.data.objects.new(self.name, me)
		ob.location = B(*location)
		bpy.context.scene.collection.objects.link(ob)
		return ob


## Rotationskörper (Beschläge) um die Achse axis durch center (Godot): profile als (Radius, Abstand entlang der
## Achse); Radius 0 = Pol. Gibt die Flächen zurück.
def lathe(bm, center, axis, profile, segs=12):
	axis = Vector(axis).normalized()
	ref = Vector((0, 1, 0)) if abs(axis.y) < 0.9 else Vector((1, 0, 0))
	u = axis.cross(ref).normalized()
	w = axis.cross(u)
	rings = []
	for r, t in profile:
		c = Vector(center) + axis * t
		if r == 0:
			rings.append([bm.verts.new(B(*c))])
		else:
			rings.append([bm.verts.new(B(*(c + (u * math.cos(a) + w * math.sin(a)) * r)))
				for a in (2 * math.pi * s / segs for s in range(segs))])
	faces = []
	for a, b in zip(rings, rings[1:]):
		if len(a) == 1 and len(b) == 1:
			continue
		for s in range(segs):
			t = (s + 1) % segs
			if len(a) == 1:
				faces.append(bm.faces.new((a[0], b[s], b[t])))
			elif len(b) == 1:
				faces.append(bm.faces.new((a[s], b[0], a[t])))
			else:
				faces.append(bm.faces.new((a[s], b[s], b[t], a[t])))
	if len(rings[0]) > 1:
		faces.append(bm.faces.new(list(reversed(rings[0]))))
	if len(rings[-1]) > 1:
		faces.append(bm.faces.new(rings[-1]))
	bmesh.ops.recalc_face_normals(bm, faces=faces)
	return faces


def finish_plain(bm, name, location=(0, 0, 0)):
	bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
	bm.normal_update()
	for f in bm.faces:
		f.smooth = True
	for e in bm.edges:
		if len(e.link_faces) == 2 and e.link_faces[0].normal.angle(e.link_faces[1].normal) > SHARP:
			e.smooth = False
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	ob = bpy.data.objects.new(name, me)
	ob.location = B(*location)
	bpy.context.scene.collection.objects.link(ob)
	return ob


# --- Atlas -------------------------------------------------------------------------------------------------------
## Gemeinsamer Atlas „atlas“ für obs. scales: Faktor je Gruppe (Furchen dichter, Rückwand gröber) – die Flächen
## einer Gruppe ≠ 0 sind eigene Inseln (Part.finish), werden um ihre Mitte gestreckt, dann wird alles gepackt.
def atlas_uv(obs, margin, scales=None):
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
		if "atlas" not in ob.data.uv_layers:
			ob.data.uv_layers.new(name="atlas")
		ob.data.uv_layers.active = ob.data.uv_layers["atlas"]
		ob.select_set(True)
	bpy.context.view_layer.objects.active = obs[0]
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=margin, area_weight=0.0, scale_to_bounds=False)
	bpy.ops.object.mode_set(mode='OBJECT')
	if scales:
		for ob in obs:
			me = ob.data
			if "group" not in me.attributes:
				continue
			groups = me.attributes["group"].data
			uvs = me.uv_layers["atlas"].data
			for p in me.polygons:
				k = scales.get(groups[p.index].value)
				if not k:
					continue
				idx = list(p.loop_indices)
				c = sum((Vector(uvs[i].uv) for i in idx), Vector((0, 0))) / len(idx)
				for i in idx:
					uvs[i].uv = c + (Vector(uvs[i].uv) - c) * k
	# Packen nimmt nur ausgewählte Inseln – mit synchroner Auswahl sind das alle ausgewählten Flächen
	bpy.context.scene.tool_settings.use_uv_select_sync = True
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.pack_islands(rotate=True, margin=margin)
	bpy.ops.object.mode_set(mode='OBJECT')
	for ob in obs:
		ob.data.uv_layers["atlas"].active_render = True


# --- Backen ------------------------------------------------------------------------------------------------------
def setup_cycles():
	sc = bpy.context.scene
	sc.render.engine = 'CYCLES'
	sc.cycles.device = 'CPU'
	sc.world = bpy.data.worlds.new("bake")
	sc.render.bake.margin = 8
	sc.render.bake.use_clear = True
	return sc


def new_image(name, size, color_data, float_buffer=False):
	img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=float_buffer)
	img.colorspace_settings.name = 'sRGB' if color_data else 'Non-Color'
	return img


## Material zum Backen: Zielbild auf dem Atlas-UV-Satz; color = Grundfarbe für den Farbbake
def bake_material(name, color=None):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nt = mat.node_tree
	if color is not None:
		nt.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
	node = nt.nodes.new("ShaderNodeTexImage")
	uv = nt.nodes.new("ShaderNodeUVMap")
	uv.uv_map = "atlas"
	nt.links.new(uv.outputs["UV"], node.inputs["Vector"])
	node.name = "bake_target"
	nt.nodes.active = node
	return mat


## Messing mit fleckigem Anlauf (Rauschen in Objektkoordinaten), wie die Beschläge der Zimmertür
def brass_material():
	mat = bake_material("brass_src")
	nt = mat.node_tree
	coord = nt.nodes.new("ShaderNodeTexCoord")
	noise = nt.nodes.new("ShaderNodeTexNoise")
	noise.inputs["Scale"].default_value = 35.0
	noise.inputs["Detail"].default_value = 3.0
	nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
	ramp = nt.nodes.new("ShaderNodeValToRGB")
	ramp.color_ramp.elements[0].position = 0.3
	ramp.color_ramp.elements[0].color = (0.6, 0.43, 0.18, 1)
	ramp.color_ramp.elements[1].position = 0.7
	ramp.color_ramp.elements[1].color = (0.8, 0.6, 0.29, 1)
	nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
	nt.links.new(ramp.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
	return mat


def bake(obs, kind, img, samples, **kw):
	sc = bpy.context.scene
	for ob in obs:
		ob.data.uv_layers.active = ob.data.uv_layers["atlas"]
		for slot in ob.material_slots:
			nt = slot.material.node_tree
			n = nt.nodes["bake_target"]
			n.image = img
			nt.nodes.active = n
	sc.cycles.samples = samples
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
		ob.select_set(True)
	bpy.context.view_layer.objects.active = obs[0]
	bpy.ops.object.bake(type=kind, **kw)
	return np.array(img.pixels[:], dtype=np.float32).reshape(img.size[1], img.size[0], 4)


## Gebackene Objektraum-Normalen (Blender-Achsen, Farbe 0..1) → Godot-Achsen (−1..1), Form (h, w, 3)
def godot_normals(px):
	n = px[..., :3] * 2.0 - 1.0
	return np.stack([n[..., 0], n[..., 2], -n[..., 1]], axis=-1)


def save_image(name, data, path, color_data=False):
	h, w = data.shape[:2]
	img = new_image(name, w, color_data)
	out = np.ones((h, w, 4), dtype=np.float32)
	out[..., :3] = data if data.ndim == 3 else data[..., None]
	img.pixels[:] = np.clip(out, 0, 1).ravel()
	img.filepath_raw = path
	img.file_format = 'PNG'
	img.save()


## Muster in den Atlas malen: Für jede Fläche, deren Gruppe in painters steht, jedes Pixel ihrer Insel (expand Pixel
## darüber hinaus) auf seinen Punkt im Raum (Godot, Objektkoordinaten) abbilden und painters[gruppe](punkte, normale)
## fragen – Rückgabe (Normalen N×3 oder None, Verschattung N oder None, Maske N in 0..1). nrm (h, w, 3) und ao (h, w)
## werden überschrieben bzw. multipliziert.
def paint_details(obs, nrm, ao, painters, expand=2.0):
	h, w = ao.shape
	for ob in obs:
		me = ob.data
		if "group" not in me.attributes:
			continue
		groups = me.attributes["group"].data
		uvs = me.uv_layers["atlas"].data
		for p in me.polygons:
			paint = painters.get(groups[p.index].value)
			if paint is None:
				continue
			idx = list(p.loop_indices)
			uv = np.array([uvs[i].uv for i in idx], dtype=np.float64) * [w, h]
			pos = np.array([G(me.vertices[me.loops[i].vertex_index].co) for i in idx], dtype=np.float64)
			# Abbildung Pixel → Raum aus drei Ecken
			U = np.stack([uv[1] - uv[0], uv[2] - uv[0]], axis=1)
			P = np.stack([pos[1] - pos[0], pos[2] - pos[0]], axis=1)
			M = P @ np.linalg.inv(U)
			px_m = math.sqrt(abs(np.linalg.det(M.T @ M))) ** 0.5   # Meter je Pixel
			# Ebene der Fläche: zwei Achsen und ihre Ausdehnung (plus expand Pixel)
			n = np.array(G(p.normal), dtype=np.float64)
			e1 = (pos[1] - pos[0]) / np.linalg.norm(pos[1] - pos[0])
			e2 = np.cross(n, e1)
			a1 = (pos - pos[0]) @ e1
			a2 = (pos - pos[0]) @ e2
			grow = expand * px_m
			lo = np.floor(uv.min(axis=0) - expand - 1).astype(int).clip(0, [w - 1, h - 1])
			hi = np.ceil(uv.max(axis=0) + expand + 1).astype(int).clip(0, [w - 1, h - 1])
			cx, cy = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(lo[1], hi[1] + 1))
			pix = np.stack([cx.ravel() + 0.5, cy.ravel() + 0.5], axis=1)
			pts = pos[0] + (pix - uv[0]) @ M.T
			b1 = (pts - pos[0]) @ e1
			b2 = (pts - pos[0]) @ e2
			inside = (b1 >= a1.min() - grow) & (b1 <= a1.max() + grow) & (b2 >= a2.min() - grow) & (b2 <= a2.max() + grow)
			if not inside.any():
				continue
			pts = pts[inside]
			rows = cy.ravel()[inside]
			cols = cx.ravel()[inside]
			normals, shade, mask = paint(pts, n, px_m)
			if normals is not None:
				old = nrm[rows, cols]
				mix = old * (1.0 - mask[:, None]) + normals * mask[:, None]
				nrm[rows, cols] = mix / np.linalg.norm(mix, axis=1, keepdims=True).clip(1e-6)
			if shade is not None:
				ao[rows, cols] *= 1.0 - mask * (1.0 - shade)
