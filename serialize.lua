--
-- Copyright (c) 2024 Min Idzelis
--
-- This file is part of LR-Immich.
--
-- This majority of this file was retrieved from https://stackoverflow.com/a/6081639
-- which contains the serializeTable function written by Henrik Ilgen.
--
-- That method and this file are licensed using CC BY-SA 3.0. See LICENSE in this folder for more details.
--

local function _pack(...)
    return { n = select("#", ...), args = ... }
end

local function _serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if (type(name) == "string") then
        if name then tmp = tmp .. name .. " = " end
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. _serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

return {
    serializeTable = _serializeTable,
    pack = _pack,
}
