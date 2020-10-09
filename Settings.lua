-- The name of the addon
AddonName       = "BracketBuddy"
AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Initialise the options table
local options =
{
    type = "group",
    name = AddonName .. " Options",
    args = { }
}

-- Toggle for the minimap icon display
options.args["minimapIcon"] =
{
    order   = 0,
    type    = "toggle",
    name    = "Hide minimap icon",
    desc    = "Use '/bb show' to show the " .. AddonName .. " window if hidden. Will reload the UI on change.",
    get     = function()
        return BracketBuddy.db.factionrealm.minimapIcon.hide
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.minimapIcon.hide = val
        ReloadUI()
    end
}

-- Minimap button description
options.args["minimapIconDesc"] =
{
    order   = 1,
    type    = "description",
    name    = "Use '/bb show' to show the " .. AddonName .. " window if hidden. Will reload the UI on change.\n\n"
}

-- Toggle for inviting padders from say
options.args["inviteSay"] =
{
    order   = 2,
    type    = "toggle",
    name    = "Invite from /say",
    desc    = "Invites players to the raid when a padding message is received in the /say chat channel.",
    get     = function()
        return BracketBuddy.db.factionrealm.inviteSettings.say
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.inviteSettings.say = val
    end
}

-- Invite from say description
options.args["inviteSayDesc"] =
{
    order   = 3,
    type    = "description",
    name    =   "Invites players to the raid when a padding message is received in the /say chat channel."  .. 
                "This is particularly useful if you have people trying to game the system by never actually making their way over to the padding location, " ..
                "or if you have multiboxers who are filling the raid without being at the padding location yet.\n\n"
}

-- Toggle for inviting padders from whispers
options.args["inviteWhisper"] =
{
    order   = 4,
    type    = "toggle",
    name    = "Invite from /whisper",
    desc    = "Invites players to the raid when a padding message is received as a whisper.",
    get     = function()
        return BracketBuddy.db.factionrealm.inviteSettings.whisper
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.inviteSettings.whisper = val
    end
}

-- Invite from whisper description
options.args["inviteWhisperDesc"] =
{
    order   = 5,
    type    = "description",
    name    = "Invites players to the raid when a padding message is received as a whisper.\n\n"
}

-- Toggle for automatically responding to players if the character has already been counted
options.args["autoRespondCounted"] =
{
    order   = 6,
    type    = "toggle",
    name    = "Auto respond duplicate counts",
    desc    = "Automatically messages a player if the character has already been counted.",
    get     = function()
        return BracketBuddy.db.factionrealm.countSettings.autoRespondCounted
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.countSettings.autoRespondCounted = val
    end
}

-- Auto respond duplicate count description
options.args["autoRespondCountedDesc"] =
{
    order   = 7,
    type    = "description",
    name    = "Automatically messages a player if the padding character has already been counted for the week.\n\n"
}

-- Toggle for responding to count checks
options.args["countCheck"] =
{
    order   = 8,
    type    = "toggle",
    name    = "Respond to count checks",
    desc    = "Responds to padding count checks.",
    get     = function()
        return BracketBuddy.db.factionrealm.countSettings.countCheck
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.countSettings.countCheck = val
    end
}

-- Count check description
options.args["countCheckDesc"] =
{
    order   = 9,
    type    = "description",
    name    = "Responds to a request to check the current padding counts. Players can message the counter 'count Name' to check their pad counts, and the total pool size.\n\n"
}

-- Toggle for automatically remaking the raid when it's full
options.args["autoRemakeRaid"] =
{
    order   = 10,
    type    = "toggle",
    name    = "Auto remake raid",
    desc    = "Automatically remakes the raid when the current one is full.",
    get     = function()
        return BracketBuddy.db.factionrealm.raidSettings.autoRemake
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.raidSettings.autoRemake = val
    end
}

-- Auto remake raid description
options.args["autoRemakeRaidDesc"] =
{
    order   = 11,
    type    = "description",
    name    = "Automatically remakes the raid when the current one is full.\n\n"
}

-- The threshold for when we should automatically remake the raid
options.args["autoRemakeRaidThreshold"] =
{
    order   = 12,
    name    = "Auto remake threshold",
    desc    = "The maximum number of raid members before we start remaking the raid.",
    type    = "range",
    min     = 5,
    max     = 40,
    step    = 1,
    width   = "full",
    get     = function()
        return BracketBuddy.db.factionrealm.raidSettings.remakeThreshold
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.raidSettings.remakeThreshold = val
    end
}

-- A seperator
options.args["sep1"] =
{
    order   = 13,
    type    = "description",
    name    = "\n"
}

-- A list of names of bracket managers, who will be promoted to assist
options.args["bracketManagers"] =
{
    order   = 14,
    name    = "Bracket managers",
    desc    = "A list of character names who should be promoted to raid assist.",
    type    = "input",
    multiline = true,
    get     = function()
        return BracketBuddy.db.factionrealm.raidSettings.bracketManagers
    end,
    set     = function(info, val)
        BracketBuddy.db.factionrealm.raidSettings.bracketManagers = val
    end
}

-- Bracket managers description
options.args["bracketManagersDesc"] =
{
    order   = 15,
    type    = "description",
    name    = "The list of names who should be promoted to raid assist if they are invited. " ..
              "Users who match this name are not counted as a padding character, and are invited regardless of if they have padded this week or not. " ..
              "Only one name per line.\n\n"
}

-- A seperator
options.args["sep2"] =
{
    order   = 16,
    type    = "description",
    name    = "\n"
}

-- A button to merge a CSV with the current data
options.args["mergeCsv"] =
{
    order   = 17,
    name    = "Merge a CSV",
    desc    = "Attempts to merge a CSV with the current pad data.",
    type    = "execute",
    func    = function()
        AceConfigDialog:Close(AddonName .. "-Options")
        BracketBuddy:ShowImport()
    end
}

-- A seperator
options.args["sep3"] =
{
    order   = 18,
    type    = "description",
    name    = "\n"
}

-- A button to export the current padding totals data to a CSV sheet
options.args["exportTotals"] =
{
    order   = 19,
    name    = "Export totals to CSV",
    desc    = "Shows a window with the total padding data in CSV format.",
    type    = "execute",
    func    = function()
        AceConfigDialog:Close(AddonName .. "-Options")
        BracketBuddy:ExportTotals()
    end
}

-- A button to export the current padding data to a CSV sheet
options.args["exportIndividuals"] =
{
    order   = 20,
    name    = "Export individual padded characters to CSV",
    desc    = "Shows a window with the individual padded characters in CSV format.",
    type    = "execute",
    func    = function()
        AceConfigDialog:Close(AddonName .. "-Options")
        BracketBuddy:ExportIndividuals()
    end
}

-- A seperator
options.args["sep4"] =
{
    order   = 21,
    type    = "description",
    name    = "\n"
}

-- A button to reset the weekly data
options.args["resetWeekly"] =
{
    order       = 22,
    name        = "Reset data",
    desc        = "Resets the current padding data",
    type        = "execute",
    confirm     = true,
    confirmText = "Are you sure you wish to clear the current padding entries?",
    func        = function()
        BracketBuddy.db.factionrealm.padding.totals = {}
        BracketBuddy.db.factionrealm.padding.realms   = {}
    end
}

-- Register the options for BracketBuddy
LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName .. "-Options", options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName .. "-Options", AddonName)