-- SPDX-FileCopyrightText: 2025 sirinsidiator
--
-- SPDX-License-Identifier: Artistic-2.0

if not Taneth then return end
Taneth("eso", function()
    local function ToHex(value)
        if value == 0 then return "0x0" end
        local hex = ""
        local prefix = "0x"

        if value < 0 then
            value = -value
            prefix = "-0x"
        end

        while value > 0 do
            local remainder = value % 16
            value = (value - remainder) / 16
            hex = string.sub("0123456789ABCDEF", remainder + 1, remainder + 1) .. hex
        end

        return prefix .. hex
    end

    describe("bit functions", function()
        local input = {
            0x00,
            0x01,
            0x10,
            0x55555555,
            0xAAAAAAAA,
            0xFFFFFFFF,
            0x1FFFFFFFFFFFFF,
        }
        local inputCount = #input

        describe("BitAnd", function()
            local bitAndResults = {
                { 0x00,            0x00,       0x00,       0x00,      0x00, 0x00, 0x00 },
                { 0x01,            0x00,       0x01,       0x00,      0x01, 0x01 },
                { 0x10,            0x10,       0x00,       0x10,      0x10 },
                { 0x55555555,      0x00,       0x55555555, 0x55555555 },
                { 0xAAAAAAAA,      0xAAAAAAAA, 0xAAAAAAAA },
                { 0xFFFFFFFF,      0xFFFFFFFF },
                { 0x1FFFFFFFFFFFFF },
            }

            for i = 1, inputCount do
                describe(ToHex(input[i]), function()
                    local results = bitAndResults[i]
                    for j = i, inputCount do
                        it(ToHex(input[j]), function()
                            local expected = results[j - i + 1]
                            assert.is_not_nil(expected)

                            local actual = BitAnd(input[i], input[j])
                            if expected ~= actual then
                                df("i: %d, j: %d, expected: %s, actual: %s", i, j - i + 1, ToHex(expected),
                                    ToHex(actual))
                            end
                            assert.equals(expected, actual)
                        end)
                    end
                end)
            end
        end)

        describe("BitOr", function()
            local bitOrResults = {
                { 0x00,            0x01,            0x10,            0x55555555,      0xAAAAAAAA,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0x01,            0x11,            0x55555555,      0xAAAAAAAB,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0x10,            0x55555555,      0xAAAAAABA,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0x55555555,      0xFFFFFFFF,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0xAAAAAAAA,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0x1FFFFFFFFFFFFF },
            }

            for i = 1, inputCount do
                describe(ToHex(input[i]), function()
                    local results = bitOrResults[i]
                    for j = i, inputCount do
                        it(ToHex(input[j]), function()
                            local expected = results[j - i + 1]
                            assert.is_not_nil(expected)

                            local actual = BitOr(input[i], input[j])
                            if expected ~= actual then
                                df("i: %d, j: %d, expected: %s, actual: %s", i, j - i + 1, ToHex(expected),
                                    ToHex(actual))
                            end
                            assert.equals(expected, actual)
                        end)
                    end
                end)
            end
        end)

        describe("BitXor", function()
            local bitXorResults = {
                { 0x00, 0x01,            0x10,            0x55555555,      0xAAAAAAAA,      0xFFFFFFFF,      0x1FFFFFFFFFFFFF },
                { 0x00, 0x11,            0x55555554,      0xAAAAAAAB,      0xFFFFFFFE,      0x1FFFFFFFFFFFFE },
                { 0x00, 0x55555545,      0xAAAAAABA,      0xFFFFFFEF,      0x1FFFFFFFFFFFEF },
                { 0x00, 0xFFFFFFFF,      0xAAAAAAAA,      0x1FFFFFAAAAAAAA },
                { 0x00, 0x55555555,      0x1FFFFF55555555 },
                { 0x00, 0x1FFFFF00000000 },
                { 0x00 },
            }

            for i = 1, inputCount do
                describe(ToHex(input[i]), function()
                    local results = bitXorResults[i]
                    for j = i, inputCount do
                        it(ToHex(input[j]), function()
                            local expected = results[j - i + 1]
                            assert.is_not_nil(expected)

                            local actual = BitXor(input[i], input[j])
                            if expected ~= actual then
                                df("i: %d, j: %d, expected: %s, actual: %s", i, j - i + 1, ToHex(expected),
                                    ToHex(actual))
                            end
                            assert.equals(expected, actual)
                        end)
                    end
                end)
            end
        end)

        describe("BitNot", function()
            local bitNotResults = {
                0x1FFFFFFFFFFFFF,
                0x1FFFFFFFFFFFFE,
                0x1FFFFFFFFFFFEF,
                0x1FFFFFAAAAAAAA,
                0x1FFFFF55555555,
                0x1FFFFF00000000,
                0x00,
            }

            for i = 1, inputCount do
                it(ToHex(input[i]), function()
                    local expected = bitNotResults[i]
                    assert.is_not_nil(expected)

                    local actual = BitNot(input[i])
                    if expected ~= actual then
                        df("i: %d, expected: %s, actual: %s", i, ToHex(expected), ToHex(actual))
                    end
                    assert.equals(expected, actual)
                end)
            end

            local numBitsTests = {
                { 0, 0x1FFFFFFFFFFFFF },
                { 1, 0x1 },
                { 10, 0x3FF },
                { 53, 0x1FFFFFFFFFFFFF },
                { 54, 0x1FFFFFFFFFFFFF },
            }

            for i = 1, #numBitsTests do
                local test = numBitsTests[i]
                local input, expected = unpack(test)
                it(string.format("should accept %d numBits as a second argument", input), function()
                    local actual = BitNot(0, input)
                    assert.equals(expected, actual)
                end)
            end
        end)

        describe("BitLShift", function()
            local bitLShiftResults = {
                0x00,
                0x02,
                0x20,
                0xAAAAAAAA,
                0x155555554,
                0x1FFFFFFFE,
                0x3FFFFFFFFFFFFE,
            }

            for i = 1, inputCount do
                it(ToHex(input[i]), function()
                    local expected = bitLShiftResults[i]
                    assert.is_not_nil(expected)

                    local actual = BitLShift(input[i], 1)
                    if expected ~= actual then
                        df("i: %d, expected: %s, actual: %s", i, ToHex(expected), ToHex(actual))
                    end
                    assert.equals(expected, actual)
                end)
            end
        end)

        describe("BitRShift", function()
            local bitRShiftResults = {
                0x00,
                0x00,
                0x08,
                0x2AAAAAAA,
                0x55555555,
                0x7FFFFFFF,
                0x0FFFFFFFFFFFFF,
            }

            for i = 1, inputCount do
                it(ToHex(input[i]), function()
                    local expected = bitRShiftResults[i]
                    assert.is_not_nil(expected)

                    local actual = BitRShift(input[i], 1)
                    if expected ~= actual then
                        df("i: %d, expected: %s, actual: %s", i, ToHex(expected), ToHex(actual))
                    end
                    assert.equals(expected, actual)
                end)
            end
        end)
    end)
end)
