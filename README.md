<!--
SPDX-FileCopyrightText: 2023 sirinsidiator

SPDX-License-Identifier: Artistic-2.0
-->

Taneth is a test framework for Elder Scrolls Online addons, inspired by [Mocha](https://mochajs.org/) and [busted](https://lunarmodules.github.io/busted/).
It can be used both inside the game and outside with the help of [ESOLua](https://github.com/sirinsidiator/ESOLua).

Test suites follow the same structure as Mocha and busted, with the exception that they have to be wrapped into a call to Taneth. A simple test file could look like this:
```lua
if not Taneth then return end
Taneth("MySuite", function()
    describe("some group", function()
        it("some test", function()
            assert.fail("I'm a bad test.")
        end)
    end)
end)
```

Outside the game you can use Taneth.bat **as long as esolua.exe is on your system's path**.
Pass `--help` to it for more information on how to use the command.

Running the test above will show output like this:
```
MySuite / some group / some test
test.lua:10: I'm a bad test.

Results for suite 'MySuite':
-
0 successes / 1 failures / 0 errors : 0.00 seconds
```

To run tests inside the game you can use the `/taneth` slash command.
Per default it will simply run all available test suites, but you can pass it the id (`MyTest` in the example above) to limit it to a specific test suite.

When a test behaves differently outside the game than it does inside, please make sure to report it either here or on the ESOLua project if it's due to Lua itself. The ultimate goal is to have it mimic the game as closely as possible.

The project is currently in a very early stage and many features are not yet implemented.
If you have any particular requests, feel free to open an issue.