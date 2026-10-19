-- Palettennamen aus einer .aseprite-Datei lesen und der Palette im Speicher zuordnen.
--
-- Die Lua-API von Aseprite 1.3.18 (API 41) kennt keine Farbnamen: Color und Palette haben kein
-- Namensfeld, und Palette:saveAs() verliert die Namen. Deshalb wird der Paletten-Chunk (0x2019)
-- des ersten Frames direkt aus der gespeicherten Datei gelesen – genau wie in tools/build_map.py.
-- Dieses Modul nutzt keine UI und lässt sich im Batch-Modus testen (test.lua).
-- Aseprite fragt beim ersten Lesen einer Datei nach Lesezugriff (Skript-Sicherheit).

local M = {}

local FILE_MAGIC = 0xA5E0
local FRAME_MAGIC = 0xF1FA
local CHUNK_PALETTE = 0x2019
local ENTRY_HAS_NAME = 1

-- Leerzeichen am Rand entfernen (wie name.strip() in build_map.py)
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Schlüssel für den Farbvergleich (RGBA als Hex)
function M.colorKey(c)
  return string.format("%02x%02x%02x%02x", c.r, c.g, c.b, c.a)
end

-- Liest die Palette des ersten Frames.
-- Ergebnis: Tabelle Index (0-basiert) → { r, g, b, a, name } und die Palettengröße,
-- oder nil und ein Fehlertext. Ohne Paletten-Chunk 0x2019 (alte Dateien) gibt es keine Namen.
function M.read(path)
  local f, err = io.open(path, "rb")
  if not f then return nil, err end
  local data = f:read(128 + 16)
  if not data or #data < 144 then
    f:close()
    return nil, "Datei zu kurz"
  end
  if string.unpack("<I2", data, 5) ~= FILE_MAGIC then
    f:close()
    return nil, "keine Aseprite-Datei"
  end
  local frameSize, frameMagic, oldCount, _, newCount = string.unpack("<I4I2I2I2xxI4", data, 129)
  if frameMagic ~= FRAME_MAGIC then
    f:close()
    return nil, "Frame-Kopf fehlt"
  end
  local body = f:read(frameSize - 16) or ""
  f:close()

  local entries, size = {}, 0
  local p = 1
  for _ = 1, (newCount ~= 0 and newCount or oldCount) do
    if p + 5 > #body then break end
    local chunkSize, chunkType = string.unpack("<I4I2", body, p)
    if chunkType == CHUNK_PALETTE then
      local total, first, last = string.unpack("<I4I4I4", body, p + 6)
      size = math.max(size, total)
      local q = p + 6 + 20
      for i = first, last do
        local flags, r, g, b, a
        flags, r, g, b, a, q = string.unpack("<I2BBBB", body, q)
        local name = ""
        if flags & ENTRY_HAS_NAME ~= 0 then
          name, q = string.unpack("<s2", body, q)
        end
        entries[i] = { r = r, g = g, b = b, a = a, name = trim(name) }
      end
    end
    if chunkSize < 6 then break end
    p = p + chunkSize
  end
  return entries, size
end

-- Teilt „Möbel: Bett“ in Vorsatz „Möbel“ und Rest „Bett“. Ohne Doppelpunkt: nil, Name.
function M.splitPrefix(name)
  local prefix, rest = name:match("^([^:]+):%s*(.*)$")
  if prefix then return trim(prefix), rest end
  return nil, name
end

-- Ordnet jeder Farbe der Palette im Speicher (live, Index 0..count-1 → {r,g,b,a}) einen Namen
-- aus der gespeicherten Palette (saved, Ergebnis von M.read) zu. Zustand je Eintrag:
--   "ok"      gleicher Index, gleiche Farbe – Name sicher
--   "moved"   Farbe steht in der Datei an anderer Stelle (eindeutig) – Name von dort
--   "changed" Farbe am Index wurde verändert – Name des Index, unsicher
--   "none"    Index gibt es in der Datei nicht
function M.match(live, count, saved)
  saved = saved or {}
  -- Farbe → Index in der Datei; false, wenn die Farbe dort mehrfach mit Namen vorkommt
  local byColor = {}
  for i, e in pairs(saved) do
    if e.name ~= "" then
      local k = M.colorKey(e)
      if byColor[k] == nil then byColor[k] = i else byColor[k] = false end
    end
  end
  local result = {}
  for i = 0, count - 1 do
    local c = live[i]
    local k = M.colorKey(c)
    local s = saved[i]
    local name, state = "", "none"
    if s and M.colorKey(s) == k then
      name, state = s.name, "ok"
    elseif byColor[k] then
      name, state = saved[byColor[k]].name, "moved"
    elseif s then
      name, state = s.name, "changed"
    end
    local prefix, rest = M.splitPrefix(name)
    result[i] = { index = i, color = c, name = name, prefix = prefix, rest = rest, state = state }
  end
  return result
end

return M
