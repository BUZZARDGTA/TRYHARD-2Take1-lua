-- Author: IB_U_Z_Z_A_R_Dl
-- Description: A script that aims in helping TRYHARD people for 2Take1 menu.
-- GitHub Repository: https://github.com/Illegal-Services/TRYHARD-2Take1-Lua


-- Globals START
---- Global variables START
local scriptExitEventListener
---- Global variables END

---- Global constants 1/2 START
local SCRIPT_NAME <const> = "TRYHARD.lua"
local SCRIPT_TITLE <const> = "TRYHARD"
local SCRIPT_SETTINGS__PATH <const> = "scripts\\TRYHARD\\Settings.ini"
local SCRIPT_SUPPORTED_ONLINE_VERSION <const> = "1.69"
local NATIVES <const> = require("lib\\natives2845")
local SCRIPT_THIS_ONLINE_VERSION = NATIVES.NETWORK.GET_ONLINE_VERSION()
local HOME_PATH <const> = utils.get_appdata_path("PopstarDevs", "2Take1Menu")
local TRUSTED_FLAGS <const> = {
    { name = "LUA_TRUST_STATS", menuName = "Trusted Stats", bitValue = 1 << 0, isRequiered = true },
    { name = "LUA_TRUST_SCRIPT_VARS", menuName = "Trusted Globals / Locals", bitValue = 1 << 1, isRequiered = true },
    { name = "LUA_TRUST_NATIVES", menuName = "Trusted Natives", bitValue = 1 << 2, isRequiered = true },
    { name = "LUA_TRUST_HTTP", menuName = "Trusted Http", bitValue = 1 << 3, isRequiered = false },
    { name = "LUA_TRUST_MEMORY", menuName = "Trusted Memory", bitValue = 1 << 4, isRequiered = false }
}
---- Global constants 1/2 END

---- Global functions 1/2 START
local function rgba_to_int(R, G, B, A)
    A = A or 255
    return ((R&0x0ff)<<0x00)|((G&0x0ff)<<0x08)|((B&0x0ff)<<0x10)|((A&0x0ff)<<0x18)
end
---- Global functions 1/2 END

---- Global constants 2/2 START
local COLOR <const> = {
    RED = rgba_to_int(255, 0, 0, 255),
    ORANGE = rgba_to_int(255, 165, 0, 255),
    GREEN = rgba_to_int(0, 255, 0, 255)
}
---- Global constants 2/2 END

---- Global functions 2/2 START
local function dec_to_ipv4(ip)
    return string.format("%i.%i.%i.%i", ip >> 24 & 255, ip >> 16 & 255, ip >> 8 & 255, ip & 255)
end

local function pluralize(word, count)
    if count > 1 then
        return word .. "s"
    else
        return word
    end
end

local function startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

local function ends_with_newline(str)
    if string.sub(str, -1) == "\n" then
        return true
    end
    return false
end

function read_file(filePath)
    local file, err = io.open(filePath, "r")
    if err then
        return nil, err
    end

    local content = file:read("*a")

    file:close()

    return content, nil
end

local function json_compress(jsonString)
    local compressedLines = {}
    for line in jsonString:gmatch("[^\r\n]+") do
        local compressedLine = line:gsub("^[ \t]*", ""):gsub("[ \t]*$", ""):gsub('": "', '":"')

        table.insert(compressedLines, compressedLine)
    end

    -- Join processed lines back into a single string
    local compressedJsonString = table.concat(compressedLines, "")

    return compressedJsonString
end

local function get_collection_custom_value(collection, inputKey, inputValue, outputKey)
    --[[
    This function retrieves a specific value (or checks existence) from a collection based on a given input key-value pair.

    Parameters:
    collection (table): The collection to search within.
    inputKey (string): The key within each item of the collection to match against `inputValue`.
    inputValue (any): The value to match against `inputKey` within the collection.
    outputKey (string or nil): Optional. The key within the matched item to retrieve its value.
                                If nil, function returns true if item is found; false otherwise.

    Returns:
    If `outputKey` is provided and the item is resolved, it returns its value or nil;
    otherwise, it returns true or false depending on whether the item was found within the collection.
    ]]
    for _, item in ipairs(collection) do
        if item[inputKey] == inputValue then
            if outputKey == nil then
                return true
            else
                return item[outputKey]
            end
        end
    end

    if outputKey == nil then
        return false
    else
        return nil
    end
