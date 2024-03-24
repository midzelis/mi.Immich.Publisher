--
-- Copyright (c) 2024 Min Idzelis
--
-- This file is part of LR-Immich.
--
-- Foobar is free software: you can redistribute it and/or modify it under the terms
-- of the GNU General Public License as published by the Free Software Foundation,
-- either version 3 of the License, or (at your option) any later version.
--
-- LR-Immich is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along with Foobar.
-- If not, see <https://www.gnu.org/licenses/>.
--

local Log = require "log"

_G.log = Log:new()

_G.LrHttp = import 'LrHttp'
_G.LrDate = import 'LrDate'
_G.LrPathUtils = import 'LrPathUtils'
_G.LrErrors = import "LrErrors"
_G.LrTasks = import "LrTasks"

_G.json = require "json"
_G.serialize = require "serialize"
_G.Set = require "set"
_G.utils = require "utils"

_G.LrView = import 'LrView'
_G.bind = LrView.bind
_G.LrBinding = import 'LrBinding'
_G.LrDialogs = import 'LrDialogs'

_G.LrPrefs = import 'LrPrefs'
_G.prefs = _G.LrPrefs.prefsForPlugin()

_G.LrErrors = import "LrErrors"
