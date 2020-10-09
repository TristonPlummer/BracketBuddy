-- The name of the addon
AddonName       = "BracketBuddy"

-- Register the addon instance with Ace
BracketBuddy    = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0")
AceConfigDialog = LibStub("AceConfigDialog-3.0")

--[[
    This gets executed when the addon and it's saved variables have been loaded.
]]
function BracketBuddy:OnInitialize()

    -- Default initialise the database
    self.db = LibStub("AceDB-3.0"):New(AddonName .. "DB",
    {
        factionrealm =
        {
            minimapIcon = 
            {
                hide    = false
            },
            inviteSettings =
            {
                say     = true,
                whisper = true
            },
            raidSettings =
            {
                autoRemake      = true,
                remakeThreshold = 38,
                bracketManagers = ""
            },
            countSettings =
            {
                countCheck          = false,
                autoRespondCounted  = false
            },
            padding =
            {
                realms = {},
                totals = {}
            }
        }

    }, true)

    -- Register for events to listen on
    self:RegisterEvent("CHAT_MSG_SAY")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("RAID_ROSTER_UPDATE")

    -- Prepare the UI
    BracketBuddyGUI:Prepare()

    -- Draw the minimap icon
    DrawMinimapIcon()
end

--[[
    Gets executed when a message is received in /say
]]
function BracketBuddy:CHAT_MSG_SAY(...)
    if not self.db.factionrealm.inviteSettings.say then
        return
    end

    local _, msg, author = ...
    HandleMessage(msg, author)
end

--[[
    Gets executed when a message is received as a whisper
]]
function BracketBuddy:CHAT_MSG_WHISPER(...)
    if not self.db.factionrealm.inviteSettings.whisper then
        return
    end

    local _, msg, author = ...
    HandleMessage(msg, author)
end

--[[
    Gets executed when the raid roster is uupdated
]]
function BracketBuddy:RAID_ROSTER_UPDATE(...)
    if not BracketBuddy.db.factionrealm.raidSettings.bracketManagers then
        return
    end

    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if IsBracketManager(name) then
            PromoteToAssistant("raid" .. i)
        else
            DemoteAssistant("raid" .. i)
        end
    end
end

--[[
    Checks if a name is a bracket manager
]]
function IsBracketManager(name)
    if not BracketBuddy.db.factionrealm.raidSettings.bracketManagers then
        return false
    end
    
    -- Search the bracket managers
    local text = BracketBuddy.db.factionrealm.raidSettings.bracketManagers
    for bm in text:gmatch("[^\r\n]+") do
        if bm:lower() == name:lower() then
            return true
        end
    end

    return false
end

--[[
    Handles a message received from another player
]]
function HandleMessage(msg, author)
    msg     = msg:lower()
    name    = author:gsub("%-[^|]+", "")
    name    = name:lower()
    
    -- Get the realm and ranker name from the message
    local realm, ranker = msg:match("(%w+)(.+)")
    if not ranker or string.len(ranker) < 2 then
        return
    end

    -- Update the name to include the current realm
    name = name .. "-" .. GetNormalizedRealmName():lower()

    -- Trim whitespace from the ranker's name
    ranker = ranker:gsub("%s+", "")
    ranker = ranker:lower()

    -- If the realm is "count", we instead should attempt to provide the total pad count
    if realm == "count" then
        HandleCountCheck(author, ranker)
        return
    end

    -- If the author has already been counted
    local realms = BracketBuddy.db.factionrealm.padding.realms
    local totals = BracketBuddy.db.factionrealm.padding.totals

    -- Populate the realm table if it's nil
    if realms[realm] == nil then
        realms[realm] = {}
    end

    -- If the name has already been counted
    if realms[realm][name] ~= nil and not IsBracketManager(name) then
        if BracketBuddy.db.factionrealm.countSettings.autoRespondCounted then
            SendChatMessage("The name " .. name .. " has already been counted - please use a unique name!", "WHISPER", nil, name)
        end
    end

    -- Invite the player and stop if they are a bracket manager
    if IsBracketManager(name) then
        InvitePlayer(name)
        return
    end

    -- Append the ranker's realm to their name
    ranker = ranker .. "-" .. realm

    -- Log the padded character and invite the player
    realms[realm][name] = 
    {
        ranker  = ranker,
        date    = date("%Y-%m-%d %H:%M:%S", GetServerTime())
    }

    -- Recalculate the totals of the ranker based on the padding entries
    local total = 0
    for k, v in pairs(realms[realm]) do
        if v.ranker:lower() == ranker:lower() then
            total = total + 1
        end
    end
    BracketBuddy.db.factionrealm.padding.totals[ranker] = total

    InvitePlayer(name)
end

--[[
    Checks the total number of pads that a specified ranker has done
]]
function HandleCountCheck(author, ranker)
    if not BracketBuddy.db.factionrealm.countSettings.countCheck then
        return false
    end

    local totals        = BracketBuddy.db.factionrealm.padding.totals
    local rankerTotal   = totals[ranker:lower()] or 0
    local poolTotal     = 0

    -- Calculate the pool total
    for _, count in pairs(totals) do
        poolTotal = poolTotal + count
    end

    -- Inform the author of the total counts
    SendChatMessage("The player \'" .. ranker .. "\' has " .. rankerTotal .. " pads, and the current total pad count is " .. poolTotal .. ".", "WHISPER", nil, author)
end

--[[
    Invites the player, and also remakes the raid if required.
    player: The name of the player to invite.
]]
function InvitePlayer(player)

    -- If we're either not in a group, or if we're the leader of our group
    if not IsInGroup() or UnitIsGroupLeader("PLAYER") then

        -- If we should remake the group
        if BracketBuddy.db.factionrealm.raidSettings.autoRemake and GetNumGroupMembers() >= BracketBuddy.db.factionrealm.raidSettings.remakeThreshold then
            LeaveParty()
        end

        -- If the group is not currently a raid, convert it to one
        if not IsInRaid() then
            ConvertToRaid()
            SetRaidTarget("player", 1) -- Mark ourselves with a star
        end

        -- Invite the target player
        InviteUnit(player)
    end
end

--[[
    Handles the drawing of BracketBuddy's minimap icon.
]]
function DrawMinimapIcon()
    LibStub("LibDBIcon-1.0"):Register(AddonName, LibStub("LibDataBroker-1.1"):NewDataObject(AddonName,
    {
        type = "data source",
        text = AddonName,
        icon = "Interface\\Icons\\Ability_DualWield",
        OnClick = function(self, button)
            if button == "LeftButton" then
                BracketBuddyGUI:Toggle()
            elseif button == "RightButton" then
                AceConfigDialog:Open(AddonName .. "-Options")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine(format("%s", AddonName), format("|cff777777v%s", GetAddOnMetadata(AddonName, "Version")))
            tooltip:AddLine("|cff777777by Cups-Arugal|r")
            tooltip:AddLine("|cFFCFCFCFLeft Click: |r Show pad standings")
            tooltip:AddLine("|cFFCFCFCFRight Click: |r Open settings")
        end
    }), BracketBuddy.db.factionrealm.minimapIcon)
end