end

local function ADD_MP_INDEX(statName, lastMpChar)
    local exceptions = {
        ["MP_CHAR_STAT_RALLY_ANIM"] = true,
        ["MP_CHAR_ARMOUR_1_COUNT"] = true,
        ["MP_CHAR_ARMOUR_2_COUNT"] = true,
        ["MP_CHAR_ARMOUR_3_COUNT"] = true,
        ["MP_CHAR_ARMOUR_4_COUNT"] = true,
        ["MP_CHAR_ARMOUR_5_COUNT"] = true,
    }

    if
        exceptions[statName] or (
            not startswith(statName, "MP_")
            and not startswith(statName, "MPPLY_")
        )
    then
        return "MP" .. lastMpChar .. "_" .. statName
    end

    return statName
end

local function is_phone_open()
	return (
        NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("cellphone_flashhand")) > 0
    ) and true or false
end

local function is_transition_active()
    return (
        NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("maintransition")) > 0
        or (
            NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("pi_menu")) == 0
            and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("am_pi_menu")) == 0
        )
        or (
            NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("main")) == 0
            and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("freemode")) == 0
        )
    ) and true or false
end

local function is_any_game_overlay_open()
    if NATIVES.HUD.IS_PAUSE_MENU_ACTIVE() then
        -- Doesn't work in SP
        return true
    end

    local scripts_list = {
        "maintransition",
        "pausemenu",
        "pausemenucareerhublaunch",
        "pausemenu_example",
        "pausemenu_map",
        "pausemenu_multiplayer",
        "pausemenu_sp_repeat",
        "apparcadebusiness",
        "apparcadebusinesshub",
        "appavengeroperations",
        "appbailoffice",
        "appbikerbusiness",
        "appbroadcast",
        "appbunkerbusiness",
        "appbusinesshub",
        "appcamera",
        "appchecklist",
        "appcontacts",
        "appcovertops",
        "appemail",
        "appextraction",
        "appfixersecurity",
        "apphackertruck",
        "apphs_sleep",
        "appimportexport",
        "appinternet",
        "appjipmp",
        "appmedia",
        "appmpbossagency",
        "appmpemail",
        "appmpjoblistnew",
        "apporganiser",
        "appprogresshub",
        "apprepeatplay",
        "appsecurohack",
        "appsecuroserv",
        "appsettings",
        "appsidetask",
        "appsmuggler",
        "apptextmessage",
        "apptrackify",
        "appvinewoodmenu",
        "appvlsi",
        "appzit",
    }

    for _, app in ipairs(scripts_list) do
        if NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key(app)) > 0 then
            return true
        end
    end

    return false
end

local function is_thread_runnning(threadId)
    if threadId and not menu.has_thread_finished(threadId) then
        return true
    end

    return false
end

local function remove_event_listener(eventType, listener)
    if listener and event.remove_event_listener(eventType, listener) then
        return
    end

    return listener
end

local function delete_thread(threadId)
    if threadId and menu.delete_thread(threadId) then
        return nil
    end

    return threadId
end

local function handle_script_exit(params)
    params = params or {}
    if params.clearAllNotifications == nil then
        params.clearAllNotifications = false
    end
    if params.hasScriptCrashed == nil then
        params.hasScriptCrashed = false
    end

    scriptExitEventListener = remove_event_listener("exit", scriptExitEventListener)

    if is_thread_runnning(sendChatMessageThread) then
        sendChatMessageThread = delete_thread(sendChatMessageThread)
    end

    -- This will delete notifications from other scripts too.
    -- Suggestion is open: https://discord.com/channels/1088976448452304957/1092480948353904752/1253065431720394842
    if params.clearAllNotifications then
        menu.clear_all_notifications()
    end

    if params.hasScriptCrashed then
        menu.notify("Oh no... Script crashed:(\nYou gotta restart it manually.", SCRIPT_NAME, 12, COLOR.RED)
        error()
    end

    menu.exit()
end

