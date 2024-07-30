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
local INPUT <const> = {
    WEAPON_SPECIAL_TWO = 54,
}
local CTask <const> = {
    --[[
    https://alloc8or.re/gta5/doc/enums/eTaskTypeIndex.txt
    WARNING: values can change after a game update
    if R* adds in the middle!
    This is up-to-date for b3274
    ]]
    DoNothing = 15, -- scripted player movements. ex: walking over to a laptop/car door
    SynchronizedScene = 135, -- player using laptop/in transitions
	EnterVehicle = 160,
    GoToCarDoorAndStandStill = 195,
    AimGunBlindFire = 304,
}
local PRF <const> = {
    --[[
    (PRF = PED RESET FLAG)
    gta v source\src\dev_ng\game\Peds\PedFlags.cpp
    gta v source\src\dev_ng\game\Peds\PedFlagsMeta.psc
    gta v source\src\dev_ng\game\script_headers\commands_ped.sch
    WARNING: values can change after a game update
    if R* adds in the middle!
    This is up-to-date for b3274
    ]]
    DoingCombatRoll = 254,
}
local PCF <const> = {
    --[[
    (PCF = PED CONFIG FLAG)
    gta v source\src\dev_ng\game\Peds\PedFlags.cpp
    gta v source\src\dev_ng\game\Peds\PedFlagsMeta.psc
    gta v source\src\dev_ng\game\script_headers\commands_ped.sch
    WARNING: values can change after a game update
    if R* adds in the middle!
    This is up-to-date for b3274
    ]]
    IsAimingGun = 78,
}
local Global <const> = {
    --[[
    This is up-to-date for b3274
                       --> "How to update after new build update"
    ]]
    gsbd_fm = 1845281, --> (Global_1845281[iVar0 /*883*/].f_)
    unknown_1 = 883,   --> (Global_1845281[iVar0 /*883*/].f_)
    unknown_2 = 860,   --> for i, in (800, 900) do ... |  Was 844 in 1.68, I do not know how to find this unknown type value other then using a for loop.
}
--[[
This Global bypass so that you have thermal vision online all the time. (BEHAVIOUR WITHOUT BYPASS: Only apply thermal while scoping with MKII Heavy Sniper)

Credits:
Gee-Skid for Thermal Vision source code (natives & 1.68 Globals).
]]
Global.online_thermal__bypass = Global.gsbd_fm + (player.player_id() * Global.unknown_1) + Global.unknown_2 + 1
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
local function pluralize(word, count)
    return word .. (count > 1 and "s" or "")
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

local function is_ped_in_combatroll(playerPed)
    return (
        NATIVES.PED.GET_PED_RESET_FLAG(playerPed, PRF.DoingCombatRoll)
    )
end

local function is_thermal_vision_enabled()
    return NATIVES.GRAPHICS.GET_USINGSEETHROUGH()
end

local function is_any_cutscene_playing(playerID)
    return (
        cutscene.is_cutscene_playing()
        or cutscene.is_cutscene_active()
        or NATIVES.NETWORK.NETWORK_IS_PLAYER_IN_MP_CUTSCENE(playerID)
        or NATIVES.NETWORK.IS_PLAYER_IN_CUTSCENE(playerID)
    )
end

local function is_phone_open()
    return NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("cellphone_flashhand")) > 0
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
    )
end

local function is_session_started()
    return (
        network.is_session_started()
        and player.get_host() ~= -1
        and not NATIVES.STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
        and not is_transition_active()
        and (
            NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("pi_menu")) == 0
            and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("am_pi_menu")) == 1
        ) and (
            NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("main")) == 0
            and NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("freemode")) == 1
        )
    )
end

local function is_player_playing(playerID)
    return (
        player.is_player_playing(playerID)
        and NATIVES.PLAYER.IS_PLAYER_PLAYING(playerID)
        and NATIVES.NETWORK.NETWORK_IS_PLAYER_CONNECTED(playerID)
        and NATIVES.NETWORK.NETWORK_IS_PLAYER_ACTIVE(playerID)
    )
