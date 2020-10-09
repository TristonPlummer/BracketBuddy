-- Initialise the global interface object
local GUI = {}
_G["BracketBuddyGUI"] = GUI

-- The name of the addon
AddonName       = "BracketBuddy"

-- Register the addon instance with Ace
AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
LibStub("AceHook-3.0"):Embed(GUI)

-- The gui objects
local frame, tabGroup, scroll = nil, nil, nil

--[[
    Commonly used colors
]]
local colors = {
	["ORANGE"] = "ff7f00",
	["GREY"] = "aaaaaa",
	["RED"] = "C41F3B",
	["GREEN"] = "00FF96",
	["SHAMAN"] = "0070DE",
	["nil"] = "FFFFFF",
	["NORMAL"] = "f2ca45"
}

--[[
    Displays the GUI
]]
function GUI:Show()
    if not frame then
        return
    end

    frame:Show()
end

--[[
    Hides the GUI
]]
function GUI:Hide()
    if frame then
        frame:Hide()
    end
end

--[[
    Toggles the GUI
]]
function GUI:Toggle()
    if frame and frame:IsShown() then
        self:Hide()
    else
        tabGroup:SelectTab("TotalPads")
        self:Show()
    end
end

--[[
    Prepares the graphical interface for display
]]
function GUI:Prepare()

    -- Create the frame
    frame = AceGUI:Create("Frame")
    frame:Hide()
    _G["BracketBuddyGUI_MainFrame"] = frame
    tinsert(UISpecialFrames, "BracketBuddyGUI_MainFrame") -- Enables ESC close

    -- Set the title and display parameters
    frame:SetTitle("BracketBuddy - by Cups-Arugal")
    frame:SetWidth(800)
    frame:SetHeight(600)
    frame:SetLayout("Fill")
    frame:EnableResize(false)
    
    -- Create a tab group
    tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTabs({
        { text = "Total pad counts",    value = "TotalPads" },
        { text = "Recent pads",         value = "RecentPads" }
    })
    tabGroup:SetLayout("Flow")
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren()
        GUI["Build" .. group](self, container)
    end)
    tabGroup:SetStatusTable({})
    tabGroup:SelectTab("TotalPads")
    frame:AddChild(tabGroup)
end

--[[
    Builds a scrollable frame to use as a container for the tables
]]
function GUI:BuildScrollFrame()
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
	scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    return scroll
end

--[[
    Builds the total pad count table
]]
function GUI:BuildTotalPads(container)

     -- Get the total pad table
     local db = BracketBuddy.db.factionrealm.padding.totals
     local totals = {}
     for name, count in pairs(db) do
         table.insert(totals, {name, count})
     end

    -- Create the scroll bar
    local scroll = self:BuildScrollFrame()

    -- Build the table header
    local tableHeader = AceGUI:Create("SimpleGroup")
    tableHeader:SetFullWidth(true)
    tableHeader:SetLayout("Flow")

    -- The name
    local button = AceGUI:Create("InteractiveLabel")
    button:SetWidth(150)
    button:SetText(colorize("Name", "ORANGE"))
    tableHeader:AddChild(button)
    
    -- The number of pads completed
    button = AceGUI:Create("InteractiveLabel")
    button:SetWidth(80)
    button:SetText(colorize("Pads", "ORANGE"))
    button:SetCallback("OnClick", function()
        table.sort(totals, function(a, b)
            return a[2] > b[2]
        end)

        scroll:ReleaseChildren()
        self:BuildTotalTable(scroll, totals)
    end)
    tableHeader:AddChild(button)

    -- Build the total pads
    table.sort(totals, function(a, b)
        return a[2] > b[2]
    end)
    self:BuildTotalTable(scroll, totals)

    -- Add the header and scroll bar
    container:AddChild(tableHeader)
    container:AddChild(scroll)
end

