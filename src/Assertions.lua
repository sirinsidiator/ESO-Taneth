-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

local internal = Taneth
local IsExternal = internal.IsExternal

local function Fail(result, message)
    if not internal.currentRun.currentTest then return end
    internal.currentRun.currentTest.failure = not result
    if internal.currentRun.currentTest.assertAsync then
        return internal.currentRun.currentTest.assertAsync(result, message)
    end
    return internal.originalAssert(result, message)
end

local function DeepCompare(t1, t2)
    if type(t1) ~= type(t2) then
        return false
    end
    if type(t1) ~= "table" then
        return t1 == t2
    end

    for k, v in pairs(t1) do
        if not DeepCompare(v, t2[k]) then
            return false
        end
    end
    for k, v in pairs(t2) do
        if not DeepCompare(v, t1[k]) then
            return false
        end
    end
    return true
end

local function DeepToString(t, visited)
    if type(t) ~= "table" then return tostring(t) end

    if not visited then visited = {} end
    if type(t) == "table" and visited[t] then return "{...}" end
    visited[t] = true

    local parts = {}
    local size = #t
    if size > 0 then
        for i = 1, size do
            parts[i] = DeepToString(t[i], visited)
        end
    end

    for k, v in pairs(t) do
        if type(k) ~= "number" or k > size then
            if type(k) == "string" then
                parts[#parts + 1] = k .. " = " .. DeepToString(v, visited)
            else
                parts[#parts + 1] = "[" .. tostring(k) .. "] = " .. DeepToString(v, visited)
            end
        end
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

internal.assert = setmetatable({
    equals = function(a, b)
        return Fail(a == b, "expected: " .. tostring(a) .. ", actual: " .. tostring(b))
    end,
    same = function(a, b)
        return Fail(DeepCompare(a, b), "expected: " .. DeepToString(a) .. ", actual: " .. DeepToString(b))
    end,
    is_true = function(a)
        return Fail(a == true, "expected: true, actual: " .. tostring(a))
    end,
    is_false = function(a)
        return Fail(a == false, "expected: false, actual: " .. tostring(a))
    end,
    is_nil = function(a)
        return Fail(a == nil, "expected: nil, actual: " .. tostring(a))
    end,
    is_not_nil = function(a)
        return Fail(a ~= nil, "not expected: nil, actual: " .. tostring(a))
    end,
    are_not = {
        equals = function(a, b)
            return Fail(a ~= b, "not expected: " .. tostring(a) .. ", actual: " .. tostring(b))
        end,
    },
    has_error = function(expectedError, callback)
        local success, err = pcall(callback)
        if success or not err then
            return Fail(false, "Expected error: '" .. expectedError .. "' but no error was thrown")
        else
            if not IsExternal() then
                local index = err:find("\nstack traceback")
                if index then
                    err = err:sub(1, index - 1)
                end
            end
            return Fail(err:find(expectedError, -expectedError:len(), 1, true) ~= nil,
                "Expected error: '" .. expectedError .. "' but got '" .. err .. "' instead")
        end
    end,
    has_no_error = function(callback)
        local success, err = pcall(callback)
        if not success then
            if not IsExternal() then
                local index = err:find("\nstack traceback")
                if index then
                    err = err:sub(1, index - 1)
                end
            end
            return Fail(false, "Expected no error but got '" .. err .. "' instead")
        end
    end,
    fail = function(message)
        Fail(false, message)
    end,
}, {
    __call = oassert
})