end

local function is_player_free_aiming_with_crosshair_reticle(playerID, playerPed)
    -- TODO: Add an "is camera aim moving and aiming" parameter.
    --if (!rPed.GetPedResetFlag(CPED_RESET_FLAG_IsAimingFromCover) && !rPed.GetPedResetFlag(CPED_RESET_FLAG_IsPeekingFromCover) && !rPed.GetPedResetFlag(CPED_RESET_FLAG_IsBlindFiring))
    if NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, CTask.AimGunBlindFire) then
        return false
    end

    if NATIVES.PED.GET_PED_CONFIG_FLAG(playerPed, PCF.IsAimingGun, true) then
        if
            NATIVES.PED.GET_PED_RESET_FLAG(playerPed, 143)
        then
            return false
        end
        return true
    end


    --if
    --    player.is_player_free_aiming(playerID)
    --    or NATIVES.PED.GET_PED_CONFIG_FLAG(playerPed, PCF.IsAimingGun, true)
    --then
    --    return true
    --end

    return false
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

local function add_mp_index(statName, lastMpChar)
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

local function set_snack_or_armor(snackOrArmorName, quantity)
    if not is_session_started() then
        return false
    end

    local lastMpChar = stats.stat_get_int(gameplay.get_hash_key("MPPLY_LAST_MP_CHAR"), -1)

    return stats.stat_set_int(gameplay.get_hash_key(add_mp_index(snackOrArmorName, lastMpChar)), quantity, true)
end

local function is_thread_running(threadId)
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

    if is_thread_running(sendChatMessageThread) then
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

