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
local function scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
obj.spoonPath = scriptPath()

--- Objects:
local Sync = dofile(obj.spoonPath .. "/sync.lua")

--- Internal state:
obj.confFile = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/GitSyncSpoon.lua"
obj.conf = {}
obj.syncs = {}
obj.systemWatcher = nil

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
   -- bail out if disabled; omission equivalent to "enabled = true"
   if nil ~= self.conf.enabled and (not self.conf.enabled) then
      print("disabled")
      return
   end
   -- configure Sync object prototype
   Sync.app = self
   -- read resources (script and icon images), error-check as needed
   -- ...
   self.conf.gitSyncScript = obj.spoonPath .. "/resources/git-sync"
   -- process conf file: sensible defaults
   if not self.conf.interval then
      self.conf.interval = 600
   end
   if not self.conf.git then
      self.conf.git = "/usr/bin/git"
   else
      self.conf.git = hs.fs.pathToAbsolute(self.conf.git)
   end
   -- XXX: Use a regex to extract directory containing git binary for adding to
   -- the PATH of sync task environments. basedir() would have been better, but
   -- does not appear to be available in Lua or Hammerspoon.
   self.conf.gitDirectory = (self.conf.git:match("(.*)/(.*)$"))
   -- process conf file: for each repo, create a new sync object
   for idx, repo in ipairs(self.conf.repos) do
      local path = "string" == type(repo) and repo or repo.path
      local interval = ("table" == type(repo) and repo.interval) and repo.interval or self.conf.interval
      self.syncs[#self.syncs+1] = Sync.new(path, interval)
   end
   -- if menu icon enabled, turn it on (FIXME: if no repos, show error message and icon)
   self.menu = hs.menubar.new()
   self.menu:setIcon("/Users/kostya/Desktop/icon.png")
   self.menu:setMenu(self.makeMenuTable)
   -- activate system watcher
   self.systemWatcher = hs.caffeinate.watcher.new(
      function(evt)
         self:systemWatchFn(evt)
      end
   )
   -- go
   self:start()
   return self
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
   for idx, sync in ipairs(obj.syncs) do
      sync:start()
   end
   obj.systemWatcher:start()
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
   obj.systemWatcher:stop()
   for idx, sync in ipairs(obj.syncs) do
      sync:stop()
   end
   obj.gitSyncActive = false
end

--- GitSync:makeMenuTable()
function obj:makeMenuTable()
   local res = {}
   res[#res+1] = { title = "-" }
   for idx, sync in ipairs(obj.syncs) do
      res[#res+1] = sync:display()
   end
   res[#res+1] = { title = "-" }
   if obj.gitSyncActive then
      res[#res+1] = {
         title = "Disable",
         fn = function()
            obj.stop()
         end
      }
   else
      res[#res+1] = {
         title = "Enable",
         fn = function()
            obj.start()
         end
      }
   end
   return res
end

-- GitSync:systemWatchFn()
function obj:systemWatchFn(event)
   if hs.caffeinate.watcher.systemWillSleep == event then
      for idx, sync in ipairs(obj.syncs) do
         sync:pause()
      end
   elseif hs.caffeinate.watcher.systemDidWake == event then
      for idx, sync in ipairs(obj.syncs) do
         sync:unpause()
      end
   end
end

return obj
