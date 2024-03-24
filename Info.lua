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

return {
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3,
	LrToolkitIdentifier = 'midzelis-LR-Immich',
	LrPluginName = "[mi] Immich Publisher",
	LrPluginInfoProvider = 'plugininfo.lua',
	LrPluginInfoUrl = "https://github.com/midzelis/immich-publisher",
	LrExportServiceProvider = {
		title = "Immich",
		file = "publisher.lua",
	},
	LrInitPlugin = "init.lua",
	VERSION = { major = 1, minor = 0, revision = 0, build = "0", },
}
