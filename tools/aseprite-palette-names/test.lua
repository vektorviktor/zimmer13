-- Test für palette-file.lua im Batch-Modus (ohne Fenster, verändert nichts):
--   Aseprite.exe -b map.aseprite --script tools/aseprite-palette-names/test.lua
-- Prüft, dass jede Farbe der geöffneten Datei ihren Namen aus der Legende (bzw. Datei) bekommt, und die Zuordnung
-- bei vertauschten, geänderten und neuen Farben.

local dir = app.fs.filePath(debug.getinfo(1, "S").source:sub(2))
local PaletteFile = dofile(app.fs.joinPath(dir, "palette-file.lua"))
local failures = 0

local function check(name, cond)
  print((cond and "OK     " or "FEHLER ") .. name)
  if not cond then failures = failures + 1 end
end

-- Datei: Namen lesen und der Palette im Speicher zuordnen
local spr = app.sprite
assert(spr, "Bitte eine .aseprite-Datei mit angeben")
local saved, size, source = PaletteFile.read(spr.filename)
check("Namen lesbar", saved ~= nil)
print("Namen aus " .. (source == "legend" and PaletteFile.legendPath(spr.filename) or "der Datei"))
local pal = spr.palettes[1]
local live = {}
for i = 0, #pal - 1 do
  local c = pal:getColor(i)
  live[i] = { r = c.red, g = c.green, b = c.blue, a = c.alpha }
end
local entries = PaletteFile.match(live, #pal, saved)
local named, sure = 0, 0
for i = 0, #pal - 1 do
  if entries[i].name ~= "" then named = named + 1 end
  if entries[i].state == "ok" then sure = sure + 1 end
end
print(string.format("%s: %d Farben, %d benannt", app.fs.fileName(spr.filename), #pal, named))
check("Palettengröße wie in der Datei", size == #pal)
check("Alle Farben sicher zugeordnet", sure == #pal)

-- Zuordnung bei geänderter Palette
local s = {
  [0] = { r = 0, g = 0, b = 0, a = 255, name = "Wand" },
  [1] = { r = 255, g = 0, b = 0, a = 255, name = "Möbel: Bett" },
  [2] = { r = 0, g = 255, b = 0, a = 255, name = "Licht: Kerze" },
  [3] = { r = 9, g = 9, b = 9, a = 255, name = "X" },
}
local l = {
  [0] = { r = 0, g = 0, b = 0, a = 255 },   -- unverändert
  [1] = { r = 0, g = 255, b = 0, a = 255 }, -- mit 2 vertauscht
  [2] = { r = 255, g = 0, b = 0, a = 255 },
  [3] = { r = 1, g = 1, b = 1, a = 255 },   -- Farbe geändert
  [4] = { r = 7, g = 7, b = 7, a = 255 },   -- neu
}
local m = PaletteFile.match(l, 5, s)
check("unverändert", m[0].name == "Wand" and m[0].state == "ok")
check("vertauscht", m[1].name == "Licht: Kerze" and m[1].state == "moved"
  and m[2].name == "Möbel: Bett" and m[2].state == "moved")
check("Farbe geändert", m[3].name == "X" and m[3].state == "changed")
check("neu", m[4].name == "" and m[4].state == "none")
check("Vorsatz", m[2].prefix == "Möbel" and m[2].rest == "Bett" and m[0].prefix == nil)

print(failures == 0 and "Alle Tests bestanden" or (failures .. " Fehler"))
