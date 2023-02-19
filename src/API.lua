-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

local internal = Taneth
local IsExternal = internal.IsExternal

Taneth = setmetatable({
    IsExternal = IsExternal,
    RegisterTestSuite = internal.RegisterTestSuite,
    RunTestSuite = internal.RunTestSuite,
    RunAll = internal.RunAll
}, {
    __call = internal.RegisterTestSuite
})

if not IsExternal() then
    SLASH_COMMANDS["/taneth"] = function(id)
        if not id or id == "" then
            Taneth:RunAll()
        else
            Taneth:RunTestSuite(id)
        end
    end
end