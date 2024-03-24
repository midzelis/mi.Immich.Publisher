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

local Immich = require "immich"

local function _updateCantExportBecause(propertyTable)
    if (utils.nilOrEmpty(propertyTable.api_key) or utils.nilOrEmpty(propertyTable.server)) then
        propertyTable.LR_cantExportBecause = "Need to create API"
        return
    end

    propertyTable.LR_cantExportBecause = nil
end

local function _createAlbum(immich, exportSession, name, remoteIds)
    local response = immich:create_album(name, '', remoteIds);
    exportSession:recordRemoteCollectionId(response.id);
    exportSession:recordRemoteCollectionUrl(immich:albumWebUrl(response.id));
end

local function _updateRemovedPhotosInRemote(immich, exportContext)
    -- detect photos that have been publushed but have been removed from collection
    -- NOTE: due to a LR bug, there is no way to detect that a photo has been removed
    -- from a collection without a forced publishing at at least one picture

    local publishedCollection = exportContext.publishedCollection
    if not publishedCollection then
        -- this is a regular export
        return false, Set:new()
    end
    local remoteId = exportContext.publishedCollectionInfo['remoteId'];
    if remoteId == nil then
        return false, Set:new()
    end

    log:info("Synchronizing removed photos from lightroom collection")
    local allPhotos = publishedCollection:getPublishedPhotos()
    local photoIds = utils.map(allPhotos, function(photo) return photo:getRemoteId() end)
    photoIds = utils.filter(photoIds, utils.notNil)
    photoIds = Set:new(photoIds);
    local response = immich:album_info(remoteId)
    -- if remove album doesn't exist, nothing to do
    if not response['error'] then
        -- side effect - while we're here, set/update collections' web url
        exportContext.exportSession:recordRemoteCollectionUrl(immich:albumWebUrl(response.id));
        local assets = Set:new(utils.map(response.assets, function(asset) return asset.id end))
        -- save existingPhotos, to optimize album update in later step
        local existingPhotos = Set:intersection(assets, photoIds);
        assets:removeAll(photoIds:list());
        if assets.size > 0 then
            log:info("Found locally removed photos: "..tostring(assets.size))
            log:info("Removing from immich album only (photos will not be deleted)")
            immich:remove_album_assets( remoteId, assets:list())
        else
            log:info("Did not detect any locally removed photos to sync to immich album")
        end
        return true, existingPhotos
    end
    return false, Set:new()
end


