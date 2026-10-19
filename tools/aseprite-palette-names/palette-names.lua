-- Palettennamen: eigenes Fenster, das die aktive Palette als Liste zeigt – Farbkachel, Index, Name.
-- Gedacht für den Gebäudeplan map.aseprite, dessen Legende in den Namen der Palettenfarben steht
-- („Wand“, „Möbel: Bett“, „Licht: Wandleuchte defekt“ …) – in der Legende map.gpl daneben.
--
-- Linksklick auf einen Eintrag setzt die Vordergrundfarbe, Rechtsklick die Hintergrundfarbe.
-- Klick auf eine Gruppenüberschrift klappt die Gruppe ein und aus.
--
-- Die Farben kommen live aus der Palette im Speicher, die Namen aus der Legende <datei>.gpl oder, ohne
-- Legende, aus der gespeicherten Datei (palette-file.lua – Aseprite behält keine Farbnamen). Passt eine
-- Farbe nicht zur Legende (Reihenfolge oder Farbwert geändert), steht hinter dem Namen ein „*“.
-- Die Erweiterung liest nur; Palette und Datei bleiben unverändert.

local PaletteFile -- Modul aus palette-file.lua, geladen in init()
local prefs = {}  -- plugin.preferences, bleiben über Neustarts erhalten

local ALL = "Alle"
local NO_PREFIX = "Ohne Vorsatz"
local NO_NAME = "Ohne Namen"
local BAR_W = 6          -- Breite der Bildlaufleiste
local WHEEL_ROWS = 3     -- Zeilen je Mausrad-Raste
local SAVE_COMMANDS = { SaveFile = true, SaveFileAs = true }

local S = {
  dlg = nil,
  sprite = nil,         -- Sprite, an dessen Ereignisse die Liste gebunden ist
  spriteEvents = {},    -- { events, code } zum Abmelden
  appEvents = {},
  saved = nil,          -- Palette mit Namen aus Legende oder Datei (PaletteFile.read)
  note = "",            -- Hinweis, warum Namen fehlen
  liveKey = nil,        -- Signatur der Palette im Speicher, um Änderungen zu erkennen
  entries = {},         -- Index → Eintrag (PaletteFile.match + group)
  count = 0,
  groups = {},          -- Gruppen in Reihenfolge des ersten Auftretens
  groupsKey = "",
  collapsed = {},       -- eingeklappte Gruppen
  rows = {},            -- sichtbare Zeilen: { header = Gruppe, n = Anzahl } oder { entry = Eintrag }
  scroll = 0,
  hover = nil,
  statusText = "",      -- Fußzeilen der Liste (im Canvas gezeichnet, damit das Fenster schmal werden kann)
  infoText = "",
  picked = nil,         -- zuletzt per Klick gesetzte Vordergrundfarbe
  dragBar = false,
  rowH = 16,
  viewW = 0,
  viewH = 0,
}

-- Hilfen ------------------------------------------------------------------------------------------

local function themeColor(id, fallback)
  local ok, c = pcall(function() return app.theme.color[id] end)
  if ok and c then return c end
  return fallback
end

local function hex(c)
  return string.format("#%02x%02x%02x", c.r, c.g, c.b)
end

-- Palette des aktiven Frames (bei mehreren Paletten im Sprite)
local function activePalette(spr)
  local pal = spr.palettes[1]
  local frame = app.frame
  if #spr.palettes > 1 and frame and app.sprite == spr then
    for i = 1, #spr.palettes do
      local p = spr.palettes[i]
      if p.frameNumber <= frame.frameNumber then pal = p end
    end
  end
  return pal
end

local function contentH()
  return #S.rows * S.rowH
end

local function clampScroll()
  local maxScroll = math.max(0, contentH() - S.viewH)
  S.scroll = math.max(0, math.min(S.scroll, maxScroll))
end

-- Index der Vordergrundfarbe in der Liste (oder nil)
local function fgIndex()
  local fg = app.fgColor
  local key = PaletteFile.colorKey({ r = fg.red, g = fg.green, b = fg.blue, a = fg.alpha })
  local e = S.entries[fg.index]
  if e and PaletteFile.colorKey(e.color) == key then return fg.index end
  for i = 0, S.count - 1 do
    if PaletteFile.colorKey(S.entries[i].color) == key then return i end
  end
  -- Palette ungespeichert geändert: zuletzt angeklickten Eintrag behalten
  if S.picked and fg.index == S.picked and S.entries[S.picked] then return S.picked end
  return nil
end

