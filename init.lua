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

local function resolve_path(relative_path)
   return hs.fs.pathToAbsolute(relative_path)
end

--- Objects:
local Sync = dofile(obj.spoonPath .. "/sync.lua")

--- Note:
--- might have to do this in order to keep the timer firing as expected between sleeps
--- myTimer = hs.timer.new(60, someFn)
--- myTimer:start()

--- Internal state
--- FIXME: ${XDG_CONFIG_HOME:-$HOME/.config}
obj.confFile = os.getenv("HOME") .. "/.config/GitSyncSpoon.lua"
obj.conf = {}
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
   -- read conf file
   local confFn, err = loadfile(self.confFile, "t", self.conf)
   if confFn then
      confFn()
   else
      -- FIXME: Need better error handling and reporting.
      print(err)
      print("failed to load")
   end
   -- bail out if disabled
   if not self.conf.enabled then
      return
   end
   -- read resources (script and icon images), error-check as needed
   -- ...
   -- process conf file: sensible defaults
   if not self.conf.defaultInterval then
      self.conf.defaultInterval = 600
   end
   if not self.conf.git then
      self.conf.git = "/usr/bin/git"
   else
      self.conf.git = resolve_path(self.conf.git)
   end
   Sync.git = self.conf.git
   -- process conf file: for each repo, create a new sync object
   for idx, repo in ipairs(self.conf.repos) do
      local path = type(repo) == "string" and repo or repo.path
      local interval = (type(repo) == "table" and repo.interval) and repo.interval or self.conf.defaultInterval
      self.syncs[#self.syncs+1] = Sync.new(path, resolve_path(path), interval)
   end
   -- if menu icon enabled, turn it on (if no repos, show error message and icon)
   self.menu = hs.menubar.new()
   self.menu:setIcon("/Users/kostya/Desktop/icon.png")
   self.menu:setMenu(self.makeMenuTable)
   -- go
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
   obj.gitSyncActive = true
   -- loop over each sync and start its timer

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
   obj.gitSyncActive = false
   -- loop over each sync and stop its timer

end

--- GitSync:makeMenuTable()
function obj:makeMenuTable()
   local res = {}
   res[#res+1] = { title = "-" }
   for idx, sync in ipairs(obj.syncs) do
      res[#res+1] = {
         title = sync.display_path .. " (" .. sync.interval .. ")",
         fn = function()
            sync:go()
         end
      }
   end
   res[#res+1] = { title = "-" }
   if obj.gitSyncActive then
      res[#res+1] = {
         title = "Disable",
         fn = obj.stop
      }
   else
      res[#res+1] = {
         title = "Enable",
         fn = obj.start
      }
   end
   return res
end

return obj
