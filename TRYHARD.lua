-- Author: IB_U_Z_Z_A_R_Dl
-- Description: A script that aims in helping TRYHARD people for Stand menu.
-- GitHub Repository: https://github.com/Illegal-Services/TRYHARD-2Take1-Lua


-- Globals START
---- Global variables START
local scriptExitEventListener
---- Global variables END

---- Global constants 1/2 START
local SCRIPT_NAME <const> = "TRYHARD.lua"
local SCRIPT_TITLE <const> = "TRYHARD"
local SCRIPT_SETTINGS__PATH <const> = "scripts\\TRYHARD\\Settings.ini"
local HOME_PATH <const> = utils.get_appdata_path("PopstarDevs", "2Take1Menu")
local TRUSTED_FLAGS <const> = {
    { name = "LUA_TRUST_STATS", menuName = "Trusted Stats", bitValue = 1 << 0, isRequiered = true },
    { name = "LUA_TRUST_SCRIPT_VARS", menuName = "Trusted Globals / Locals", bitValue = 1 << 1, isRequiered = false },
    { name = "LUA_TRUST_NATIVES", menuName = "Trusted Natives", bitValue = 1 << 2, isRequiered = false },
    { name = "LUA_TRUST_HTTP", menuName = "Trusted Http", bitValue = 1 << 3, isRequiered = false },
    { name = "LUA_TRUST_MEMORY", menuName = "Trusted Memory", bitValue = 1 << 4, isRequiered = false }
}
---- Global constants 1/2 END

---- Global functions 1/2 START
local function rgb_to_int(R, G, B, A)
    A = A or 255
    return ((R&0x0ff)<<0x00)|((G&0x0ff)<<0x08)|((B&0x0ff)<<0x10)|((A&0x0ff)<<0x18)
end
---- Global functions 1/2 END