local function save_settings(params)
    params = params or {}
    if params.wasSettingsCorrupted == nil then
        params.wasSettingsCorrupted = false
    end

    local file, err = io.open(SCRIPT_SETTINGS__PATH, "w")
    if err then
        handle_script_exit({ hasScriptCrashed = true })
        return
    end

    local settingsContent = ""

    for _, setting in ipairs(ALL_SETTINGS) do
        if type(setting.defaultValue) == "boolean" then
            settingsContent = settingsContent .. setting.key .. "=" .. tostring(setting.feat.on) .. "\n"
        elseif type(setting.defaultValue) == "number" then
            settingsContent = settingsContent .. setting.key .. "=" .. tostring(setting.feat.value) .. "\n"
        else
            handle_script_exit({ hasScriptCrashed = true })
        end
    end

    file:write(settingsContent)

    file:close()

    if params.wasSettingsCorrupted then
        menu.notify("Settings file were corrupted but have been successfully restored and saved.", SCRIPT_TITLE, 6, COLOR.ORANGE)
    else
        menu.notify("Settings successfully saved.", SCRIPT_TITLE, 6, COLOR.GREEN)
    end
end

local function load_settings(params)
    local function custom_str_to_bool(string, onlyMatchAgainst)
        --[[
        This function returns the boolean value represented by the string for lowercase or any case variation;
        otherwise, nil.

        Args:
            string (str): The boolean string to be checked.
            (optional) onlyMatchAgainst (bool | None): If provided, the only boolean value to match against.
        ]]
        local needRewriteCurrentSetting = false
        local resolvedValue

        if string == nil then
            return nil, true -- Input is not a valid string
        end

        local stringLower = string:lower()

        if stringLower == "true" then
            resolvedValue = true
        elseif stringLower == "false" then
            resolvedValue = false
        end

        if resolvedValue == nil then
            return nil, true -- Input is not a valid boolean value
        end

        if (
            onlyMatchAgainst ~= nil
            and onlyMatchAgainst ~= resolvedValue
        ) then
            return nil, true -- Input does not match the specified boolean value
        end

        if string ~= tostring(resolvedValue) then
            needRewriteCurrentSetting = true
        end

        return resolvedValue, needRewriteCurrentSetting
    end

    params = params or {}
    if params.settings_to_load == nil then
        params.settings_to_load = {}

        for _, setting in ipairs(ALL_SETTINGS) do
            params.settings_to_load[setting.key] = setting.feat
        end
    end
    if params.isScriptStartup == nil then
        params.isScriptStartup = false
    end

    local settings_loaded = {}
    local areSettingsLoaded = false
    local hasResetSettings = false
    local needRewriteSettings = false
    local settingFileExisted = false

    if utils.file_exists(SCRIPT_SETTINGS__PATH) then
        settingFileExisted = true

        local settings_content, err = read_file(SCRIPT_SETTINGS__PATH)
        if err then
            menu.notify("Settings could not be loaded.", SCRIPT_TITLE, 6, COLOR.RED)
            handle_script_exit({ hasScriptCrashed = true })
            return areSettingsLoaded
        end

        for line in settings_content:gmatch("[^\r\n]+") do
            local key, value = line:match("^(.-)=(.*)$")
            if key and value ~= nil then
                if get_collection_custom_value(ALL_SETTINGS, "key", key) then
                    if params.settings_to_load[key] ~= nil then
                        settings_loaded[key] = value
                    end
                else
                    needRewriteSettings = true
                end
            else
                needRewriteSettings = true
            end
        end

        if not ends_with_newline(settings_content) then
            needRewriteSettings = true
        end

        areSettingsLoaded = true
    else
        hasResetSettings = true

        if not params.isScriptStartup then
            menu.notify("Settings file not found.", SCRIPT_TITLE, 6, COLOR.RED)
        end
    end

    for setting, _ in pairs(params.settings_to_load) do
        local resolvedSettingValue = get_collection_custom_value(ALL_SETTINGS, "key", setting, "defaultValue")

        if type(resolvedSettingValue) == "boolean" then
            local settingLoadedValue, needRewriteCurrentSetting = custom_str_to_bool(settings_loaded[setting])
            if settingLoadedValue ~= nil then
                resolvedSettingValue = settingLoadedValue
            end
            if needRewriteCurrentSetting then
                needRewriteSettings = true
            end

            params.settings_to_load[setting].on = resolvedSettingValue
        elseif type(resolvedSettingValue) == "number" then
            --  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            --  !! NEED TO IMPLEMENT IN ALL_SETTINGS, MAX and MIN or smth. !!
            --  !! THIS CODE IS SUBJECT TO USER INJECTION                  !!
            --  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            -- Handle number case (integers and floats)
            if math.floor(resolvedSettingValue) == resolvedSettingValue then -- It's an integer
                local number = tonumber(settings_loaded[setting])
                if number then
                    resolvedSettingValue = number
                else
                    needRewriteSettings = true
                end
            --else -- It's a float
            end

            params.settings_to_load[setting].value = resolvedSettingValue
        else
            handle_script_exit({ hasScriptCrashed = true })
        end
    end

    if not params.isScriptStartup then
        if hasResetSettings then
            menu.notify("Settings have been loaded and applied to their default values.", SCRIPT_TITLE, 6, COLOR.ORANGE)
        else
            menu.notify("Settings successfully loaded and applied.", SCRIPT_TITLE, 6, COLOR.GREEN)
        end
    end

    if needRewriteSettings then
        local wasSettingsCorrupted = settingFileExisted or false
        save_settings({ wasSettingsCorrupted = wasSettingsCorrupted })
    end

    return areSettingsLoaded
