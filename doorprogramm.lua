local SIDE = "back"
local COLOR_OPEN  = colors.orange
local COLOR_CLOSE = colors.white
local COLOR_STATE = colors.blue

local PULSE_TIME = 0.3
local AUTO_CLOSE_TIME = 30

local MONITOR_SIDE = "top"

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

local function allOff()
    redstone.setBundledOutput(SIDE, 0)
end

local function pulse(color)
    allOff()
    redstone.setBundledOutput(SIDE, color)
    sleep(PULSE_TIME)
    allOff()
end

local function doorIsOpen()
    local sig = redstone.getBundledInput(SIDE)
    return (bit.band(sig, COLOR_STATE) ~= 0)
end

local autoCloseRemaining = nil
local lastDoorOpen = doorIsOpen()

local options = { "Oeffnen", "Schliessen" }
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

local function execute()
    local offen = doorIsOpen()

    if selected == 1 then
        if offen then
            term.setCursorPos(1,14)
            term.setTextColor(colors.red)
            print("Tuer ist offen – Oeffnen gesperrt!")
            term.setTextColor(colors.white)
            sleep(1.5)
            return
        end
        
        pulse(COLOR_OPEN)
        if doorIsOpen() then
            autoCloseRemaining = AUTO_CLOSE_TIME
            lastDoorOpen = true
        end

    elseif selected == 2 then
        if not offen then
            term.setCursorPos(1,14)
            term.setTextColor(colors.red)
            print("Tuer ist zu – Schliessen gesperrt!")
            term.setTextColor(colors.white)
            sleep(1.5)
            return
        end

        pulse(COLOR_CLOSE)
        autoCloseRemaining = nil
        lastDoorOpen = false
    end
end

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

local function monitorLoop()
    if not mon then
        while true do sleep(5) end
    end

    while true do
        local offen = doorIsOpen()

        if offen and not lastDoorOpen then
            autoCloseRemaining = AUTO_CLOSE_TIME
        elseif not offen and lastDoorOpen then
            autoCloseRemaining = nil
        end
        lastDoorOpen = offen

        mon.clear()
        local w, h = mon.getSize()

        local tag = os.day()
        local zeit = textutils.formatTime(os.time(), true)

        local mid = math.floor(h/2)
        mon.setCursorPos(1, mid)
        mon.write("Welcome - Tag " .. tag .. " - " .. zeit)

        mon.setCursorPos(1, mid + 1)
        if offen then
            if autoCloseRemaining then
                mon.write("Auto-Close in: " .. autoCloseRemaining .. "s")
            else
                mon.write("Auto-Close: bereit")
            end
        else
            mon.write("Tuer geschlossen")
        end

        if autoCloseRemaining then
            autoCloseRemaining = autoCloseRemaining - 1
            if autoCloseRemaining <= 0 then
                if doorIsOpen() then
                    pulse(COLOR_CLOSE)
                end
                autoCloseRemaining = nil
                lastDoorOpen = doorIsOpen()
            end
        end

        sleep(1)
    end
end

parallel.waitForAny(mainTerminalLoop, monitorLoop)
