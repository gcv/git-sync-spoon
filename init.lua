--- === Git Sync ===
---
--- Orchestrates automatic synchronization of a local Git repository with a
--- remote one. See https://github.com/simonthum/git-sync for details of the
--- underlying script. This Spoon provides a convenient wrapper for git-sync
--- with the following features:
---
--- - menu bar status display
--- - timer operation for polling remote repositories
--- - configuration for multiple repositories
---
--- This is intended as a private, Git-backed replacement for synchronization
--- services like Dropbox and Syncthing.
---
--- Download: FIXME

local obj = {}
obj.__index = obj

--- Metadata
obj.name = "GitSync"
obj.version = "0.1" -- FIXME
obj.author = "gcv"
obj.homepage = "https://github.com/gcv/git-sync.spoon"
obj.license = "CC0"

--- Internal function used to find code location.
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
obj.spoonPath = script_path()

--- Internal state
obj.syncs = {}

--- GitSync:init()
--- Method
--- Initialize GitSync.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:init()
   -- read resources (script and icon images), error-check as needed
   -- read conf file
   -- if conf file not found, error out
   -- if conf file is bad, error out
   -- process conf file: for each sync, create a new sync object
   -- if menu icon enabled, turn it on (if no syncs, show error message and icon)
   self:start()
end

--- GitSync:start()
--- Method
--- Start GitSync.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:start()
   -- loop over each sync and start its timer

   obj.gitSyncActive = true
end

--- GitSync:stop()
--- Method
--- Stop GitSync.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:stop()
   -- loop over each sync and stop its timer

   obj.gitSyncActive = false
end

return obj
