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

function handle(properties, key, newValue)
    prefs[key] = newValue
end

local function sectionsForTopOfDialog(f, props)
    props.debug = prefs.debug or false
    props.verbose = prefs.verbose or false

    props:addObserver('debug', handle);
    props:addObserver('verbose', handle);

    local section = {
        bind_to_object = props,
        title = "Immich Options",
        f:row {
            f:static_text {
                title = "Plugin by Min Idzelis",
                fill_horizontal = 1,
            },
        },
        f:row {
            f:static_text {
                title = "License: GPL",
                fill_horizontal = 1,
            },
        },
        f:row {
            f:checkbox {
                enabled = true,
                title = 'Enable debug',
                fill_horizontal = 1,
                value = bind 'debug'
            },
        },
        f:row {
            f:view {
                width = 20,
            },
            f:checkbox {
                enabled = bind({ key = 'debug' }),
                margin_left = 5,
                title = 'Verbose',
                spacing = 10,
                fill = 0,
                value = bind 'verbose'
            },
        },
    }
    return {
        section
    }
end

return {
    sectionsForTopOfDialog = sectionsForTopOfDialog,
}
