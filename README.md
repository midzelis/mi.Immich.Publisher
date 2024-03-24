# Immich Publisher [im]

A plugin for Lightroom Classic to publish collections from Lightroom into Immich Albums. 

This plugin never deletes images! 

This plugin creates a relationship between local photos and collections and immich assets and albums. If the same photo is present in multiple collections, that relationship is maintained in immich - there are no additional copies created, just memberships. 

Exports will upload photos to immich without adding them to an alubm. However, if you later create a published collection with those previously exported pictures, the photos will not be re-uploaded, only the memberships will be added. 

Export and Publish functions work. 

### Known issues
* Immich doesn't support overwriting an image for the time being. So, if you make edits to an image in Lightroom, and try to republish, it will not show up on immich
    * I'll be enhancing Immich in the future to support this. 
* If you remove a photo from a Lightroom collection, I haven't been able to figure out how to get notified.   
    * Workaround 
        * Mark a file for republishing. This will cause the plugin to run, and it will check that all the local files are synced to the remote.   

### Advanced
Turn on Logging if you want to see more information about what is being send to the server. Verbose logging is very versbose, and normal logging is probably the most you want. 

### Future
I plan on adding keywords, comments, likes, and additional enhancements in the future. 

PRs Welcome! 