local function processRenderedPhotos(functionContext, exportContext)
    log:info('Starting immich export/publishing...');
    local api_key = exportContext.propertyTable.api_key
    local server = exportContext.propertyTable.server

    local publishing = exportContext.propertyTable.LR_isExportForPublish == true
    local immich = Immich:new(server, api_key);

    local exportSession = exportContext.exportSession
    local remoteAlbumExists, existingPhotosIdsInAlbum = _updateRemovedPhotosInRemote(immich, exportContext);

    -- gather up ids for photos to export
    local identifiers = {}
    for photo in exportSession:photosToExport() do
        table.insert(identifiers, tostring(photo.localIdentifier))
    end
    local alreadyExisting = immich:asset_exists(identifiers)
    for key in pairs(alreadyExisting) do
        local response = immich:search_metadata({ deviceAssetId = key, deviceId = immich.deviceId })
        if response.assets.count ~= 1 then
            log:info("Detected duplicate photo on remote");
            -- we can't uniquely find the remote identifier, treat this is as error for now
            LrErrors.throwUserError("Detected duplicate photo on remote")
        end
        -- record the remote id for the local id
        alreadyExisting[key] = response.assets.items[1].id
    end
    -- set up progress bars
    local total = exportSession:countRenditions() * 2
    local progressScope = exportContext:configureProgress { title = "Uploading photos to Immich" }
    progressScope:attachToFunctionContext( functionContext )
    progressScope:setPortionComplete( 0, total )
    local renditions = {}
    for _, redition in exportSession:renditions({ stopIfCanceled = true, progressScope = progressScope}) do
        table.insert(renditions, redition)
    end
    local remoteIds = {}
    for _, rendition in ipairs(renditions) do
        local localIdentifier = tostring(rendition.photo.localIdentifier)
        local remoteId = alreadyExisting[localIdentifier];
        if type(remoteId) == 'string' then
            log:info('Already present, Local: ' .. localIdentifier .. ' Remote: ' .. remoteId)
            rendition:skipRender()
            if publishing then
                rendition:recordPublishedPhotoId(remoteId);
            end
            table.insert(remoteIds, remoteId)
        end
    end
    for i, rendition in ipairs(renditions) do
        if not rendition.wasSkipped then
            local _, pathOrMessage = rendition:waitForRender()
            local response = immich:asset_upload(rendition.photo, pathOrMessage)
            if publishing then
                log:info('Created Immich photo with id: ' .. response.id)
                rendition:recordPublishedPhotoId(response.id)
            end
            table.insert(remoteIds, response.id)
        end
        progressScope:setPortionComplete( i, total )
    end

    if publishing then
        -- album sync
        local remoteId = exportContext.publishedCollectionInfo['remoteId'];
        local name = exportContext.publishedCollectionInfo['name'];
        if not remoteId then
            -- create the album
            log:info('Creating Immich ' .. name)
            _createAlbum(immich, exportSession, name, remoteIds)
        else
            if remoteAlbumExists then
                -- add to album
                log:info('Immich album already exists, adding assets to it')
                existingPhotosIdsInAlbum:removeAll(remoteIds);
                if existingPhotosIdsInAlbum.size > 0 then
                    log:info('Adding photos to immich album: '..tostring(existingPhotosIdsInAlbum.size))
                    immich:add_album_assets(remoteId, existingPhotosIdsInAlbum:list())
                else
                    log:info('All collection photos already present in immich album')
                end
            else
                -- remote album was deleted, recreate
                log:info('Immich album "' .. name .. '" was deleted, recreating and adding photos')
                _createAlbum(immich, exportSession, name, remoteIds)
            end
        end
    end

    progressScope:done()
end


local function startDialog(propertyTable)
    _updateCantExportBecause(propertyTable)
    propertyTable:addObserver('api_key', _updateCantExportBecause);
    propertyTable:addObserver('server', _updateCantExportBecause);
end

local function endDialog(propertyTable, why)

end

local function sectionsForTopOfDialog(f, propertyTable)
    -- if not props.api_key then
    --     props.api_key=''
    -- end
    return {
        -- Section for the top of the dialog.
        {
            title = "Immich Options",
            f:row {
                f:static_text {
                    title = "Welcome to Immich Publisher",
                    fill_horizontal = 1,
                },
            },
            f:row {
                spacing = f:control_spacing(),

                f:static_text {
                    title = "Immich server URL",
                    width = 150,
                },

                f:edit_field {

                    fill_horizontal = 1,
                    enabled = true,
                    value = bind 'server',
                    immediate = true,
                },
            },
            f:row {
                spacing = f:control_spacing(),

                f:static_text {
                    title = "API Key",
                    width = 150,
                },

                f:edit_field {

                    fill_horizontal = 1,
                    enabled = true,
                    value = bind 'api_key',
                    immediate = true,
                },
            },
        },

    }
end


return {
    hideSections = { 'exportLocation' },
	exportPresetFields = {
		{ key = 'api_key', default = nil },
		{ key = 'server', default = nil },
	},
    allowFileFormats = nil, -- nil equates to all available formats
    allowColorSpaces = nil, -- nil equates to all color spaces
    supportsIncrementalPublish = true,
    small_icon = 'immich.png',
    startDialog = startDialog,
    endDialog = endDialog,
    processRenderedPhotos = processRenderedPhotos,
    sectionsForTopOfDialog = sectionsForTopOfDialog,
}