---- Global constants 2/2 START
local COLOR <const> = {
    RED = rgb_to_int(255, 0, 0, 255),
    ORANGE = rgb_to_int(255, 165, 0, 255),
    GREEN = rgb_to_int(0, 255, 0, 255)
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

function read_file(file_path)
    local file, err = io.open(file_path, "r")
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
        menu.notify("Oh no... Script crashed:(\nYou gotta restart it manually.", SCRIPT_NAME, 6, COLOR.RED)
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
    local function custom_str_to_bool(string, only_match_against)
        --[[
        This function returns the boolean value represented by the string for lowercase or any case variation;
        otherwise, nil.

        Args:
            string (str): The boolean string to be checked.
            (optional) only_match_against (bool | None): If provided, the only boolean value to match against.
        ]]
        local need_rewrite_current_setting = false
        local resolved_value = nil

        if string == nil then
            return nil, true -- Input is not a valid string
        end

        local string_lower = string:lower()

        if string_lower == "true" then
            resolved_value = true
        elseif string_lower == "false" then
            resolved_value = false
        end

        if resolved_value == nil then
            return nil, true -- Input is not a valid boolean value
        end

        if (
            only_match_against ~= nil
            and only_match_against ~= resolved_value
        ) then
            return nil, true -- Input does not match the specified boolean value
        end

        if string ~= tostring(resolved_value) then
            need_rewrite_current_setting = true
        end

        return resolved_value, need_rewrite_current_setting
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
local myRootMenu = menu.add_feature(SCRIPT_TITLE, "parent", 0)

local exitScriptFeat = menu.add_feature("#FF0000DD#Stop Script#DEFAULT#", "action", myRootMenu.id, function(feat, pid)
    handle_script_exit()
end)
exitScriptFeat.hint = 'Stop "' .. SCRIPT_NAME .. '"'

menu.add_feature("       " .. string.rep(" -", 23), "action", myRootMenu.id)

local autoRefillSnacksAndArmorsMenu = menu.add_feature("Auto Refill Snacks & Armors", "parent", myRootMenu.id)

local autoRefillSnacksAndArmors = menu.add_feature("Auto Refill Snacks & Armors", "toggle", autoRefillSnacksAndArmorsMenu.id, function(f)
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
autoRefillSnacksAndArmors.hint = "Automatically refill selected Snacks & Armor every 10 seconds."

menu.add_feature("---------------------------------------", "action", autoRefillSnacksAndArmorsMenu.id)
menu.add_feature("Snacks to Refill:", "action", autoRefillSnacksAndArmorsMenu.id)
menu.add_feature("---------------------------------------", "action", autoRefillSnacksAndArmorsMenu.id)

local autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS = menu.add_feature("P'S & Q's", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS.hint = 'Number of "P\'S & Q\'s" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS.max = 30

local autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS = menu.add_feature("EgoChaser", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS.hint = 'Number of "EgoChaser" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS.max = 15

local autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS = menu.add_feature('Meteorite', "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS.hint = 'Number of "Meteorite" to refill.'
autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS.max = 5

local autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT = menu.add_feature("eCola", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT.hint = 'Number of "eCola" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT.max = 10

local autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT = menu.add_feature("Pisswasser", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT.hint = 'Number of "Pisswasser" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT.max = 10

local autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT = menu.add_feature("Blêuter'd Champagne", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT.hint = 'Number of "Blêuter\'d Champagne" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT.max = 5

local autoRefillSnacksAndArmors__CIGARETTES_BOUGHT = menu.add_feature("Smokes", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT.hint = 'Number of "Smokes" to refill.'
autoRefillSnacksAndArmors__CIGARETTES_BOUGHT.max = 20

local autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT = menu.add_feature("Sprunk", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT.hint = 'Number of "Sprunk" to refill.'
autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT.max = 10

menu.add_feature("---------------------------------------", "action", autoRefillSnacksAndArmorsMenu.id)
menu.add_feature("Armors to Refill:", "action", autoRefillSnacksAndArmorsMenu.id)
menu.add_feature("---------------------------------------", "action", autoRefillSnacksAndArmorsMenu.id)

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT = menu.add_feature("Super Light Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT.hint = 'Number of "Super Light Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT = menu.add_feature("Light Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT.hint = 'Number of "Light Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT = menu.add_feature("Standard Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT.hint = 'Number of "Standard Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT = menu.add_feature("Heavy Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT.hint = 'Number of "Heavy Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT.max = 10

local autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT = menu.add_feature("Super Heavy Armor", "autoaction_value_i", autoRefillSnacksAndArmorsMenu.id)
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT.hint = 'Number of "Super Heavy Armor" to refill.'
autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT.max = 10

menu.add_feature("       " .. string.rep(" -", 23), "action", myRootMenu.id)

local autoBST = menu.add_feature("Auto Bull Shark Testosterone (BST)", "toggle", myRootMenu.id, function(f)
    local get_bst__feat = menu.get_feature_by_hierarchy_key("online.services.bull_shark_testosterone")
    local playerVisible__startTime
    local player_died = false

    while f.on do
        local get_bst = false

        if entity.is_entity_dead(player.player_ped()) then
            player_died = true
        elseif player.is_player_playing(player.player_id()) then
            if player_died then
                if playerVisible__startTime then
                    if (os.clock() - playerVisible__startTime) >= 1 then -- 0.5 is the strict minimal.
                        playerVisible__startTime = nil
                        player_died = nil
                        get_bst = true
                    end
                else
                    playerVisible__startTime = os.clock()
                end
            else
                get_bst = true
            end
        end
        if get_bst then
            if
                network.is_session_started()
                and player.get_host() ~= -1
            then
                get_bst__feat:toggle()
            end
        end

        system.yield()
        -- TODO: Removes BST when un-toggled, unfortunately idk how to check if BST is currently active or not.
    end
end)

local settingsMenu = menu.add_feature("Settings", "parent", myRootMenu.id)
settingsMenu.hint = "Options for the script."

ALL_SETTINGS = {
    {key = "autoRefillSnacksAndArmors", defaultValue = true, feat = autoRefillSnacksAndArmors},

    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS", defaultValue = 30, feat = autoRefillSnacksAndArmors__NO_BOUGHT_YUM_SNACKS},
    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS", defaultValue = 15, feat = autoRefillSnacksAndArmors__NO_BOUGHT_HEALTH_SNACKS},
    {key = "autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS", defaultValue = 5, feat = autoRefillSnacksAndArmors__NO_BOUGHT_EPIC_SNACKS},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_ORANGE_BOUGHT},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_BOURGE_BOUGHT},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT", defaultValue = 5, feat = autoRefillSnacksAndArmors__NUMBER_OF_CHAMP_BOUGHT},
    {key = "autoRefillSnacksAndArmors__CIGARETTES_BOUGHT", defaultValue = 20, feat = autoRefillSnacksAndArmors__CIGARETTES_BOUGHT},
    {key = "autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT", defaultValue = 10, feat = autoRefillSnacksAndArmors__NUMBER_OF_SPRUNK_BOUGHT},

    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_1_COUNT},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_2_COUNT},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_3_COUNT},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_4_COUNT},
    {key = "autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT", defaultValue = 10, feat = autoRefillSnacksAndArmors__MP_CHAR_ARMOUR_5_COUNT},

    {key = "autoBST", defaultValue = false, feat = autoBST}
}

local loadSettings = menu.add_feature('Load Settings', "action", settingsMenu.id, function()
    load_settings()
end)
loadSettings.hint = 'Load saved settings from your file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".\n\nDeleting this file will apply the default settings.'

local saveSettings = menu.add_feature('Save Settings', "action", settingsMenu.id, function()
    save_settings()
end)
saveSettings.hint = 'Save your current settings to the file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".'


load_settings({ isScriptStartup = true })
