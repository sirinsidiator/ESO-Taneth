-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

Taneth = {
    originalAssert = assert,
    suites = {},
}

local function IsExternal()
    return not ScriptBuildInfo
end
Taneth.IsExternal = IsExternal

if IsExternal() then
    d = print
end