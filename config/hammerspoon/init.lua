-- Auto-connect JBL Xtreme 2, switch audio output, recall a Hue scene, and position YouTube Music
-- on the HG584T05 monitor when CalDigit TS5 Plus is plugged in.

require("hs.ipc")

local jblMacAddress = "00-42-79-d8-8b-3d"
local jblOutputName = "JBL Xtreme 2"
local ts5NameFragment = "TS5 Plus"

local hueBridgeIP = "192.168.219.102"
local hueRelaxSceneID = "990721a0-1dd4-4f3d-8c2f-0af3550b90d3" -- "Relax" scene
local hueRoomGroupedLightID = "2434380b-4845-42cd-bcfd-79767e4c02f8" -- Jae's Room grouped_light

local youtubeMusicBundleID = "com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod"
local hgMonitorName = "HG584T05"

local debounced = {}
local function onceEvery3s(key, action)
    if debounced[key] then return end
    debounced[key] = true
    hs.timer.doAfter(3, function() debounced[key] = false end)
    action()
end

local function connectJblAndSwitchOutput()
    hs.execute("/opt/homebrew/bin/blueutil --connect " .. jblMacAddress, true)

    -- Poll for the audio device to appear (Bluetooth connect + CoreAudio registration takes a moment).
    local attempts = 0
    local timer
    timer = hs.timer.doEvery(1, function()
        attempts = attempts + 1
        local device = hs.audiodevice.findOutputByName(jblOutputName)
        if device then
            device:setDefaultOutputDevice()
            hs.alert.show("Switched audio output to " .. jblOutputName)
            timer:stop()
        elseif attempts >= 15 then
            hs.alert.show("Could not find audio device: " .. jblOutputName)
            timer:stop()
        end
    end)
end

local function openAndPositionYoutubeMusic()
    hs.application.open(youtubeMusicBundleID)

    -- Poll for the app's window to appear (launch takes a moment if it wasn't already open).
    local attempts = 0
    local timer
    timer = hs.timer.doEvery(0.5, function()
        attempts = attempts + 1
        local app = hs.application.find(youtubeMusicBundleID)
        local win = app and app:mainWindow()
        local screen = hs.screen.find(hgMonitorName)
        if win and screen then
            win:setFrame(screen:frame())
            timer:stop()
        elseif attempts >= 20 then
            hs.alert.show("Could not position YouTube Music window")
            timer:stop()
        end
    end)
end

-- Application key lives in Keychain (not this repo): `security find-generic-password -a "$USER" -s hue-bridge-app-key -w`
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

usbWatcher = hs.usb.watcher.new(function(event)
    if not (event.productName and event.productName:find(ts5NameFragment, 1, true)) then
        return
    end

    if event.eventType == "added" then
        onceEvery3s("added", function()
            connectJblAndSwitchOutput()
            recallHueScene(hueRelaxSceneID)
            openAndPositionYoutubeMusic()
        end)
    elseif event.eventType == "removed" then
        onceEvery3s("removed", function()
            turnOffHueRoom(hueRoomGroupedLightID)
            pauseAllMedia()
        end)
    end
end)
usbWatcher:start()
