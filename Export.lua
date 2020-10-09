local AceGUI = LibStub("AceGUI-3.0")

-- The max size of an edit max
EDIT_BOX_MAX_SIZE = 300000

--[[
    Prepares the export window
]]
function BracketBuddy:PrepareExport(frameTitle, editableTitle, buttonTitle)
    
    -- Create a container frame
    local frame = AceGUI:Create("Window")
    frame:SetTitle(frameTitle)
    frame:SetHeight(600)
    frame:SetWidth(800)
    frame:SetLayout("Flow")
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(self)
        self:Release()
    end)

    -- Create an scrollable widget
    local scrollable = AceGUI:Create("ScrollFrame")
    frame:AddChild(scrollable)
    scrollable:SetFullHeight(true)
    scrollable:SetFullWidth(true)

    -- Create a multi-line edit box for the CSV to be placed in
    local editable = AceGUI:Create("MultiLineEditBox")
    scrollable:AddChild(editable)
    editable:SetLabel(editableTitle)
    editable:SetMaxLetters(EDIT_BOX_MAX_SIZE)
    editable:SetHeight(540)
    editable:SetWidth(775)

    -- Add an "import" button
    local button = AceGUI:Create("Button", frame)
    button:SetWidth(170)
    button:SetText(buttonTitle)
    frame:AddChild(button)
    button:SetPoint("BOTTOM")

    -- Return the widgets
    return frame, editable, button
end

--[[
    Exports the BracketBuddy padding totals database to CSV format
]]
function BracketBuddy:ExportTotals()

    -- Get the frame and editable box
    local frame, editable, button = self:PrepareExport("BracketBuddy - Export total counts", "Export total counts", "Export")

    -- Get the total pad table and sort it in descending order
    local db = BracketBuddy.db.factionrealm.padding.totals
    local totals = {}
    for name, count in pairs(db) do
        table.insert(totals, {name, count})
    end
    table.sort(totals, function(a, b)
        return a[2] > b[2]
    end)

    -- The CSV text
    local text = ""

    -- Iterate over the table, and add the padding entries
    for k, v in pairs(totals) do
        text = text .. v[1] .. "," .. string.format("%d", v[2]) .. "\n"
    end

    -- Set the text
    editable:SetText(text)
    editable:HighlightText(0)

    -- Show the window
    frame:Show()
end

--[[
    Exports the BracketBuddy individual padded characters database to CSV format
]]
function BracketBuddy:ExportIndividuals()

    -- Get the frame and editable box
    local frame, editable, button = self:PrepareExport("BracketBuddy - Export individual pads", "Export pads", "Export")

    -- Get the total pad table and sort it in descending order
    local db = self.db.factionrealm.padding.realms
    local pads = {}
    for realm, value in pairs(db) do
        for name, padded in pairs(value) do
            table.insert(pads, {realm, name, padded["ranker"], padded["date"]})
        end
    end
    table.sort(pads, function(a, b)
        return a[3] > b[3]
    end)

    -- The CSV text
    local text = ""

    -- Iterate over the table, and add the padding entries
    for k, v in pairs(pads) do
        text = text .. v[1] .. "," .. v[2] .. "," .. v[3] .. "," .. v[4] .. "\n"
    end

    -- Set the text
    editable:SetText(text)
    editable:HighlightText(0)

    -- Show the window
    frame:Show()
end

--[[
    Opens a window and attempts to merge a CSV with our pad data.
]]
function BracketBuddy:ShowImport()

    local frame, editable, button = self:PrepareExport("BracketBuddy - Import CSV", "Import individual pads", "Import")

    button:SetCallback("OnClick", function()
        local text = editable:GetText()

        -- The individual pads table
        local realms = {}

        -- Loop through the lines in the text box
        for entry in text:gmatch("[^\r\n]+") do

            -- Split the line into padder, ranker, date
            local realm, padder, ranker, date = entry:match("([^,]*),([^,]*),([^,]*),([^,]*)")
            if (realms[realm] == nil) then
                realms[realm] = {}
            end
            realms[realm][padder] =
            {
                ranker  = ranker,
                date    = date
            }
        end

        -- Import the pads
        self:Import(realms)
        frame:Hide()
    end)

    -- Show the frame
    frame:Show()
end

--[[
    Imports the pad CSV data
]]
function BracketBuddy:Import(pads)

    -- The current pad databases
    local localPads     = self.db.factionrealm.padding.realms
    local totals        = self.db.factionrealm.padding.totals

    -- Merge the two tables
    for realm, value in pairs(pads) do
        for name, padded in pairs(value) do
            if (localPads[realm] == nil) then
                localPads[realm] = {}
            end
            localPads[realm][name] = padded
        end
    end

    -- Reset the totals and recalculate them
    totals = {}
    for realm, value in pairs(localPads) do
        for name, padded in pairs(value) do
            local total = totals[padded.ranker] or 0
            totals[padded.ranker] = total + 1
        end
    end

    -- Update the database
    self.db.factionrealm.padding.realms = localPads
    self.db.factionrealm.padding.totals = totals
end