--[[
    Builds the total pad count table
]]
function GUI:BuildTotalTable(scroll, totals)
    for k, v in pairs(totals) do
        local name = v[1]
        local count = v[2]

        -- Create the row
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")
    
        -- Create the text buttons
        local btn = AceGUI:Create("InteractiveLabel")
        local formattedName = name:sub(1, 1):upper() .. name:sub(2)
        btn:SetWidth(150)
        btn:SetText(formattedName)
        row:AddChild(btn)

        btn = AceGUI:Create("InteractiveLabel")
        btn:SetWidth(80)
        btn:SetText(count)
        row:AddChild(btn)
        scroll:AddChild(row)
    end
end

--[[
    Builds the scrollable table of recent pads
]]
function GUI:BuildRecentPads(container)

    -- Get the individual pad table
    local db = BracketBuddy.db.factionrealm.padding.realms
    local pads = {}
    for realm, value in pairs(db) do
        for name, padded in pairs(value) do
            table.insert(pads, {name, padded["ranker"], padded["date"]})
        end
    end

   -- Create the scroll bar
   local scroll = self:BuildScrollFrame()

   -- Build the table header
   local tableHeader = AceGUI:Create("SimpleGroup")
   tableHeader:SetFullWidth(true)
   tableHeader:SetLayout("Flow")

   -- The name of the padded toon
   local button = AceGUI:Create("InteractiveLabel")
   button:SetWidth(230)
   button:SetText(colorize("Pad toon", "ORANGE"))
   tableHeader:AddChild(button)
   
   -- The name of the ranker
   button = AceGUI:Create("InteractiveLabel")
   button:SetWidth(230)
   button:SetText(colorize("Ranker name", "ORANGE"))
   tableHeader:AddChild(button)

   -- The date of the pad
   button = AceGUI:Create("InteractiveLabel")
   button:SetWidth(230)
   button:SetText(colorize("Completed date", "ORANGE"))
   tableHeader:AddChild(button)

   -- Build the individual pads
    table.sort(pads, function(a, b)
        return a[3] > b[3]
    end)
   self:BuildPadTable(scroll, pads)

   -- Add the header and scroll bar
   container:AddChild(tableHeader)
   container:AddChild(scroll)
end

--[[
    Builds the individual pad table
]]
function GUI:BuildPadTable(scroll, pads)
    local count = 0
    for k, v in pairs(pads) do
        if count >= 50 then
            break
        end
        
        local name = v[1]
        local ranker = v[2]
        local date = v[3]

        -- Create the row
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")
    
        -- Create the text buttons
        local btn = AceGUI:Create("InteractiveLabel")
        local formattedName = name:sub(1, 1):upper() .. name:sub(2)
        btn:SetWidth(230)
        btn:SetText(formattedName)
        row:AddChild(btn)

        btn = AceGUI:Create("InteractiveLabel")
        local formattedRanker = ranker:sub(1, 1):upper() .. ranker:sub(2)
        btn:SetWidth(230)
        btn:SetText(formattedRanker)
        row:AddChild(btn)

        btn = AceGUI:Create("InteractiveLabel")
        btn:SetWidth(230)
        btn:SetText(date)
        row:AddChild(btn)
        scroll:AddChild(row)
        count = count + 1
    end
end

--[[
    A function to format text with a color
]]
function colorize(str, colorOrClass)
	if (not colorOrClass) then -- some guys have nil class for an unknown reason
		colorOrClass = "nil"
	end
	
	if (not colors[colorOrClass] and RAID_CLASS_COLORS and RAID_CLASS_COLORS[colorOrClass]) then
		colors[colorOrClass] = format("%02x%02x%02x", RAID_CLASS_COLORS[colorOrClass].r * 255, RAID_CLASS_COLORS[colorOrClass].g * 255, RAID_CLASS_COLORS[colorOrClass].b * 255)
	end
	if (not colors[colorOrClass]) then
		colorOrClass = "nil"
	end

	return format("|cff%s%s|r", colors[colorOrClass], str)
end