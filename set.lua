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

local Set = {}

function Set:new(list)
    local set = {}
    setmetatable(set, {
        __index = Set,
        __tostring = Set.tostring
    })
    set.items = {}
    set.size = 0
    set:addAll(list)
    return set
end

function Set:intersection(a, b)
    local result = Set:new();

    a:each(function(value)
        if (b:has(value)) then
            result:add(value)
        end
    end)

    return result
end

function Set:add(value)
    if not self.items[value] then
        self.items[value] = true
        self.size = self.size + 1
    end
end

function Set:addAll(list)
    if type(list) == 'table' then
        for _, value in ipairs(list) do
            self:add(value);
        end
    end
end

function Set:remove(value)
    if self:has(value) then
        self.items[value] = nil
        self.size = self.size - 1
    end
end

function Set:removeAll(list)
    for _, value in ipairs(list) do
        self:remove(value)
    end
end

function Set:has(value)
    return self.items[value] ~= nil
end

function Set:each(callback)
    for key in pairs(self.items) do
        callback(key)
    end
end

function Set:list()
    local _list = {}
    for key in pairs(self.items) do
        table.insert(_list, key)
    end
    return _list
end

function Set:tostring()
    local s = "{ "
    local sep = ""
    for e in pairs(self.items) do
        s = s .. sep .. e
        sep = ", "
    end
    return s .. " }"
end

return Set