end
---- Global functions 2/2 END

---- Global event listeners START
scriptExitEventListener = event.add_event_listener("exit", function(f)
    handle_script_exit()
end)
---- Global event listeners END
-- Globals END


local unnecessaryPermissions = {}
local missingPermissions = {}

for _, flag in ipairs(TRUSTED_FLAGS) do
    if menu.is_trusted_mode_enabled(flag.bitValue) then
        if not flag.isRequiered then
            table.insert(unnecessaryPermissions, flag.menuName)
        end
    else
        if flag.isRequiered then
            table.insert(missingPermissions, flag.menuName)
        end
    end
end

if #unnecessaryPermissions > 0 then
    local unnecessaryPermissionsMessage = "You do not require the following " .. pluralize("permission", #unnecessaryPermissions) .. ":\n"
    for _, permission in ipairs(unnecessaryPermissions) do
        unnecessaryPermissionsMessage = unnecessaryPermissionsMessage .. permission .. "\n"
    end
    menu.notify(unnecessaryPermissionsMessage, SCRIPT_NAME, 6, COLOR.ORANGE)
end

if #missingPermissions > 0 then
    local missingPermissionsMessage = "You need to enable the following " .. pluralize("permission", #missingPermissions) .. ":\n"
    for _, permission in ipairs(missingPermissions) do
        missingPermissionsMessage = missingPermissionsMessage .. permission .. "\n"
    end
    menu.notify(missingPermissionsMessage, SCRIPT_NAME, 6, COLOR.RED)

    handle_script_exit()
end


-- === Main Menu Features === --
local myRootMenu_Feat = menu.add_feature(SCRIPT_TITLE, "parent", 0)

local exitScript_Feat = menu.add_feature("#FF0000DD#Stop Script#DEFAULT#", "action", myRootMenu_Feat.id, function(feat, pid)
    handle_script_exit()
end)
exitScript_Feat.hint = 'Stop "' .. SCRIPT_NAME .. '"'

menu.add_feature("<- - -  TRYHARD by IB_U_Z_Z_A_R_Dl  - - ->", "action", myRootMenu_Feat.id)

local idleCrosshairMenu_Feat = menu.add_feature("Idle Crosshair", "parent", myRootMenu_Feat.id)

local idleCrosshairSpriteID <const> = scriptdraw.register_sprite("scripts\\TRYHARD\\46.png")
local idleCrosshairPos <const> = v2(scriptdraw.pos_pixel_to_rel_x(scriptdraw.pos_rel_to_pixel_x(0)), scriptdraw.pos_pixel_to_rel_y(scriptdraw.pos_rel_to_pixel_y(0)))
local idleCrosshairDefaultColor <const> = rgba_to_int(255, 255, 255, 255)

local idleCrosshairSize = 1
local idleCrosshairColor = idleCrosshairDefaultColor

-- TODO: hideIdleCrosshairInInteractionMenu
-- TODO: hideIdleCrosshairInTwoTakeOneConsole
local hideIdleCrosshairInVehicles_Feat
local hideIdleCrosshairInChatMenu_Feat
local hideIdleCrosshairInPhoneMenu_Feat
local hideIdleCrosshairInTwoTakeOneMenu_Feat

local idleCrosshair_Feat = menu.add_feature("Idle Crosshair", "toggle", idleCrosshairMenu_Feat.id, function(f)
    while f.on do
        system.yield()

        local drawCrosshair = true
        local playerID
        local playerPed

        if (
            NATIVES.HUD.IS_PAUSE_MENU_ACTIVE()
            or NATIVES.HUD.IS_WARNING_MESSAGE_ACTIVE()
            or NATIVES.HUD.IS_WARNING_MESSAGE_READY_FOR_CONTROL()
            or NATIVES.HUD.IS_NAVIGATING_MENU_CONTENT()
            or is_transition_active()
            or is_any_game_overlay_open()
            or (hideIdleCrosshairInChatMenu_Feat.on and NATIVES.HUD.IS_MP_TEXT_CHAT_TYPING())
            or (hideIdleCrosshairInPhoneMenu_Feat.on and is_phone_open())
            or (hideIdleCrosshairInTwoTakeOneMenu_Feat.on and menu.is_open())
        ) or not (
            ui.is_hud_component_active(14)
            and NATIVES.HUD.IS_MINIMAP_RENDERING()
        ) then
            drawCrosshair = false
        end

        if drawCrosshair then
            playerID = player.player_id()

            if (
                cutscene.is_cutscene_playing()
                or cutscene.is_cutscene_active()
                or NATIVES.NETWORK.NETWORK_IS_PLAYER_IN_MP_CUTSCENE(playerID)
                or NATIVES.NETWORK.IS_PLAYER_IN_CUTSCENE(playerID)
                or NATIVES.NETWORK.NETWORK_IS_PLAYER_FADING(playerID)
                or NATIVES.PLAYER.IS_PLAYER_DEAD(playerID)
            ) or not (
                NATIVES.NETWORK.NETWORK_IS_PLAYER_CONNECTED(playerID)
                and NATIVES.NETWORK.NETWORK_IS_PLAYER_ACTIVE(playerID)
                and NATIVES.PLAYER.IS_PLAYER_PLAYING(playerID)
            ) then
                drawCrosshair = false
            end
        end

        if drawCrosshair then
            playerPed = player.player_ped()

            if NATIVES.PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
                if
                    hideIdleCrosshairInVehicles_Feat.on
                    or (
                        NATIVES.PLAYER.IS_PLAYER_FREE_AIMING(playerID)
                        or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, 190) -- CTaskMountThrowProjectile
                    )
                then
                    drawCrosshair = false
                end
            else
                if
                    NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, 15)     -- CTaskDoNothing (scripted player moves (ex: when reaching a laptop))
                    or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, 135) -- CTaskSynchronizedScene (ex:player using laptop / transitions)
                    or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, 997) -- CTaskDyingDead
                    or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, 289) -- CTaskAimAndThrowProjectile -- Downside is that it adds the [BUG] bellow...
                then
                    drawCrosshair = false
                end

                if (
                    NATIVES.PLAYER.IS_PLAYER_FREE_AIMING(playerID)
                    and NATIVES.WEAPON.IS_PED_WEAPON_READY_TO_SHOOT(playerPed)
                    and NATIVES.WEAPON.GET_SELECTED_PED_WEAPON(playerPed) ~= gameplay.get_hash_key("weapon_hominglauncher") -- Alternative: WEAPON.GET_CURRENT_PED_WEAPON
                ) and not (
                    NATIVES.PED.IS_PED_SWITCHING_WEAPON(playerPed)
                ) then
                    -- [BUG]: When the player aims in 1rd person view with a "ThrowProjectile", the crosshair is not rendering while not aiming.
                    -- [BUG]: When the player aims in 3rd person view, for a short moment it doesn't have any crosshair. (this is due to camera adjusting)
                    drawCrosshair = false
                end
            end
        end

        if drawCrosshair then
            scriptdraw.draw_sprite(
                idleCrosshairSpriteID, -- id
                idleCrosshairPos,      -- pos
                idleCrosshairSize,   -- scale
                0,                     -- rot
                idleCrosshairColor   -- color
            )
        end
    end
