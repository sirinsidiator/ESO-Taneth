-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

local help = false
local addonPaths = {}
local suiteIds = {}

for i = 1, #arg do
    if arg[i] == "--help" or arg[i] == "-h" then
        help = true
    else
        local pathOrId = arg[i]
        if string.sub(pathOrId, -4) == ".txt" then
            pathOrId = string.gsub(pathOrId, "\\", "/")
            table.insert(addonPaths, pathOrId)
        else
            table.insert(suiteIds, pathOrId)
        end
    end
end

if help then
    print("Usage: Taneth.bat [--help|-h] [--verbose|-v] <one or more relative paths to addon manifests> [<one or more test suite id>]")
else
    local TANETH_FOLDER = string.sub(arg[0], 1, #arg[0] - 7)
    eso.LoadAddon(TANETH_FOLDER .. "Taneth.txt")

    for i = 1, #addonPaths do
        local addonPath = addonPaths[i]
        if not eso.LoadAddon(addonPath) then
            print("Failed to load addon manifest " .. addonPath .. ".")
            return
        end
        print("Loaded addon manifest " .. addonPath .. ".")
    end

    local hasAsyncTests = false
    if #suiteIds > 0 then
        hasAsyncTests = Taneth:RunTestSuites(suiteIds, function()
            eso.ClearAllEventsAndUpdates()
        end)
    else
        hasAsyncTests = Taneth:RunAll(function()
            eso.ClearAllEventsAndUpdates()
        end)
    end

    if hasAsyncTests then
        eso.HandleNextFrame()
    end
end
