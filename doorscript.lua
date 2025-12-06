------------------------------
--   EINSTELLUNGEN
------------------------------
local SIDE = "back"        -- Bundled-Kabel-Seite
local COLOR_OPEN  = colors.orange
local COLOR_CLOSE = colors.white
local COLOR_STATE = colors.blue   -- Tür-status: blau = offen

local PULSE_TIME = 0.3     -- wie lang der Puls dauert

-- Monitor-Seite (oder nil, wenn kein Monitor verwendet wird)
local MONITOR_SIDE = "right"   -- z.B. "right", "left", "top", ...

------------------------------
--   PERIPHERIE / MONITOR
------------------------------

local mon = nil
if MONITOR_SIDE then
    if peripheral.isPresent(MONITOR_SIDE) and peripheral.getType(MONITOR_SIDE) == "monitor" then
        mon = peripheral.wrap(MONITOR_SIDE)
        mon.setTextScale(0.5)
        mon.setBackgroundColor(colors.black)
        mon.setTextColor(colors.yellow)
        mon.clear()
    else
        print("WARNUNG: Kein Monitor an Seite '" .. MONITOR_SIDE .. "' gefunden.")
        mon = nil
    end
end

------------------------------
--   HILFSFUNKTIONEN
------------------------------

-- Alle Bundled-Signale ausschalten
local function allOff()
    redstone.setBundledOutput(SIDE, 0)
end

-- Einen kurzen Puls senden
local function pulse(color)
    allOff()
    redstone.setBundledOutput(SIDE, color)
    sleep(PULSE_TIME)
    allOff()
end

-- Türstatus einlesen (blau = offen)
local function doorIsOpen()
    local sig = redstone.getBundledInput(SIDE)
    return (bit.band(sig, COLOR_STATE) ~= 0)
end

------------------------------
--   TERMINAL-ANZEIGE
------------------------------

local options = { "Öffnen", "Schließen" }
local selected = 1

local function draw()
    term.clear()
    term.setCursorPos(1,1)
    print("=== Tuerterminal Deluxe ===")

    local offen = doorIsOpen()
    term.setCursorPos(1,3)
    if offen then
        term.setTextColor(colors.green)
        print("Status: Tuer ist OFFEN")
    else
        term.setTextColor(colors.red)
        print("Status: Tuer ist GESCHLOSSEN")
    end
    term.setTextColor(colors.white)

    print("")    
    print("Aktionen:")

    for i, v in ipairs(options) do
        term.setCursorPos(3, 6+i)
        if i == selected then
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.black)
            write("> " .. v .. " <")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
        else
            write("  " .. v)
        end
    end

    term.setCursorPos(1, 12)
    term.setTextColor(colors.lightGray)
    print("Pfeile = Auswahl | Enter = Ausfuehren")
    term.setTextColor(colors.white)
end

------------------------------
--   LOGIK FUER AKTIONEN
------------------------------

local function execute()
    local offen = doorIsOpen()

    if selected == 1 then
        -- "Öffnen"
        if offen then
            term.setCursorPos(1,14)
            term.setTextColor(colors.red)
            print("Tuer ist offen – Oeffnen gesperrt!")
            term.setTextColor(colors.white)
            sleep(1.5)
            return
        end
        
        pulse(COLOR_OPEN)

    elseif selected == 2 then
        -- "Schließen"
        if not offen then
            term.setCursorPos(1,14)
            term.setTextColor(colors.red)
            print("Tuer ist zu – Schliessen gesperrt!")
            term.setTextColor(colors.white)
            sleep(1.5)
            return
        end

        pulse(COLOR_CLOSE)
    end
end

------------------------------
--   HAUPTSCHLEIFE TERMINAL
------------------------------

local function mainTerminalLoop()
    allOff()
    draw()

    while true do
        local ev, key = os.pullEvent("key")

        if key == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #options end
            draw()

        elseif key == keys.down then
            selected = selected + 1
            if selected > #options then selected = 1 end
            draw()

        elseif key == keys.enter then
            execute()
            draw()
        end
    end
end

------------------------------
--   MONITOR-FIXTEXT (statt Laufschrift)
------------------------------

local function monitorLoop()
    if not mon then
        while true do sleep(5) end
    end

    while true do
        mon.clear()
        local w, h = mon.getSize()

        local tag = os.day()
        local zeit = textutils.formatTime(os.time(), true)

        mon.setCursorPos(1, math.floor(h/2))
        mon.write("Welcome - Tag " .. tag .. " - " .. zeit)

        sleep(1)   -- Uhrzeit aktualisieren
    end
end

------------------------------
--   PROGRAMMSTART
------------------------------

parallel.waitForAny(mainTerminalLoop, monitorLoop)