end)
idleCrosshair_Feat.hint = "Always render a crosshair when you are not aiming with a gun."

menu.add_feature("<- - - - - - - -  Options  - - - - - - - ->", "action", idleCrosshairMenu_Feat.id)

hideIdleCrosshairInVehicles_Feat = menu.add_feature("Hide Idle Crosshair in Vehicles", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInVehicles_Feat.hint = "Stops the idle crosshair rendering when in vehicles."

hideIdleCrosshairInChatMenu_Feat = menu.add_feature("Hide Idle Crosshair if Chat Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInChatMenu_Feat.hint = "Stops the idle crosshair rendering when the chat menu is opened."

hideIdleCrosshairInPhoneMenu_Feat = menu.add_feature("Hide Idle Crosshair if Phone Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInPhoneMenu_Feat.hint = "Stops the idle crosshair rendering when the phone menu is opened."

hideIdleCrosshairInTwoTakeOneMenu_Feat = menu.add_feature("Hide Idle Crosshair if 2Take1 Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInTwoTakeOneMenu_Feat.hint = "Stops the idle crosshair rendering when the Stand menu is opened."

local hotkeySuicideMenu_Feat = menu.add_feature("Hotkey Suicide", "parent", myRootMenu_Feat.id)

local hotkeyWeaponThermalVisionMenu_Feat = menu.add_feature("Hotkey Weapon Thermal Vision", "parent", myRootMenu_Feat.id)

local autoRefillSnacksAndArmorsMenu_Feat = menu.add_feature("Auto Refill Snacks & Armors", "parent", myRootMenu_Feat.id)

local autoRefillSnacksAndArmors_Feat = menu.add_feature("Auto Refill Snacks & Armors", "toggle", autoRefillSnacksAndArmorsMenu_Feat.id, function(f)
    while f.on do
        system.yield()

        if
            network.is_session_started()
            and player.get_host() ~= -1
        then
            local lastMpChar = stats.stat_get_int(gameplay.get_hash_key("MPPLY_LAST_MP_CHAR"), -1)

            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NO_BOUGHT_YUM_SNACKS", lastMpChar)), 30, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NO_BOUGHT_HEALTH_SNACKS", lastMpChar)), 15, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NO_BOUGHT_EPIC_SNACKS", lastMpChar)), 5, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NUMBER_OF_ORANGE_BOUGHT", lastMpChar)), 10, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NUMBER_OF_BOURGE_BOUGHT", lastMpChar)), 10, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NUMBER_OF_CHAMP_BOUGHT", lastMpChar)), 5, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("CIGARETTES_BOUGHT", lastMpChar)), 20, true)
            stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("NUMBER_OF_SPRUNK_BOUGHT", lastMpChar)), 10, true)
            for i = 1, 5 do
                stats.stat_set_int(gameplay.get_hash_key(ADD_MP_INDEX("MP_CHAR_ARMOUR_" .. i .. "_COUNT", lastMpChar)), 10, true)
            end

            system.wait(10000) -- No need to spam it.
        end
    end
