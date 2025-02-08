@echo off
REM SPDX-FileCopyrightText: 2023 sirinsidiator
REM
REM SPDX-License-Identifier: Artistic-2.0

FOR %%A IN (%*) DO (
    IF "%%A" == "--verbose" SET ESOLUA_ARGS=-d
    IF "%%A" == "-v" SET ESOLUA_ARGS=-d
)

IF NOT "%ESOUI_HOME%"=="" (
    SET ESOLUA_ARGS=%ESOLUA_ARGS% -s %ESOUI_HOME%
)

esolua %ESOLUA_ARGS% -- run.lua %*
