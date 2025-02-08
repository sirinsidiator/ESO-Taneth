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

internal.assert = setmetatable({
    equals = function(a, b)
        return Fail(a == b, "expected: " .. tostring(a) .. ", actual: " .. tostring(b))
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
    fail = function(message)
        Fail(false, message)
    end,
}, {
    __call = oassert
})