end)
autoRefillSnacksAndArmors_Feat.hint = "Automatically refill selected Snacks & Armor every 10 seconds."

menu.add_feature("<- - - - - - - -  Snacks to Refill  - - - - - - - ->", "action", autoRefillSnacksAndArmorsMenu_Feat.id)

local autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat = menu.add_feature("P'S & Q's", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat.hint = 'Number of "P\'S & Q\'s" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat.max = 30

local autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat = menu.add_feature("EgoChaser", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat.hint = 'Number of "EgoChaser" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat.max = 15

local autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat = menu.add_feature('Meteorite', "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat.hint = 'Number of "Meteorite" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat.max = 5

local autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat = menu.add_feature("eCola", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat.hint = 'Number of "eCola" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat.max = 10

local autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat = menu.add_feature("Pisswasser", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat.hint = 'Number of "Pisswasser" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat.max = 10

local autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat = menu.add_feature("Blêuter'd Champagne", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat.hint = 'Number of "Blêuter\'d Champagne" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat.max = 5

local autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat = menu.add_feature("Smokes", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat.hint = 'Number of "Smokes" to refill.'
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat.max = 20

local autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat = menu.add_feature("Sprunk", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat.hint = 'Number of "Sprunk" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat.max = 10

menu.add_feature("<- - - - - - - - -  Armors to Refill  - - - - - - - - ->", "action", autoRefillSnacksAndArmorsMenu_Feat.id)

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat = menu.add_feature("Super Light Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat.hint = 'Number of "Super Light Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat = menu.add_feature("Light Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat.hint = 'Number of "Light Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat = menu.add_feature("Standard Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat.hint = 'Number of "Standard Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat = menu.add_feature("Heavy Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat.hint = 'Number of "Heavy Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat = menu.add_feature("Super Heavy Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu_Feat.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat.hint = 'Number of "Super Heavy Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat.max = 10


local myGlobals = {}

myGlobals.online_thermal__bypass = function(playerID)
    --[[
    This function bypass so that you have thermal vision online all the time. (BEHAVIOUR WITHOUT BYPASS: Only apply thermal while scoping with MKII Heavy Sniper)

    Parameters:
    playerID (int): Your Player ID.

    Returns:
    uint32_t (int) The number returned from this Global.

    Credits:
    Thanks Gee-Skid for Thermal Vision source code (natives & 1.68 Globals).

    More Infos:
    These Globals are from 1.69 online version (build 3258)

    How to update after new build update:
    Global_1  --> (Global_1845281[iVar0 /*883*/].f_)
    Global_2  --> (Global_1845281[iVar0 /*883*/].f_)
    unknown_3 --> for i, in (800, 900) do ... |  Was 844 in 1.68, I do not know how to find this unknown type value other then using a for loop.
    ]]
    local Global_1 = 1845281
    local Global_2 = 883
    local unknown_3 = 860
    return Global_1 + (playerID * Global_2) + unknown_3 + 1
end

local function exec_global(featureName, globalExecType, myGlobalFunction, params)
    --[[
    Parameters:
    featureName (string):
    globalExecType (string):
    myGlobalFunction (function):
    params: Optional.
        State (bool):
        notifyOnFailure (bool): Wathever you want or not to force displaying the "Prevented executing outdated Global" message.

    Returns:
    nil: The game version is not compatible with the given Global.
    bool The status returned from the given Global.
    ]]

    params = params or {}
    if params.forceNotifyOnFailure == nil then
        params.forceNotifyOnFailure = false
    end

    if SCRIPT_THIS_ONLINE_VERSION ~= SCRIPT_SUPPORTED_ONLINE_VERSION then
        if params.forceNotifyOnFailure or globalExecType == "set_global_f" or  globalExecType == "set_global_i" or globalExecType == "set_global_s" then
            menu.notify('Prevented executing an outdated Global.\nExpect "' .. featureName .. '" feature to be unstable.', SCRIPT_NAME, 12, COLOR.ORANGE)
        end

        return
    end

    if globalExecType == "set_global_i" then
        return script.set_global_i(myGlobalFunction(player.player_id()), params.state)
    elseif globalExecType == "get_global_i" then
        return script.get_global_i(myGlobalFunction(player.player_id()))
    end

    handle_script_exit({ hasScriptCrashed = true })
end

local forceThermalVision_Feat = menu.add_feature("Force Thermal Vision", "toggle", myRootMenu_Feat.id, function(f)
    local notifyOnFailure__flag = true

    while true do
        if not f.on then
            if exec_global("Thermal Vision", "get_global_i", myGlobals.online_thermal__bypass, { forceNotifyOnFailure = notifyOnFailure__flag }) == 1 then
                exec_global("Thermal Vision", "set_global_i", myGlobals.online_thermal__bypass, { state = 0 })
            end

            if NATIVES.GRAPHICS.GET_USINGSEETHROUGH() then
                NATIVES.GRAPHICS.SET_SEETHROUGH(false)
            end

            NATIVES.GRAPHICS.SEETHROUGH_RESET()

            return
        end

        if not NATIVES.GRAPHICS.GET_USINGSEETHROUGH() then
            local getGlobalResult = exec_global("Thermal Vision", "get_global_i", myGlobals.online_thermal__bypass, { forceNotifyOnFailure = notifyOnFailure__flag })
            if getGlobalResult == 0 then
                exec_global("Thermal Vision", "set_global_i", myGlobals.online_thermal__bypass, { state = 1 })
            end
            NATIVES.GRAPHICS.SET_SEETHROUGH(true)

            -- If the bypass Global cannot be used, at least we can spam the native, it'll works with the MKII Heavy Sniper while aiming w it lmfao
            if getGlobalResult ~= nil then
                return
            end

            notifyOnFailure__flag = false
        end

        system.yield()
    end
end)
forceThermalVision_Feat.hint = "Enables the thermal vision view."

local noCombatRollCooldown_Feat = menu.add_feature("No Combat Roll Cooldown", "toggle", myRootMenu_Feat.id)

local autoBST_Feat = menu.add_feature("Auto Bull Shark Testosterone (BST)", "toggle", myRootMenu_Feat.id, function(f)
    local getBst_Feat = menu.get_feature_by_hierarchy_key("online.services.bull_shark_testosterone")
    local playerVisible_startTime
    local playerDied = false

    while f.on do
        local get_bst = false

        if NATIVES.PLAYER.IS_PLAYER_DEAD(player.player_id()) or entity.is_entity_dead(player.player_ped()) then
            playerDied = true
        elseif player.is_player_playing(player.player_id()) then
            if playerDied then
                if playerVisible_startTime then
                    if (os.clock() - playerVisible_startTime) >= 1 then -- 0.5 is the strict minimal.
                        playerVisible_startTime = nil
                        playerDied = nil
                        get_bst = true
                    end
                else
                    playerVisible_startTime = os.clock()
                end
            else
                get_bst = true
            end
        end
        if get_bst then
            if
                network.is_session_started()
                and player.get_host() ~= -1
                and not NATIVES.STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
                and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("maintransition")) == 0
                and (
                    NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("pi_menu")) == 0
                    and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("am_pi_menu")) == 1
                ) and (
                    NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("main")) == 0
                    and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("freemode")) == 1
                )
            then
                getBst_Feat:toggle()
            end
        end

        system.yield()
        -- TODO: Removes BST when un-toggled, unfortunately idk how to check if BST is currently active or not.
    end
end)
autoBST_Feat.hint = "Automatically gives you Bull Shark Testosterone whenever you die or its timer expires."

menu.add_feature("<- - - - - - -  2Take1 shortcuts  - - - - - - ->", "action", myRootMenu_Feat.id)

local infiniteAmmo_Feat = menu.add_feature("Infinite Ammo", "action", myRootMenu_Feat.id, function(f)
    local feat = menu.get_feature_by_hierarchy_key("local.weapons.auto_refill_ammo")
    feat.parent:toggle()
    feat:select()
end)

local noWantedLevel_Feat = menu.add_feature("No Wanted Level", "action", myRootMenu_Feat.id, function(f)
    local feat = menu.get_feature_by_hierarchy_key("local.player_options.lawless_mode")
    feat.parent:toggle()
    feat:select()
end)

local disablePhoneCalls_Feat = menu.add_feature("Disable Phone Calls", "action", myRootMenu_Feat.id, function(f)
    local feat = menu.get_feature_by_hierarchy_key("local.misc.disable_phone_calls")
    feat.parent:toggle()
    feat:select()
end)

menu.add_feature("<- - - - - - - -  Script Settings  - - - - - - - ->", "action", myRootMenu_Feat.id)

local settingsMenu_Feat = menu.add_feature("Settings", "parent", myRootMenu_Feat.id)
settingsMenu_Feat.hint = "Options for the script."

ALL_SETTINGS = {
    {key = "idleCrosshair", defaultValue = false, feat = idleCrosshair_Feat},
    {key = "hideIdleCrosshairInVehicles", defaultValue = true, feat = hideIdleCrosshairInVehicles_Feat},
    {key = "hideIdleCrosshairInChatMenu", defaultValue = true, feat = hideIdleCrosshairInChatMenu_Feat},
    {key = "hideIdleCrosshairInPhoneMenu", defaultValue = true, feat = hideIdleCrosshairInPhoneMenu_Feat},
    {key = "hideIdleCrosshairInTwoTakeOneMenu", defaultValue = true, feat = hideIdleCrosshairInTwoTakeOneMenu_Feat},

    {key = "autoRefillSnacksAndArmors", defaultValue = false, feat = autoRefillSnacksAndArmors_Feat},

    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS", defaultValue = 30, feat = autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat},
    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS", defaultValue = 15, feat = autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat},
    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS", defaultValue = 5, feat = autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT", defaultValue = 5, feat = autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat},
    {key = "autoRefillSnacksAndArmors__CIGARETTES_BOUGHT", defaultValue = 20, feat = autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat},

    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat},

    {key = "forceThermalVision", defaultValue = false, feat = forceThermalVision_Feat},
    {key = "noCombatRollCooldown", defaultValue = false, feat = noCombatRollCooldown_Feat},
    {key = "autoBST", defaultValue = false, feat = autoBST_Feat},
}

local loadSettings_Feat = menu.add_feature('Load Settings', "action", settingsMenu_Feat.id, function()
    load_settings()
end)
loadSettings_Feat.hint = 'Load saved settings from your file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".\n\nDeleting this file will apply the default settings.'

local saveSettings_Feat = menu.add_feature('Save Settings', "action", settingsMenu_Feat.id, function()
    save_settings()
end)
saveSettings_Feat.hint = 'Save your current settings to the file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".'


load_settings({ isScriptStartup = true })
