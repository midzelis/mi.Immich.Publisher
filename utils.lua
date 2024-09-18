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

local function map(array, callback)
    local new_array = {}
    for i, v in ipairs(array) do
        new_array[i] = callback(v)
    end
    return new_array
end

local function filter(array, callback)
    local new_array = {}
    for _, v in ipairs(array) do
        if (callback(v) == true) then
            table.insert(new_array, v);
        end
    end
    return new_array
end

local function notNil(val)
    return type(val) ~= 'nil'
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function nilOrEmpty(val)
    return val == nil or trim(val) == ''
end

return {
    map = map,
    notNil = notNil,
    filter = filter,
    trim = trim,
    nilOrEmpty = nilOrEmpty,
}
