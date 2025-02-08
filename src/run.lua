-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

local help = false
local addonPath = nil
local suiteId = nil

for i = 1, #arg do
    if arg[i] == "--help" or arg[i] == "-h" then
        help = true
    elseif addonPath then
        suiteId = arg[i]
    else
        addonPath = arg[i]
    end
end

if help then
    print("Usage: Taneth.bat [--help|-h] [--verbose|-v] <relative path to addon manifest> [<test suite id>]")
else
    eso.LoadAddon("Taneth.txt")

    if addonPath then
        if not eso.LoadAddon(addonPath) then
            print("Failed to load addon manifest " .. addonPath .. ".")
            return
        end
        print("Loaded addon manifest " .. addonPath .. ".")
    end

    if suiteId then
        Taneth:RunTestSuite(suiteId)
    else
        Taneth:RunAll()
    end
end