-- Daten -------------------------------------------------------------------------------------------

-- Namen aus der gespeicherten Datei des gebundenen Sprites lesen
local function loadSaved()
  S.saved, S.note = nil, ""
  local spr = S.sprite
  if not spr then
    S.note = "Keine Datei offen"
    return
  end
  local fn = spr.filename
  local ext = app.fs.fileExtension(fn):lower()
  if not app.fs.isFile(fn) then
    S.note = "Datei noch nicht gespeichert – keine Namen"
  elseif ext ~= "aseprite" and ext ~= "ase" then
    S.note = "Namen gibt es nur in .aseprite-Dateien"
  else
    local saved, err, source = PaletteFile.read(fn)
    if saved then
      S.saved = saved
      if source == "file" then
        S.note = "Keine Legende " .. app.fs.fileName(PaletteFile.legendPath(fn)) .. " – Namen aus der Datei"
      end
    else
      S.note = "Datei nicht lesbar: " .. tostring(err)
    end
  end
end

-- Palette im Speicher lesen und den Namen zuordnen. Gibt true zurück, wenn sich etwas geändert hat.
local function rebuildEntries(force)
  if not S.sprite then
    local changed = S.count ~= 0
    S.entries, S.count, S.liveKey, S.groups = {}, 0, nil, {}
    return changed or force
  end
  local pal = activePalette(S.sprite)
  local live, keys = {}, {}
  for i = 0, #pal - 1 do
    local c = pal:getColor(i)
    live[i] = { r = c.red, g = c.green, b = c.blue, a = c.alpha }
    keys[#keys + 1] = PaletteFile.colorKey(live[i])
  end
  local key = table.concat(keys)
  if not force and key == S.liveKey then return false end
  S.liveKey = key
  S.count = #pal
  S.entries = PaletteFile.match(live, S.count, S.saved)
  local groups, seen = {}, {}
  for i = 0, S.count - 1 do
    local e = S.entries[i]
    e.group = (e.name == "" and NO_NAME) or e.prefix or NO_PREFIX
    if not seen[e.group] then
      seen[e.group] = true
      groups[#groups + 1] = e.group
    end
  end
  S.groups = groups
  return true
end

local function entryMatches(e, needle)
  if needle == "" then return true end
  if e.name:lower():find(needle, 1, true) then return true end
  if tostring(e.index) == needle then return true end
  return hex(e.color):find(needle, 1, true) ~= nil
end

-- Sichtbare Zeilen aus Gruppe, Suchtext und Gruppierung bestimmen
local function buildRows()
  local rows = {}
  if S.dlg then
    local data = S.dlg.data
    local group = data.group or ALL
    local needle = (data.search or ""):lower()
    if data.grouped then
      for _, g in ipairs(S.groups) do
        if group == ALL or group == g then
          local header = { header = g, n = 0 }
          for i = 0, S.count - 1 do
            local e = S.entries[i]
            if e.group == g and entryMatches(e, needle) then
              if header.n == 0 then rows[#rows + 1] = header end
              header.n = header.n + 1
              if not S.collapsed[g] then rows[#rows + 1] = { entry = e } end
            end
          end
        end
      end
    else
      for i = 0, S.count - 1 do
        local e = S.entries[i]
        if (group == ALL or e.group == group) and entryMatches(e, needle) then
          rows[#rows + 1] = { entry = e }
        end
      end
    end
  end
  S.rows = rows
  S.hover = nil
  clampScroll()
end

local function entryInfo(e)
  if not e then return "" end
  local name = e.name ~= "" and e.name or "(ohne Name)"
  local text = string.format("%d: %s  %s", e.index, name, hex(e.color))
  if e.color.a < 255 then text = text .. string.format(" α%d", e.color.a) end
  if e.state == "moved" then
    text = text .. "  – verschoben"
  elseif e.state == "changed" then
    text = text .. "  – Farbe geändert"
  end
  return text
end

local function updateLabels()
  if not S.dlg then return end
  local status
  if S.note ~= "" then
    status = S.note
  else
    local named, unsure = 0, 0
    for i = 0, S.count - 1 do
      local e = S.entries[i]
      if e.name ~= "" then named = named + 1 end
      if e.state ~= "ok" and e.name ~= "" then unsure = unsure + 1 end
    end
    status = string.format("%d Farben, %d benannt", S.count, named)
    if S.sprite then status = app.fs.fileName(S.sprite.filename) .. ": " .. status end
    if unsure > 0 then
      status = status .. string.format(", %d mit * (ungespeichert)", unsure)
    end
  end
  local hovered = S.hover and S.rows[S.hover] and S.rows[S.hover].entry
  S.statusText = status
  S.infoText = entryInfo(hovered or S.entries[fgIndex() or -1])
end

-- Auswahl der Gruppen nur neu setzen, wenn sich die Gruppen geändert haben
local function updateGroupOptions()
  local key = table.concat(S.groups, "\n")
  if key == S.groupsKey then return end
  S.groupsKey = key
  local options, current, found = { ALL }, S.dlg.data.group, false
  for _, g in ipairs(S.groups) do
    options[#options + 1] = g
    if g == current then found = true end
  end
  S.dlg:modify{ id = "group", options = options, option = found and current or ALL }
end

local function refresh()
  if not S.dlg then return end
  updateGroupOptions()
  buildRows()
  updateLabels()
  S.dlg:repaint()
end

-- Ereignisse --------------------------------------------------------------------------------------

local function unbindSprite()
  for _, l in ipairs(S.spriteEvents) do
    pcall(function() l.events:off(l.code) end)
  end
  S.spriteEvents = {}
  S.sprite = nil
end

local function onSpriteChange()
  if rebuildEntries(false) then refresh() end
end

local function onFilenameChange()
  loadSaved()
  rebuildEntries(true)
  refresh()
end

local function bindSprite(spr)
  unbindSprite()
  S.sprite = spr
  if spr then
    local ev = spr.events
    S.spriteEvents = {
      { events = ev, code = ev:on("change", onSpriteChange) },
      { events = ev, code = ev:on("filenamechange", onFilenameChange) },
    }
  end
  loadSaved()
  rebuildEntries(true)
end

-- Andere Datei, Ebene oder anderes Frame ausgewählt
local function onSiteChange()
  if app.sprite ~= S.sprite then
    bindSprite(app.sprite)
    S.scroll = 0
    refresh()
  elseif rebuildEntries(false) then -- anderes Frame mit eigener Palette
    refresh()
  end
end

local function onAfterCommand(ev)
  if SAVE_COMMANDS[ev.name] and S.sprite then
    loadSaved()
    rebuildEntries(true)
    refresh()
  end
end

local function onFgColorChange()
  updateLabels()
  if S.dlg then S.dlg:repaint() end
end

local function bindApp()
  local ev = app.events
  S.appEvents = {
    ev:on("sitechange", onSiteChange),
    ev:on("aftercommand", onAfterCommand),
    ev:on("fgcolorchange", onFgColorChange),
  }
end

local function unbindApp()
  for _, code in ipairs(S.appEvents) do
    pcall(function() app.events:off(code) end)
  end
  S.appEvents = {}
end

-- Zeichnen ----------------------------------------------------------------------------------------

local function drawSwatch(gc, c, x, y, size, outline)
  if c.a < 255 then -- Schachbrett hinter durchsichtigen Farben
    local half = size // 2
    gc.color = Color(204, 204, 204)
    gc:fillRect(Rectangle(x, y, size, size))
    gc.color = Color(153, 153, 153)
    gc:fillRect(Rectangle(x, y, half, half))
    gc:fillRect(Rectangle(x + half, y + half, size - half, size - half))
  end
  gc.color = Color(c.r, c.g, c.b, c.a)
  gc:fillRect(Rectangle(x, y, size, size))
  gc.color = outline
  gc:strokeRect(Rectangle(x, y, size, size))
end

local function onPaint(ev)
  local gc = ev.context
  local w, h = gc.width, gc.height
  local textH = gc:measureText("Mg").height
  local lineH = textH + 4
  local listH = math.max(0, h - 2 * lineH - 3) -- darunter zwei Fußzeilen
  S.viewW, S.viewH = w, listH
  S.rowH = math.max(textH + 6, 16)
  clampScroll()

  local rowH = S.rowH
  local text = themeColor("text", Color(0, 0, 0))
  local faint = themeColor("disabled", Color(128, 128, 128))
  local face = themeColor("listitem_normal_face", themeColor("face", Color(255, 255, 255)))
  local selFace = themeColor("listitem_selected_face", Color(44, 76, 145))
  local selText = themeColor("listitem_selected_text", Color(255, 255, 255))
  local hotFace = themeColor("menuitem_hot_face", faint)
  local headerText = themeColor("separator_label", text)

  gc.color = face
  gc:fillRect(Rectangle(0, 0, w, h))
  gc:save()
  gc:beginPath()
  gc:rect(Rectangle(0, 0, w, listH))
  gc:clip()

  local showBar = contentH() > listH
  local listW = showBar and (w - BAR_W - 2) or w
  local swatch = rowH - 4
  local idxW = gc:measureText("000").width
  local grouped = S.dlg and S.dlg.data.grouped
  local fg = fgIndex()
  local textY = (rowH - textH) // 2

  local first = S.scroll // rowH + 1
  local y = (first - 1) * rowH - S.scroll
  for r = first, #S.rows do
    if y >= listH then break end
    local row = S.rows[r]
    if row.header then
      if r == S.hover then
        gc.color = hotFace
        gc:fillRect(Rectangle(0, y, listW, rowH))
      end
      local label = (S.collapsed[row.header] and "+ " or "– ") .. row.header .. " (" .. row.n .. ")"
      gc.color = headerText
      gc:fillText(label, 4, y + textY)
      local lineX = 4 + gc:measureText(label).width + 6
      gc.color = faint
      gc:fillRect(Rectangle(lineX, y + rowH // 2, math.max(0, listW - lineX - 4), 1))
    else
      local e = row.entry
      local selected = e.index == fg
      if selected then
        gc.color = selFace
        gc:fillRect(Rectangle(0, y, listW, rowH))
      elseif r == S.hover then
        gc.color = hotFace
        gc:fillRect(Rectangle(0, y, listW, rowH))
      end
      local x = grouped and 14 or 4
      drawSwatch(gc, e.color, x, y + 2, swatch, selected and selText or faint)
      x = x + swatch + 6

      local idx = tostring(e.index)
      gc.color = selected and selText or faint
      gc:fillText(idx, x + idxW - gc:measureText(idx).width, y + textY)
      x = x + idxW + 8

      local label = grouped and e.prefix and e.rest or e.name
      if e.name == "" then
        label = "(ohne Name)"
      elseif e.state ~= "ok" then
        label = label .. " *"
      end
      if selected then
        gc.color = selText
      elseif e.name == "" or e.state ~= "ok" then
        gc.color = faint
      else
        gc.color = text
      end
      gc:fillText(label, x, y + textY)
    end
    y = y + rowH
  end

  if #S.rows == 0 then
    gc.color = faint
    gc:fillText(S.count == 0 and "Keine Palette" or "Keine Treffer", 8, 8)
  end

  if showBar then
    local thumbH = math.max(20, listH * listH // contentH())
    local thumbY = math.floor(S.scroll / (contentH() - listH) * (listH - thumbH) + 0.5)
    gc.color = themeColor("separator_label", faint)
    gc.opacity = 60
    gc:fillRect(Rectangle(w - BAR_W, 0, BAR_W, listH))
    gc.opacity = 255
    gc.color = faint
    gc:fillRect(Rectangle(w - BAR_W, thumbY, BAR_W, thumbH))
  end
  gc:restore()

  -- Fußzeilen: Eintrag unter der Maus bzw. Vordergrundfarbe, Status. Zu lange Texte werden abgeschnitten.
  gc.color = faint
  gc:fillRect(Rectangle(0, listH, w, 1))
  gc.color = text
  gc:fillText(S.infoText, 4, listH + 3)
  gc.color = faint
  gc:fillText(S.statusText, 4, listH + 3 + lineH)
end

-- Maus --------------------------------------------------------------------------------------------

local function rowAt(y)
  if y < 0 or y >= S.viewH then return nil end
  local r = (y + S.scroll) // S.rowH + 1
  if r >= 1 and r <= #S.rows then return r end
  return nil
end

local function onBar(x)
  return S.viewW > 0 and contentH() > S.viewH and x >= S.viewW - BAR_W - 2
end

local function scrollToBar(y)
  local thumbH = math.max(20, S.viewH * S.viewH // contentH())
  local t = (y - thumbH / 2) / math.max(1, S.viewH - thumbH)
  S.scroll = math.floor(t * (contentH() - S.viewH) + 0.5)
  clampScroll()
  S.dlg:repaint()
end

local function onMouseDown(ev)
  if onBar(ev.x) then
    S.dragBar = true
    scrollToBar(ev.y)
    return
  end
  local r = rowAt(ev.y)
  if not r then return end
  local row = S.rows[r]
  if row.header then
    S.collapsed[row.header] = not S.collapsed[row.header] or nil
    buildRows()
    S.dlg:repaint()
    return
  end
  local c = Color{ index = row.entry.index }
  if ev.button == MouseButton.RIGHT then
    app.bgColor = c
  else
    S.picked = row.entry.index
    app.fgColor = c
  end
  updateLabels()
  S.dlg:repaint()
end

local function onMouseMove(ev)
  if S.dragBar then
    scrollToBar(ev.y)
    return
  end
  local r = (not onBar(ev.x)) and rowAt(ev.y) or nil
  if r ~= S.hover then
    S.hover = r
    updateLabels()
    S.dlg:repaint()
  end
end

local function onMouseUp()
  S.dragBar = false
end

local function onWheel(ev)
  S.scroll = S.scroll + math.floor(ev.deltaY * S.rowH * WHEEL_ROWS + 0.5)
  clampScroll()
  local r = rowAt(ev.y)
  if r ~= S.hover then
    S.hover = r
    updateLabels()
  end
  S.dlg:repaint()
end

-- Fenster -----------------------------------------------------------------------------------------

local function closeDialog()
  if S.dlg then S.dlg:close() end
end

-- Gespeicherte Fensterlage nur übernehmen, wenn sie im Programmfenster liegt
local function savedBounds()
  local b = prefs.bounds
  if type(b) ~= "table" or not b.w then return nil end
  local ok, win = pcall(function() return app.window end)
  if ok and win and (b.x < 0 or b.y < 0 or b.x + 40 > win.width or b.y + 40 > win.height) then
    return nil
  end
  return Rectangle(b.x, b.y, b.w, b.h)
end

local function openDialog()
  if S.dlg then return end
  local dlg
  dlg = Dialog{
    title = "Palettennamen",
    onclose = function()
      local b = dlg.bounds
      prefs.bounds = { x = b.x, y = b.y, w = b.width, h = b.height }
      prefs.grouped = dlg.data.grouped
      prefs.group = dlg.data.group
      unbindApp()
      unbindSprite()
      S.dlg = nil
    end,
  }
  S.dlg = dlg
  S.groupsKey = ""
  -- Ohne Beschriftungen links, damit das Fenster schmal werden kann: Gruppe, Gruppiert, Suchfeld
  dlg:combobox{ id = "group", options = { ALL }, option = ALL,
    onchange = function() S.scroll = 0; refresh() end }
  dlg:newrow()
  dlg:check{ id = "grouped", text = "Gruppiert", selected = prefs.grouped ~= false,
    onchange = function() refresh() end }
  dlg:newrow()
  dlg:entry{ id = "search", text = "",
    onchange = function() S.scroll = 0; refresh() end }
  -- Kleine Mindestgröße: Breite und Höhe bestimmt der Nutzer durch Ziehen am Fensterrand.
  dlg:canvas{ id = "list", width = 100, height = 330,
    onpaint = onPaint, onmousedown = onMouseDown, onmousemove = onMouseMove,
    onmouseup = onMouseUp, onwheel = onWheel }
  dlg:button{ id = "reload", text = "Neu einlesen", onclick = function()
    loadSaved()
    rebuildEntries(true)
    refresh()
  end }

  bindSprite(app.sprite)
  bindApp()
  updateGroupOptions()
  if prefs.group then
    for _, g in ipairs(S.groups) do
      if g == prefs.group then dlg:modify{ id = "group", option = g } end
    end
  end
  refresh()
  local bounds = savedBounds()
  if bounds then
    dlg:show{ wait = false, bounds = bounds }
  else
    dlg:show{ wait = false }
  end
  -- Ein repaint() vor show() malt in eine Fläche ohne Größe; erst jetzt ist das Fenster angelegt.
  dlg:repaint()
end

local function toggleDialog()
  if S.dlg then closeDialog() else openDialog() end
end

-- Erweiterung -------------------------------------------------------------------------------------

function init(plugin)
  PaletteFile = dofile(app.fs.joinPath(plugin.path, "palette-file.lua"))
  prefs = plugin.preferences
  plugin:newCommand{
    id = "PaletteNames",
    title = "Palettennamen",
    group = "view_extras",
    onclick = toggleDialog,
    onchecked = function() return S.dlg ~= nil end,
  }
  plugin:newCommand{
    id = "PaletteNamesFromPalette",
    title = "Palettennamen anzeigen",
    group = "palette_main",
    onclick = toggleDialog,
    onchecked = function() return S.dlg ~= nil end,
  }
end

function exit(plugin)
  closeDialog()
end

-- Zugriff für test.lua (Aseprite selbst wertet den Rückgabewert nicht aus)
return { state = S, open = openDialog, close = closeDialog, refresh = refresh,
  mouseDown = onMouseDown, mouseMove = onMouseMove, wheel = onWheel }
