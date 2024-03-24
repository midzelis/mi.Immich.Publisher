--
-- Copyright (c) 2024 Min Idzelis
--
-- This file is part of LR-Immich.
--
-- Foobar is free software: you can redistribute it and/or modify it under the terms
-- of the GNU General Public License as published by the Free Software Foundation,
-- either version 3 of the License, or (at your option) any later version.
--
-- LR-Immich is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along with Foobar.
-- If not, see <https://www.gnu.org/licenses/>.

local log = import 'LrLogger' ('immich')
local LrPrefs = import 'LrPrefs'
local prefs = LrPrefs.prefsForPlugin()

Log = {}

function Log:new(list)
    local _log = {}
    setmetatable(_log, {
        __index = Log,
    })
    prefs:addObserver('debug', _log.update)
    prefs:addObserver('verbose', _log.update)
    if prefs.debug then
        log:enable('logfile')
    else
        log:disable()
    end
    return _log
end

function Log:update()
    if prefs.debug then
        log:enable('logfile')
        log:info("Enabling logging")
    else
        log:info("Disabling logging")
        log:disable()
    end
end

function Log:info(...)
    if prefs.debug then
        log:info(...)
    end
end

function Log:debug(...)
    Log:trace(...)
end

function Log:trace(...)
    if prefs.debug == true and prefs.verbose == true then
        log:debug(...)
    end
end

return Log
