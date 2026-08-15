require("hs.ipc")

local jblMacAddress = "00-42-79-d8-8b-3d"
local jblOutputName = "JBL Xtreme 2"
local scarlettDeviceName = "Scarlett 2i2 USB"
local macbookSpeakersName = "MacBook Air Speakers"
local ts5NameFragment = "TS5 Plus"

local hueBridgeIP = "192.168.219.102"
local hueRelaxSceneID = "990721a0-1dd4-4f3d-8c2f-0af3550b90d3"
local hueRoomGroupedLightID = "2434380b-4845-42cd-bcfd-79767e4c02f8"

local youtubeMusicBundleID = "com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod"
local hgMonitorName = "HG584T05"

local metronomeBundleID = "is.gtmetronome"
local macbookDisplayName = "Built-in Retina Display"

local sidecarIpadName = "J’s iPad"
local sidecarScreenNameFragment = "Sidecar Display"

local function findScreenByName(name)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == name then
            return screen
        end
    end
    return nil
end

local function findScreenByNameFragment(fragment)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name():find(fragment, 1, true) then
            return screen
        end
    end
    return nil
end

local function pollUntil(getValue, onSuccess, onTimeout, intervalSeconds, maxAttempts)
    intervalSeconds = intervalSeconds or 0.5
    maxAttempts = maxAttempts or 20
    local attempts = 0
    local timer
    timer = hs.timer.doEvery(intervalSeconds, function()
        attempts = attempts + 1
        local value = getValue()
        if value then
            timer:stop()
            onSuccess(value)
        elseif attempts >= maxAttempts then
            timer:stop()
            onTimeout()
        end
    end)
end

local debounced = {}
local function onceEvery3s(key, action)
    if debounced[key] then return end
    debounced[key] = true
    hs.timer.doAfter(3, function() debounced[key] = false end)
    action()
end

local function connectJblAndSwitchOutput()
    hs.execute("/opt/homebrew/bin/blueutil --connect " .. jblMacAddress, true)

    pollUntil(
        function() return hs.audiodevice.findOutputByName(jblOutputName) end,
        function(device)
            device:setDefaultOutputDevice()
            hs.alert.show("Switched audio output to " .. jblOutputName)
        end,
        function() hs.alert.show("Could not find audio device: " .. jblOutputName) end,
        1, 15
    )
end

local function openAndPositionYoutubeMusic()
    hs.application.open(youtubeMusicBundleID)

    pollUntil(
        function()
            local app = hs.application.find(youtubeMusicBundleID)
            local win = app and app:mainWindow()
            local screen = findScreenByName(hgMonitorName)
            if win and screen then return { win = win, screen = screen } end
        end,
        function(result) result.win:setFrame(result.screen:frame()) end,
        function() hs.alert.show("Could not position YouTube Music window") end
    )
end

local cachedHueKey = nil
local function hueAppKey()
    if not cachedHueKey then
        local output, status = hs.execute('/usr/bin/security find-generic-password -a "$USER" -s "hue-bridge-app-key" -w')
        if status then
            cachedHueKey = output:gsub("%s+$", "")
        end
    end
    return cachedHueKey
end

local function hueRequest(path, body)
    local key = hueAppKey()
    if not key then
        hs.alert.show("Hue: app key not found in Keychain")
        return
    end

    local url = "https://" .. hueBridgeIP .. path
    hs.task.new("/usr/bin/curl", function(exitCode)
        if exitCode ~= 0 then
            hs.alert.show("Hue: request failed")
        end
    end, {
        "-k", "-s", "-X", "PUT", url,
        "-H", "hue-application-key: " .. key,
        "-d", body
    }):start()
end

local function recallHueScene(sceneID)
    hueRequest("/clip/v2/resource/scene/" .. sceneID, '{"recall":{"action":"active"}}')
end

local function turnOffHueRoom(groupedLightID)
    hueRequest("/clip/v2/resource/grouped_light/" .. groupedLightID, '{"on":{"on":false}}')
end

local function pauseAllMedia()
    hs.task.new("/opt/homebrew/bin/nowplaying-cli", nil, { "pause" }):start()
end

local function connectSidecar()
    hs.task.new("/opt/homebrew/bin/SidecarLauncher", function(exitCode, stdOut)
        if exitCode ~= 0 then
            hs.alert.show("Sidecar: failed to connect to " .. sidecarIpadName)
        end
    end, { "connect", sidecarIpadName }):start()
end

local function disconnectSidecar()
    hs.task.new("/opt/homebrew/bin/SidecarLauncher", nil, { "disconnect", sidecarIpadName }):start()
end

local function switchToMacBookSpeakers()
    local speakers = hs.audiodevice.findOutputByName(macbookSpeakersName)
    if speakers then
        speakers:setDefaultOutputDevice()
    else
        hs.alert.show("Could not find audio device: " .. macbookSpeakersName)
    end
end

local previousInputDevice = nil
local function switchToScarlett()
    local scarlett = hs.audiodevice.findDeviceByName(scarlettDeviceName)
    if not scarlett then
        hs.alert.show("Could not find audio device: " .. scarlettDeviceName)
        return
    end
    previousInputDevice = hs.audiodevice.defaultInputDevice()
    scarlett:setDefaultOutputDevice()
    scarlett:setDefaultInputDevice()
end

local function switchBackFromScarlett()
    local jbl = hs.audiodevice.findOutputByName(jblOutputName)
    if jbl then
        jbl:setDefaultOutputDevice()
    end
    if previousInputDevice then
        previousInputDevice:setDefaultInputDevice()
        previousInputDevice = nil
    end
end

local function moveGarageBandToIpad(app)
    pollUntil(
        function()
            local win = app and app:mainWindow()
            local screen = findScreenByNameFragment(sidecarScreenNameFragment)
            if win and screen then return { win = win, screen = screen } end
        end,
        function(result) result.win:setFrame(result.screen:frame()) end,
        function() hs.alert.show("Could not position GarageBand window on " .. sidecarIpadName) end
    )
end

local function openAndPositionMetronome()
    hs.application.open(metronomeBundleID)

    pollUntil(
        function()
            local app = hs.application.find(metronomeBundleID)
            local win = app and app:mainWindow()
            local screen = findScreenByName(macbookDisplayName)
            if win and screen then return { win = win, screen = screen } end
        end,
        function(result) result.win:setFrame(result.screen:frame()) end,
        function() hs.alert.show("Could not position Metronome window") end
    )
end

local function quitMetronome()
    local app = hs.application.find(metronomeBundleID)
    if app then
        app:kill()
    end
end

garageBandWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if appName ~= "GarageBand" then return end
    if eventType == hs.application.watcher.launched then
        switchToScarlett()
        moveGarageBandToIpad(app)
        openAndPositionMetronome()
    elseif eventType == hs.application.watcher.terminated then
        switchBackFromScarlett()
        quitMetronome()
    end
end)
garageBandWatcher:start()

usbWatcher = hs.usb.watcher.new(function(event)
    if not (event.productName and event.productName:find(ts5NameFragment, 1, true)) then
        return
    end

    if event.eventType == "added" then
        onceEvery3s("added", function()
            connectJblAndSwitchOutput()
            recallHueScene(hueRelaxSceneID)
            openAndPositionYoutubeMusic()
            connectSidecar()
        end)
    elseif event.eventType == "removed" then
        onceEvery3s("removed", function()
            -- turnOffHueRoom(hueRoomGroupedLightID)
            pauseAllMedia()
            disconnectSidecar()
            switchToMacBookSpeakers()
        end)
    end
end)
usbWatcher:start()