local function exec_global(featureName, globalExecType, global, params)
    --[[
    Parameters:
    featureName (string):
    globalExecType (string):
    global (int):
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
        return script.set_global_i(global, params.state)
    elseif globalExecType == "get_global_i" then
        return script.get_global_i(global)
    end

    handle_script_exit({ hasScriptCrashed = true })
end

local function enable_thermal_vision()
    local function bypass_online()
        local getGlobalResult = exec_global("Thermal Vision", "get_global_i", Global.online_thermal__bypass, { forceNotifyOnFailure = true })
        if getGlobalResult == 0 then
            exec_global("Thermal Vision", "set_global_i", Global.online_thermal__bypass, { state = 1 })
        end
        return getGlobalResult
    end

    local getGlobalResult

    if is_session_started() then
        getGlobalResult = bypass_online()
    end

    if not is_thermal_vision_enabled() then
        NATIVES.GRAPHICS.SET_SEETHROUGH(true)
    end
    --GRAPHICS._SEETHROUGH_SET_MAX_THICKNESS(50.0)

    return getGlobalResult
end

local function disable_thermal_vision()
    local function bypass_online()
        local getGlobalResult = exec_global("Thermal Vision", "get_global_i", Global.online_thermal__bypass, { forceNotifyOnFailure = true })
        if getGlobalResult == 1 then
            exec_global("Thermal Vision", "set_global_i", Global.online_thermal__bypass, { state = 0 })
        end
        return getGlobalResult
    end

    local getGlobalResult

    if is_session_started() then
        getGlobalResult = bypass_online()
    end

    if is_thermal_vision_enabled() then
        NATIVES.GRAPHICS.SET_SEETHROUGH(false)
    end
    --GRAPHICS._SEETHROUGH_SET_MAX_THICKNESS(1.0)
    --NATIVES.GRAPHICS.SEETHROUGH_RESET()

    return getGlobalResult
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
            menu.notify("Settings file could not be read.", SCRIPT_TITLE, 6, COLOR.RED)
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

    for settingKey, setting_Feat in pairs(params.settings_to_load) do
        local defaultSettingValue = get_collection_custom_value(ALL_SETTINGS, "key", settingKey, "defaultValue")
        local resolvedSettingValue = defaultSettingValue

        if type(defaultSettingValue) == "boolean" then
            local settingLoadedValue, needRewriteCurrentSetting = custom_str_to_bool(settings_loaded[settingKey])
            if settingLoadedValue ~= nil then
                resolvedSettingValue = settingLoadedValue
            end
            if needRewriteCurrentSetting then
                needRewriteSettings = true
            end

            setting_Feat.on = resolvedSettingValue
        elseif type(defaultSettingValue) == "number" then
            --[[
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            !! NEED TO IMPLEMENT IN ALL_SETTINGS, MAX and MIN or smth. !!
            !!         THIS CODE IS SUBJECT TO USER INJECTION          !!
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            ]]
            if math.type(defaultSettingValue) == "integer" then
                local number = tonumber(settings_loaded[settingKey])
                if number and math.type(number) == "integer" then
                    resolvedSettingValue = number
                else
                    needRewriteSettings = true
                end

                setting_Feat.value = resolvedSettingValue
            elseif math.type(defaultSettingValue) == "float" then
                local number = tonumber(settings_loaded[settingKey])
                if number and math.type(number) == "float" then
                    resolvedSettingValue = number
                else
                    needRewriteSettings = true
                end

                setting_Feat.value = resolvedSettingValue  -- Note: 2Take1 represents idleCrosshairSize as 1.1000000238419 instead of 1.0. While this isn't technically an issue, it appears visually unappealing in the settings file.
            else
                handle_script_exit({ hasScriptCrashed = true })
            end
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
scriptExitEventListener = event.add_event_listener("exit", function()
    handle_script_exit()
end)
---- Global event listeners END
-- Globals END


-- Permissions Startup Checking START
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
    menu.notify("You do not require the following " .. pluralize("permission", #unnecessaryPermissions) .. ":\n" .. table.concat(unnecessaryPermissions, "\n"),
        SCRIPT_NAME, 6, COLOR.ORANGE)
end
if #missingPermissions > 0 then
    menu.notify(
        "You need to enable the following " .. pluralize("permission", #missingPermissions) .. ":\n" .. table.concat(missingPermissions, "\n"),
        SCRIPT_NAME, 6, COLOR.RED)
    handle_script_exit()
end
-- Permissions Startup Checking END


-- === Main Menu Features === --
local myRootMenu_Feat = menu.add_feature(SCRIPT_TITLE, "parent", 0)

local exitScript_Feat = menu.add_feature("#FF0000DD#Stop Script#DEFAULT#", "action", myRootMenu_Feat.id, function()
    handle_script_exit()
end)
exitScript_Feat.hint = 'Stop "' .. SCRIPT_NAME .. '"'

menu.add_feature("<- - -  TRYHARD by IB_U_Z_Z_A_R_Dl  - - ->", "action", myRootMenu_Feat.id)

local idleCrosshairMenu_Feat = menu.add_feature("Idle Crosshair", "parent", myRootMenu_Feat.id)

local idleCrosshairSpriteID <const> = scriptdraw.register_sprite("scripts\\TRYHARD\\46.png")
local idleCrosshairPos <const> = v2(scriptdraw.pos_pixel_to_rel_x(scriptdraw.pos_rel_to_pixel_x(0)), scriptdraw.pos_pixel_to_rel_y(scriptdraw.pos_rel_to_pixel_y(0)))
local idleCrosshairDefaultColor <const> = rgba_to_int(255, 255, 255, 255)

local idleCrosshairColor = idleCrosshairDefaultColor

local idleCrosshairSize_Feat
local hideIdleCrosshairInVehicles_Feat
local hideIdleCrosshairInChatMenu_Feat
local hideIdleCrosshairInPhoneMenu_Feat
local hideIdleCrosshairInTwoTakeOneMenu_Feat
-- TODO: hideIdleCrosshairInInteractionMenu_Feat
-- TODO: hideIdleCrosshairInTwoTakeOneConsole_Feat

local idleCrosshair_Feat = menu.add_feature("Idle Crosshair", "toggle", idleCrosshairMenu_Feat.id, function(f)
    while f.on do
        system.yield()

        local drawCrosshair = true
        local playerID = player.player_id()
        local playerPed = player.player_ped()

        if
            is_any_game_overlay_open()
            or is_transition_active()
            or NATIVES.HUD.IS_WARNING_MESSAGE_ACTIVE()
            or NATIVES.HUD.IS_WARNING_MESSAGE_READY_FOR_CONTROL()
            or (hideIdleCrosshairInChatMenu_Feat.on and NATIVES.HUD.IS_MP_TEXT_CHAT_TYPING())
            or (hideIdleCrosshairInPhoneMenu_Feat.on and is_phone_open())
            or (hideIdleCrosshairInTwoTakeOneMenu_Feat.on and menu.is_open())
            or is_any_cutscene_playing(playerID)
            or NATIVES.NETWORK.NETWORK_IS_PLAYER_FADING(playerID)
            or NATIVES.PLAYER.IS_PLAYER_DEAD(playerID)
            or entity.is_entity_dead(playerPed)
            or not ui.is_hud_component_active(14)
            or not NATIVES.HUD.IS_MINIMAP_RENDERING()
            or not is_player_playing(playerID)
        then
            drawCrosshair = false
        end

        if drawCrosshair then
            if ped.is_ped_in_any_vehicle(playerPed) then
                if
                    hideIdleCrosshairInVehicles_Feat.on
                    or is_player_free_aiming_with_crosshair_reticle(playerID, playerPed)
                then
                    drawCrosshair = false
                end
            else
                if
                    is_player_free_aiming_with_crosshair_reticle(playerID, playerPed) and (
                        NATIVES.WEAPON.GET_SELECTED_PED_WEAPON(playerPed) ~= gameplay.get_hash_key("weapon_hominglauncher")
                    )
                    or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, CTask.DoNothing) and not (
                        NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, CTask.EnterVehicle)
                        and NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, CTask.GoToCarDoorAndStandStill)
                    )
                    or NATIVES.TASK.GET_IS_TASK_ACTIVE(playerPed, CTask.SynchronizedScene)
                then
                    drawCrosshair = false
                end
            end
        end

        if drawCrosshair then
            scriptdraw.draw_sprite(
                idleCrosshairSpriteID,        -- id
                idleCrosshairPos,             -- pos
                idleCrosshairSize_Feat.value, -- scale
                0,                            -- rot
                idleCrosshairColor            -- color
            )
        end
    end
end)
idleCrosshair_Feat.hint = "Always render a crosshair when you are not aiming with a gun."

menu.add_feature("<- - - - - - - - - -  Options  - - - - - - - - - ->", "action", idleCrosshairMenu_Feat.id)

hideIdleCrosshairInVehicles_Feat = menu.add_feature("Hide Idle Crosshair in Vehicles", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInVehicles_Feat.hint = "Stops the idle crosshair rendering when in vehicles."

hideIdleCrosshairInChatMenu_Feat = menu.add_feature("Hide Idle Crosshair if Chat Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInChatMenu_Feat.hint = "Stops the idle crosshair rendering when the chat menu is opened."

hideIdleCrosshairInPhoneMenu_Feat = menu.add_feature("Hide Idle Crosshair if Phone Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInPhoneMenu_Feat.hint = "Stops the idle crosshair rendering when the phone menu is opened."

hideIdleCrosshairInTwoTakeOneMenu_Feat = menu.add_feature("Hide Idle Crosshair if 2Take1 Opened", "toggle", idleCrosshairMenu_Feat.id)
hideIdleCrosshairInTwoTakeOneMenu_Feat.hint = "Stops the idle crosshair rendering when the Stand menu is opened."

idleCrosshairSize_Feat = menu.add_feature("Idle Crosshair Size", "autoaction_value_f", idleCrosshairMenu_Feat.id)
idleCrosshairSize_Feat.hint = "Changes the rendered idle crosshair size."
idleCrosshairSize_Feat.min = 0.20
idleCrosshairSize_Feat.max = 1.50
idleCrosshairSize_Feat.mod = 0.10

local hotkeySuicideMenu_Feat = menu.add_feature("Hotkey Suicide", "parent", myRootMenu_Feat.id)

local thermalVisionMenu_Feat = menu.add_feature("Thermal Vision", "parent", myRootMenu_Feat.id)

local weaponHotkeyThermalVision_Feat

local forceThermalVision_Feat = menu.add_feature("Force Thermal Vision", "toggle", thermalVisionMenu_Feat.id, function(f)
    if not f.on then
        return
    end

    if weaponHotkeyThermalVision_Feat.on then
        weaponHotkeyThermalVision_Feat.on = false
    end

    while f.on do
        system.yield()

        enable_thermal_vision()
    end

    disable_thermal_vision()
end)
forceThermalVision_Feat.hint = "Enables the thermal vision view."

local disableThermalVisionOffAim_Feat
local rememberThermalVisionLastState_Feat
local reloadWithThermalVision_Feat
local combatRollWithThermalVision_Feat

weaponHotkeyThermalVision_Feat = menu.add_feature("Weapon Hotkey Thermal Vision", "toggle", thermalVisionMenu_Feat.id, function(f)
    if not f.on then
        return
    end

    if forceThermalVision_Feat.on then
        forceThermalVision_Feat.on = false
    end

    local thermalVisionState = false

    while f.on do
        system.yield()

        local playerID = player.player_id()
        local playerPed = player.player_ped()

        local enableThermalThisFrame = (rememberThermalVisionLastState_Feat.on and thermalVisionState) or false

        if is_player_free_aiming_with_crosshair_reticle(playerID, playerPed) and not player.is_player_in_any_vehicle(playerID) then
            if controls.is_control_just_pressed(0, INPUT.WEAPON_SPECIAL_TWO) then
                if is_thermal_vision_enabled() then
                    enableThermalThisFrame, thermalVisionState = false, false
                else
                    enableThermalThisFrame, thermalVisionState = true, true
                end
            else
                enableThermalThisFrame = thermalVisionState
            end
        else
            if not rememberThermalVisionLastState_Feat.on then
                enableThermalThisFrame, thermalVisionState = false, false
            end
            if disableThermalVisionOffAim_Feat.on then
                enableThermalThisFrame = false
            end
        end

        if enableThermalThisFrame then
            if (
                (not reloadWithThermalVision_Feat.on and NATIVES.PED.IS_PED_RELOADING(playerPed))
                or
                (not combatRollWithThermalVision_Feat.on and is_ped_in_combatroll(playerPed))
            ) then
                enableThermalThisFrame = false
            end
        end

        if enableThermalThisFrame then
            enable_thermal_vision()
        else
            disable_thermal_vision()
        end
    end

    disable_thermal_vision()
end)
weaponHotkeyThermalVision_Feat.hint = 'Makes it so when you aim with any gun, you can toggle thermal vision on "E" key.'

menu.add_feature("<- - - - - -  Weapon Hotkey Options  - - - - - ->", "action", thermalVisionMenu_Feat.id)

disableThermalVisionOffAim_Feat = menu.add_feature("Disable Thermal Vision Off-Aim", "toggle", thermalVisionMenu_Feat.id, function(f)
    if not f.on and not rememberThermalVisionLastState_Feat.on then
        rememberThermalVisionLastState_Feat.on = true
    end
end)
disableThermalVisionOffAim_Feat.hint = "Disable thermal vision when not aiming."

rememberThermalVisionLastState_Feat = menu.add_feature("Remember Thermal Vision Last State", "toggle", thermalVisionMenu_Feat.id, function(f)
    if not f.on and not disableThermalVisionOffAim_Feat.on then
        f.on = true
        menu.notify('You cannot disable "Remember Thermal Vision Last State" when "Disable Thermal Vision Off-Aim" is disabled.', SCRIPT_TITLE, 8, COLOR.ORANGE)
    end
end)
rememberThermalVisionLastState_Feat.hint = "Remember the last state of thermal vision when toggling."

reloadWithThermalVision_Feat = menu.add_feature("Reload with Thermal Vision", "toggle", thermalVisionMenu_Feat.id)
reloadWithThermalVision_Feat.hint = "Enable thermal vision when reloading weapons."

combatRollWithThermalVision_Feat = menu.add_feature("Combat Roll with Thermal Vision", "toggle", thermalVisionMenu_Feat.id)
combatRollWithThermalVision_Feat.hint = "Enable thermal vision during combat rolls."

local snacksAndArmorsMenu_Feat = menu.add_feature("Snacks & Armors", "parent", myRootMenu_Feat.id)

local autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat
local autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat
local autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat
local autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat
local autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat
local autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat
local autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat
local autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat
local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat
local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat
local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat
local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat
local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat

local autoRefillSnacksAndArmors_Feat = menu.add_feature("Auto Refill Snacks & Armors", "toggle", snacksAndArmorsMenu_Feat.id, function(f)
    while f.on do
        system.yield()

        if is_session_started() then
            set_snack_or_armor("NO_BOUGHT_YUM_SNACKS", autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat.value)
            set_snack_or_armor("NO_BOUGHT_HEALTH_SNACKS", autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat.value)
            set_snack_or_armor("NO_BOUGHT_EPIC_SNACKS", autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat.value)
            set_snack_or_armor("NUMBER_OF_ORANGE_BOUGHT", autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat.value)
            set_snack_or_armor("NUMBER_OF_BOURGE_BOUGHT", autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat.value)
            set_snack_or_armor("NUMBER_OF_CHAMP_BOUGHT", autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat.value)
            set_snack_or_armor("CIGARETTES_BOUGHT", autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat.value)
            set_snack_or_armor("NUMBER_OF_SPRUNK_BOUGHT", autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat.value)
            set_snack_or_armor("MP_CHAR_ARMOUR_1_COUNT", autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat.value)
            set_snack_or_armor("MP_CHAR_ARMOUR_2_COUNT", autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat.value)
            set_snack_or_armor("MP_CHAR_ARMOUR_3_COUNT", autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat.value)
            set_snack_or_armor("MP_CHAR_ARMOUR_4_COUNT", autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat.value)
            set_snack_or_armor("MP_CHAR_ARMOUR_5_COUNT", autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat.value)

            system.wait(10000) -- No need to spam it.
        end
    end
end)
autoRefillSnacksAndArmors_Feat.hint = "Automatically refill selected Snacks & Armor every 10 seconds."

menu.add_feature("<- - - - - - - -  Snacks to Refill  - - - - - - - ->", "action", snacksAndArmorsMenu_Feat.id)

autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat = menu.add_feature("P'S & Q's", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NO_BOUGHT_YUM_SNACKS", f.value)
end)
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat.hint = 'Number of "P\'s & Q\'s" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS_Feat.max = 30

autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat = menu.add_feature("EgoChaser", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NO_BOUGHT_HEALTH_SNACKS", f.value)
end)
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat.hint = 'Number of "EgoChaser" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS_Feat.max = 15

autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat = menu.add_feature('Meteorite', "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NO_BOUGHT_EPIC_SNACKS", f.value)
end)
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat.hint = 'Number of "Meteorite" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS_Feat.max = 5

autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat = menu.add_feature("eCola", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NUMBER_OF_ORANGE_BOUGHT", f.value)
end)
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat.hint = 'Number of "eCola" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT_Feat.max = 10

autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat = menu.add_feature("Pisswasser", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NUMBER_OF_BOURGE_BOUGHT", f.value)
end)
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat.hint = 'Number of "Pisswasser" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT_Feat.max = 10

autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat = menu.add_feature("Blêuter'd Champagne", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NUMBER_OF_CHAMP_BOUGHT", f.value)
end)
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat.hint = 'Number of "Blêuter\'d Champagne" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT_Feat.max = 5

autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat = menu.add_feature("Smokes", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("CIGARETTES_BOUGHT", f.value)
end)
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat.hint = 'Number of "Smokes" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT_Feat.max = 20

autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat = menu.add_feature("Sprunk", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("NUMBER_OF_SPRUNK_BOUGHT", f.value)
end)
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat.hint = 'Number of "Sprunk" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT_Feat.max = 10

menu.add_feature("<- - - - - - - - -  Armors to Refill  - - - - - - - - ->", "action", snacksAndArmorsMenu_Feat.id)

autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat = menu.add_feature("Super Light Armor", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("MP_CHAR_ARMOUR_1_COUNT", f.value)
end)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat.hint = 'Number of "Super Light Armor" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT_Feat.max = 10

autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat = menu.add_feature("Light Armor", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("MP_CHAR_ARMOUR_2_COUNT", f.value)
end)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat.hint = 'Number of "Light Armor" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT_Feat.max = 10

autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat = menu.add_feature("Standard Armor", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("MP_CHAR_ARMOUR_3_COUNT", f.value)
end)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat.hint = 'Number of "Standard Armor" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT_Feat.max = 10

autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat = menu.add_feature("Heavy Armor", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("MP_CHAR_ARMOUR_4_COUNT", f.value)
end)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat.hint = 'Number of "Heavy Armor" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT_Feat.max = 10

autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat = menu.add_feature("Super Heavy Armor", "action_value_i", snacksAndArmorsMenu_Feat.id, function(f)
    set_snack_or_armor("MP_CHAR_ARMOUR_5_COUNT", f.value)
end)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat.hint = 'Number of "Super Heavy Armor" to automatically refill.\n\nYou can also select it to add them to your inventory immediately.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT_Feat.max = 10

local legitAutoRefillAmmosmenu_Feat = menu.add_feature("Legit Auto Refill Ammos", "parent", myRootMenu_Feat.id)

local refillAmmo_Feat = menu.get_feature_by_hierarchy_key("local.weapons.refill_ammo")
local autoRefillAmmo_Feat = menu.get_feature_by_hierarchy_key("local.weapons.auto_refill_ammo")
local legitAutoRefillAmmosTimer_Feat

local legitAutoRefillAmmos_Feat = menu.add_feature("Legit Auto Refill Ammos", "toggle", legitAutoRefillAmmosmenu_Feat.id, function(f)
    -- Store the original state of autoRefillAmmo_Feat
    local originalAutoRefillState = autoRefillAmmo_Feat.on

    while f.on do
        -- Disable autoRefillAmmo_Feat if it is on
        if autoRefillAmmo_Feat.on then
            autoRefillAmmo_Feat.on = false
        end

        local reloadState = true
        local playerId = player.player_id()
        local playerPed = player.player_ped()

        local start_Time = os.clock()

        -- Wait for 3 seconds and check if player did not reload/aim during this time
        while os.clock() - start_Time < legitAutoRefillAmmosTimer_Feat.value do
            if is_player_free_aiming_with_crosshair_reticle(playerId, playerPed) or ped.is_ped_shooting(playerPed) then -- player.is_player_free_aiming(playerId) Not needed at least in my tests.
                reloadState = false
                break
            end
            system.yield(100) -- Prevent CPU overuse by adding a short delay
        end

        -- Refill ammo if the player did not reload/aim within the last 3 seconds
        if reloadState then
            refillAmmo_Feat:toggle()
        end

        system.yield(500) -- Adding a delay to prevent rapid refilling
    end

    -- Restore the original state of autoRefillAmmo_Feat when the toggle is turned off
    autoRefillAmmo_Feat.on = originalAutoRefillState
end)
legitAutoRefillAmmos_Feat.hint = "Automatically refill your ammo every [3-60] seconds when you're not aiming/shooting.\nThis mimics the time it takes for a macro to refill for legitimate players."

legitAutoRefillAmmosTimer_Feat = menu.add_feature("Refill Timer", "autoaction_value_i", legitAutoRefillAmmosmenu_Feat.id)
legitAutoRefillAmmosTimer_Feat.min = 3
legitAutoRefillAmmosTimer_Feat.max = 60
legitAutoRefillAmmosTimer_Feat.hint = "Allows you to choose the period of time to automatically refill your ammo."

local noCombatRollCooldown_Feat = menu.add_feature("No Combat Roll Cooldown", "toggle", myRootMenu_Feat.id)

local autoBST_Feat = menu.add_feature("Auto Bull Shark Testosterone (BST)", "toggle", myRootMenu_Feat.id, function(f)
    local getBST_Feat = menu.get_feature_by_hierarchy_key("online.services.bull_shark_testosterone")
    local playerVisible_startTime
    local playerDied = false

    while f.on do
        system.yield()

        local getBST = false
        local playerID = player.player_id()
        local playerPed = player.player_ped()

        if NATIVES.PLAYER.IS_PLAYER_DEAD(playerID) or entity.is_entity_dead(playerPed) then
            playerDied = true
        elseif is_player_playing(playerID) then
            if playerDied then
                if playerVisible_startTime then
                    if (os.clock() - playerVisible_startTime) >= 1 then -- 0.5 is the strict minimal.
                        playerVisible_startTime = nil
                        playerDied = nil
                        getBST = true
                    end
                else
                    playerVisible_startTime = os.clock()
                end
            else
                getBST = true
            end
        end
        if getBST then
            if is_session_started() then
                getBST_Feat:toggle()
            end
        end
    end

    --[[
    if not f.on then
    -- TODO: Removes BST when un-toggled, unfortunately idk how to check if BST is currently active or not.
    end
    ]]
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
    {key = "idleCrosshairSize", defaultValue = 1.0, feat = idleCrosshairSize_Feat},

    {key = "hideIdleCrosshairInVehicles", defaultValue = true, feat = hideIdleCrosshairInVehicles_Feat},
    {key = "hideIdleCrosshairInChatMenu", defaultValue = true, feat = hideIdleCrosshairInChatMenu_Feat},
    {key = "hideIdleCrosshairInPhoneMenu", defaultValue = true, feat = hideIdleCrosshairInPhoneMenu_Feat},
    {key = "hideIdleCrosshairInTwoTakeOneMenu", defaultValue = true, feat = hideIdleCrosshairInTwoTakeOneMenu_Feat},

    {key = "forceThermalVision", defaultValue = false, feat = forceThermalVision_Feat},
    {key = "hotkeyWeaponThermalVision", defaultValue = false, feat = weaponHotkeyThermalVision_Feat},
    {key = "disableThermalVisionOffAim", defaultValue = true, feat = disableThermalVisionOffAim_Feat},
    {key = "rememberThermalVisionLastState", defaultValue = false, feat = rememberThermalVisionLastState_Feat},
    {key = "reloadWithThermalVision", defaultValue = false, feat = reloadWithThermalVision_Feat},
    {key = "combatrollWithThermalVision", defaultValue = false, feat = combatRollWithThermalVision_Feat},

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

    {key = "legitAutoRefillAmmos", defaultValue = false, feat = legitAutoRefillAmmos_Feat},
    {key = "legitAutoRefillAmmosTimer", defaultValue = 3, feat = legitAutoRefillAmmosTimer_Feat},

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
