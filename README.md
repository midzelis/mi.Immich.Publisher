# Immich Publisher [im]

A plugin for Lightroom Classic to publish collections from Lightroom into Immich Albums.

This plugin never deletes images!

This plugin creates a relationship between local photos and collections and immich assets and albums. If the same photo is present in multiple collections, that relationship is maintained in immich - there are no additional copies created, just memberships.

Exports will upload photos to Immich without adding them to an alubm. However, if you later create a published collection with those previously exported pictures, the photos will not be re-uploaded, only the memberships will be added.

Both "Export" and "Publish" functions work.

### Known issues

-   If you remove a photo from a published Lightroom collection - the "Publish" action will not remove the photo right away. It appears that Lightroom does not invoke the Publishing plugin when this happens - at least I haven't been able to figure this out yet.
    -   Workaround
        -   Mark a file for republishing. This will cause the plugin to run, and it will check that all the local files are synced to the remote.

### Advanced

Turn on Logging if you want to see more information about what is being send to the server. Verbose logging is very versbose, and normal logging is probably the most you want.

### Future

I plan on adding keywords, comments, likes, and additional enhancements in the future.

PRs Welcome!
