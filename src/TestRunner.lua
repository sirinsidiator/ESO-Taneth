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
    env.skip = internal.skip
    env._G = env
    setmetatable(env, { __index = _G })
    return env
end

local function CreateTestEnv()
    local env = {}
    env._G = env
    setmetatable(env, { __index = internal.currentRun.suiteEnv })
    return env
end

local function PushSuite(label)
    internal.currentRun.suite[#internal.currentRun.suite + 1] = {
        label = label,
        tests = {},
    }
end

local function PopSuite()
    internal.currentRun.suite[#internal.currentRun.suite] = nil
end

local function GenerateLabel(label)
    local labels = {}
    for i = 1, #internal.currentRun.suite do
        labels[#labels + 1] = internal.currentRun.suite[i].label
    end
    labels[#labels + 1] = label
    return table.concat(labels, " / ")
end

local function CreateTableFunction(func)
    return setmetatable({}, {
        __call = function(self, ...) return func(...) end
    })
end

local function PendingTestCallback()
    internal.currentRun.currentTest.skipped = true
    return internal.originalAssert(false, "Test pending")
end

internal.skip = PendingTestCallback

internal.describe = CreateTableFunction(function(label, callback)
    PushSuite(label)
    setfenv(callback, internal.currentRun.suiteEnv)()
    PopSuite()
end)
internal.describe.skip = function(label, callback)
    PushSuite(label)
    local wasAutoSkip = internal.currentRun.autoSkip
    internal.currentRun.autoSkip = true
    setfenv(callback, internal.currentRun.suiteEnv)()
    internal.currentRun.autoSkip = wasAutoSkip
    PopSuite()
end

internal.it = CreateTableFunction(function(label, callback)
    if internal.currentRun.autoSkip then
        callback = PendingTestCallback
    else
        callback = callback or PendingTestCallback
    end
    internal.currentRun.tests[#internal.currentRun.tests + 1] = {
        label = GenerateLabel(label),
        callback = setfenv(callback, CreateTestEnv())
    }
end)
internal.it.skip = function(label, _callback)
    internal.currentRun.tests[#internal.currentRun.tests + 1] = {
        label = GenerateLabel(label),
        callback = setfenv(PendingTestCallback, CreateTestEnv())
    }
end

internal.it.async = CreateTableFunction(function(label, callback, timeout)
    internal.currentRun.tests[#internal.currentRun.tests + 1] = {
        label = GenerateLabel(label),
        callback = setfenv(callback, CreateTestEnv()),
        async = true,
        timeout = timeout
    }
end)
internal.it.async.skip = internal.it.skip

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
    if not ESO_Dialogs[TANETH_RESULT_DIALOG] then
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
            strings[#strings + 1] = string.format("%d successes / %d pending / %d failures / %d errors : %.2f seconds",
                stats.successCount, stats.pendingCount, stats.failureCount, stats.errorCount, stats.duration)
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

local function RunTest(test, stats)
    local success, err = pcall(test.callback)

    if success then
        test.result = "+"
        stats.successCount = stats.successCount + 1
    else
        if test.skipped then
            test.result = "-"
            stats.pendingCount = stats.pendingCount + 1
        elseif test.failure then
            test.result = "-"
            stats.failureCount = stats.failureCount + 1
        else
            test.result = "*"
            stats.errorCount = stats.errorCount + 1
        end
        PrintError(test.label, err)
    end
    return test.result
end

local DEFAULT_TEST_TIMEOUT = 5000
local function RunAsyncTest(test, stats, callback)
    local finished = false

    local function ClearTimeout()
        EVENT_MANAGER:UnregisterForUpdate("TanethTest")
    end

    local function FinishTest()
        if finished then
            print("Test already finished")
            return
        end
        test.onAsyncError = nil
        ClearTimeout()
        callback(test.result)
        finished = true
    end

    local function SetSuccess()
        test.result = "+"
        stats.successCount = stats.successCount + 1
    end

    local function SetError(err)
        if test.skipped then
            test.result = "-"
            stats.pendingCount = stats.pendingCount + 1
        elseif test.failure then
            test.result = "-"
            stats.failureCount = stats.failureCount + 1
        else
            test.result = "*"
            stats.errorCount = stats.errorCount + 1
        end
        PrintError(test.label, err)
    end

    test.assertAsync = function(condition, message)
        if not condition then
            SetError(message)
            FinishTest()
        end
    end

    EVENT_MANAGER:RegisterForUpdate("TanethTest", test.timeout or DEFAULT_TEST_TIMEOUT, function()
        if finished then return end
        SetError("Test timed out")
        FinishTest()
    end)

    local success, err = pcall(test.callback, function(err)
        if finished then return end
        if err then
            SetError(err)
        else
            SetSuccess()
        end
        FinishTest()
    end)

    if not success then
        SetError(err)
        FinishTest()
    end
end

local function RunNextTest(stats, index, callback)
    local currentTest = internal.currentRun.tests[index]
    internal.currentRun.currentTest = currentTest

    if not currentTest then
        callback()
        return false
    end

    if currentTest.async then
        RunAsyncTest(currentTest, stats, function(result)
            stats.results[index] = result
            RunNextTest(stats, index + 1, callback)
        end)
        return true
    else
        stats.results[index] = RunTest(currentTest, stats)
        return RunNextTest(stats, index + 1, callback)
    end
end

local function RegisterTestSuite(self, id, callback)
    local suite = internal.suites[id] or {}
    suite[#suite + 1] = callback
    internal.suites[id] = suite
end
internal.RegisterTestSuite = RegisterTestSuite

local function DoRunTestSuite(id, suite, callback)
    if not suite then
        return { id = id, error = "Test suite '" .. id .. "' not found" }
    end

    if #suite == 0 then
        return { id = id, error = "Test suite '" .. id .. "' is empty" }
    end

    local env = CreateSuiteEnv()
    internal.currentRun = {
        suiteEnv = env,
        suite = {},
        tests = {},
    }
    internal.describe(id, function()
        for i = 1, #suite do
            setfenv(suite[i], env)()
        end
    end)

    local stats = {
        successCount = 0,
        pendingCount = 0,
        failureCount = 0,
        errorCount = 0,
        results = {},
    }
    local startTime = GetGameTimeMilliseconds()
    local async = RunNextTest(stats, 1, function()
        stats.id = id
        stats.duration = (GetGameTimeMilliseconds() - startTime) / 1000
        callback(stats)
    end)
    return async
end

local function RunNextSuite(suites, index, callback)
    local id = suites[index]
    if not id then
        callback()
        return
    end

    local async = DoRunTestSuite(id, internal.suites[id], function(stats)
        suites[index] = stats
        RunNextSuite(suites, index + 1, callback)
    end)
    return async
end

local function RunTestSuite(self, id, callback)
    local runs = { id }
    local async = RunNextSuite(runs, 1, function()
        ShowResult(runs)
        if callback then callback() end
    end)
    return async
end
internal.RunTestSuite = RunTestSuite

local function RunTestSuites(self, ids, callback)
    local async = RunNextSuite(ids, 1, function()
        ShowResult(ids)
        if callback then callback() end
    end)
    return async
end
internal.RunTestSuites = RunTestSuites

local function RunAll(self, callback)
    local runs = {}
    for id in pairs(internal.suites) do
        runs[#runs + 1] = id
    end

    local async = RunNextSuite(runs, 1, function()
        ShowResult(runs)
        if callback then callback() end
    end)
    return async
end
internal.RunAll = RunAll
