-- SPDX-FileCopyrightText: 2023 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

local internal = Taneth
local IsExternal = internal.IsExternal

local function CreateSuiteEnv()
    local env = {}
    env.describe = internal.describe
    env.it = internal.it
    env.assert = internal.assert
    env._G = env
    setmetatable(env, {__index = _G})
    return env
end

local function CreateTestEnv()
    local env = {}
    env._G = env
    setmetatable(env, {__index = internal.currentRun.suiteEnv})
    return env
end

local function PushLabel(label)
    internal.currentRun.labels[#internal.currentRun.labels + 1] = label
end

local function PopLabel()
    internal.currentRun.labels[#internal.currentRun.labels] = nil
end

local function CreateTableFunction(func)
    return setmetatable({}, {
        __call = function(self, ...) return func(...) end
    })
end

internal.describe = CreateTableFunction(function(label, callback)
    PushLabel(label)
    setfenv(callback, internal.currentRun.suiteEnv)()
    PopLabel()
end)
internal.describe.skip = function() end

internal.it = CreateTableFunction(function(label, callback)
    PushLabel(label)
    internal.currentRun.tests[#internal.currentRun.tests + 1] = {
        label = table.concat(internal.currentRun.labels, " / "),
        callback = setfenv(callback, CreateTestEnv())
    }
    PopLabel()
end)
internal.it.skip = function() end

local function PrintError(label, err)
    if IsExternal() then
        d(label)
        d(err)
        d(" ")
    else
        d(label, err)
    end
end

local TANETH_RESULT_DIALOG = "Taneth_Result"
local function GetResultDialog()
    if(not ESO_Dialogs[TANETH_RESULT_DIALOG]) then
        ESO_Dialogs[TANETH_RESULT_DIALOG] = {
            canQueue = true,
            title = {
                text = "Test Results",
            },
            mainText = {
                text = "",
            },
            buttons = {
                [1] = {
                    text = "Reload UI",
                    callback = function(dialog) ReloadUI() end,
                },
                [2] = {
                    text = "Dismiss",
                }
            }
        }
    end
    return ESO_Dialogs[TANETH_RESULT_DIALOG]
end

local function ShowConfirmationDialog(title, body, callback)
    local dialog = GetConfirmDialog()
    dialog.title.text = title
    dialog.mainText.text = body
    dialog.buttons[1].callback = callback
    ZO_Dialogs_ShowDialog(LAM_CONFIRM_DIALOG)
end

local COLOR = {
    ["+"] = "|c00FF00",
    ["-"] = "|cFF6A00",
    ["*"] = "|cFF0000",
}
local function ShowResult(runs)
    local strings = {}
    for i = 1, #runs do
        local stats = runs[i]
        if stats.error then
            strings[#strings + 1] = "Failed to run suite '" .. stats.id .. "':"
            strings[#strings + 1] = stats.error
            strings[#strings + 1] = ""
        else
            strings[#strings + 1] = "Results for suite '" .. stats.id .. "':"
            if not IsExternal() then
                local previous = ""
                for j = 1, #stats.results do
                    if previous ~= stats.results[j] then
                        previous = stats.results[j]
                        stats.results[j] = COLOR[previous] .. previous
                    end
                end
                stats.results[#stats.results + 1] = "|r"
            end
            strings[#strings + 1] = table.concat(stats.results, "")
            strings[#strings + 1] = string.format("%d successes / %d failures / %d errors : %.2f seconds", stats.successCount, stats.failureCount, stats.errorCount, stats.duration)
            strings[#strings + 1] = " "
        end
    end

    if IsExternal() then
        for i = 1, #strings do
            d(strings[i])
        end
    else
        local dialog = GetResultDialog()
        dialog.mainText.text = table.concat(strings, "\n")
        ZO_Dialogs_ShowDialog(TANETH_RESULT_DIALOG)
    end
end

local function RunTests()
    local successCount = 0
    local failureCount = 0
    local errorCount = 0
    local startTime = GetGameTimeMilliseconds()

    local results = {}
    for i = 1, #internal.currentRun.tests do
        local currentTest = internal.currentRun.tests[i]
        internal.currentRun.currentTest = currentTest
        local success, err = pcall(currentTest.callback)

        if success then
            currentTest.result = "+"
            successCount = successCount + 1
        else
            if currentTest.failure then
                currentTest.result = "-"
                failureCount = failureCount + 1
            else
                currentTest.result = "*"
                errorCount = errorCount + 1
            end
            PrintError(currentTest.label, err)
        end
        results[i] = currentTest.result
    end

    local duration = (GetGameTimeMilliseconds() - startTime) / 1000
    return {
        successCount = successCount,
        failureCount = failureCount,
        errorCount = errorCount,
        duration = duration,
        results = results
    }
end

local function RegisterTestSuite(self, id, callback)
    local suite = internal.suites[id] or {}
    suite[#suite + 1] = callback
    internal.suites[id] = suite
end
internal.RegisterTestSuite = RegisterTestSuite

local function DoRunTestSuite(id, suite)
    if not suite then
        return { id = id, error = "Test suite '" .. id .. "' not found" }
    end

    if #suite == 0 then
        return { id = id, error = "Test suite '" .. id .. "' is empty" }
    end

    local env = CreateSuiteEnv()
    internal.currentRun = {
        suiteEnv = env,
        labels = {},
        tests = {},
    }
    internal.describe(id, function()
        for i = 1, #suite do
            setfenv(suite[i], env)()
        end
    end)
    local stats = RunTests()
    stats.id = id
    return stats
end

local function RunTestSuite(self, id)
    local runs = { DoRunTestSuite(id, internal.suites[id]) }
    ShowResult(runs)
end
internal.RunTestSuite = RunTestSuite

local function RunTestSuites(self, ids)
    local runs = {}
    for id in pairs(ids) do
        runs[#runs + 1] = DoRunTestSuite(id, internal.suites[id])
    end
    ShowResult(runs)
end
internal.RunTestSuites = RunTestSuites

local function RunAll(self)
    local runs = {}
    for id in pairs(internal.suites) do
        runs[#runs + 1] = DoRunTestSuite(id, internal.suites[id])
    end
    ShowResult(runs)
end
internal.RunAll = RunAll