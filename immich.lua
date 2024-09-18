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
--

Immich = {}
local LrFileUtils = import 'LrFileUtils'

function Immich:new(server, api_key)
    local immich = {}
    setmetatable(immich, {
        __index = Immich,
    })
    if "/" == server:sub(-1) then
        immich.server = server:sub(1, -2)
    else
        immich.server = server
    end
    immich.api_key = api_key
    immich.deviceId = 'lightroom.immich'
    return immich
end

function Immich:_authHeaders(additional)
    local headers = {
        { field = 'x-api-key', value = self.api_key },
        { field = 'Accept',    value = 'application/json' }
    }
    for key, val in pairs(additional or {}) do
        table.insert(headers, { field = key, value = val })
    end
    return headers
end

function _invoke(func)
    local result = func()
    if not result then
        log:trace("error!!", result)
        LrErrors.throwUserError("Error sending HTTP(S) request")
    end
    log:trace("HTTP Response: ", result)
    if (result == '') then
        return {}
    end
    return json.decode(result)
end

function Immich:_get(url)
    log:trace('GET ' .. url)
    return _invoke(function() return LrHttp.get(url, self:_authHeaders()) end)
end

function Immich:_send(url, body, method)
    local headers = self:_authHeaders({ ['Content-Type'] = 'application/json' })
    local encoded = json.encode(body)
    log:trace((method or 'POST') .. ' ' .. url, encoded)
    return _invoke(function() return LrHttp.post(url, encoded, headers, method) end)
end

function Immich:_postMultipart(url, formdata, method)
    log:trace('POST (multipart) ' .. url)
    return _invoke(function() return LrHttp.postMultipart(url, formdata, self:_authHeaders(), method) end)
end

function Immich:_url(path)
    return self.server .. path
end

function Immich:asset_trash(identifiers)
    local url = self:_url('/api/assets')
    local body = {
        ids = identifiers,
    }
    local response = self:_send(url, body, 'DELETE')
    local set = Set:new(response.existingIds)
    return set.items
end

function Immich:asset_exists(identifiers)
    local url = self:_url('/api/assets/exist')
    local body = {
        deviceAssetIds = identifiers,
        deviceId = self.deviceId,
    }
    local response = self:_send(url, body)
    local set = Set:new(response.existingIds)
    return set.items
end

function Immich:asset_upload(photo, rendered)
    local url = self:_url('/api/assets')
    local name = LrPathUtils.leafName(rendered)
    local date = photo:getRawMetadata("dateTimeOriginalISO8601")
    -- local fileSize = LrFileUtils.fileAttributes('/tmp/out.jpg').fileSize
    -- log:debug("fileSize", fileSize)
    rendered = string.gsub(rendered, " ", "\\ ")

    local formdata = {
        { name = 'assetData',      filePath = rendered,          fileName = name, contentType = 'application/octet-stream' },
        { name = 'deviceAssetId',  value = photo.localIdentifier },
        { name = 'deviceId',       value = self.deviceId },
        { name = 'fileCreatedAt',  value = date },
        { name = 'fileModifiedAt', value = date },
    }

    return self:_postMultipart(url, formdata)
end

function Immich:_cmdline_quote()
    if WIN_ENV then
        return '"'
    elseif MAC_ENV then
        return ''
    else
        return ''
    end
end

function Immich:_curl_cmd()
    if WIN_ENV then
        return '"' .. LrPathUtils.child(LrPathUtils.child(_PLUGIN.path, "win64-curl"), "curl.exe") .. '"'
    elseif MAC_ENV then
        return 'curl'
    else
        return ''
    end
end

function Immich:asset_replace_upload(assetId, photo, rendered)
    local url = self:_url('/api/assets/' .. assetId .. '/original')
    local name = LrPathUtils.leafName(rendered)
    local date = photo:getRawMetadata("dateTimeOriginalISO8601")
    rendered = string.gsub(rendered, " ", "\\ ")

    local curl = self:_curl_cmd();

    local cmd = string.format(
        '%s -L -X PUT "%s" ' ..
        '-H "x-api-key: %s" ' ..
        '-H "Content-Type: multipart/form-data" ' ..
        '-H "Accept: application/json" ' ..
        '-F "fileCreatedAt=\"%s\"" ' ..
        '-F "fileModifiedAt=\"%s\"" ' ..
        '-F "deviceId=\"%s\"" ' ..
        '-F "deviceAssetId=\"%s\"" ' ..
        '-F "assetData=@\"%s;filename=%s\""',
        curl, url, self.api_key, date, date, self.deviceId, photo.localIdentifier, rendered, name
    )

    local fullCmd = self:_cmdline_quote() .. cmd .. self:_cmdline_quote()
    log:info('Executing: ' .. fullCmd)
    -- LrDialogs.confirm('hi')
    -- LrErrors.throwUserError("abort");
    local code = LrTasks.execute(fullCmd)
    log:info('Result from curl PUT', code)
end

function Immich:album_info(id)
    local url = self:_url('/api/albums/' .. id)
    return self:_get(url)
end

function Immich:create_album(albumName, description, assetIds)
    local url = self:_url('/api/albums')
    local body = {
        albumName = albumName,
        description = description,
        assetIds = assetIds,
    }
    return self:_send(url, body)
end

function Immich:add_album_assets(albumId, assetIds)
    log:trace('add_album_assets', albumId, Set:new(assetIds))
    local url = self:_url('/api/albums/' .. albumId .. '/assets')
    local body = {
        ids = assetIds,
    }
    return self:_send(url, body, 'PUT')
end

function Immich:remove_album_assets(albumId, assetIds)
    log:trace('remove_album_assets', albumId, assetIds)
    local url = self:_url('/api/albums/' .. albumId .. '/assets')
    local body = {
        ids = assetIds,
    }
    return self:_send(url, body, 'DELETE')
end

function Immich:search_metadata(body)
    local url = self:_url('/api/search/metadata')
    return self:_send(url, body)
end

function Immich:albumWebUrl(albumId)
    return self:_url('/albums/' .. albumId)
end

function Immich:albumAssetWebUrl(albumId, assetId)
    return self:_url('/albums/' .. albumId .. '/photos/' .. assetId)
end

function Immich:assetWebUrl(assetId)
    return self:_url('/photos/' .. assetId)
end

return Immich
