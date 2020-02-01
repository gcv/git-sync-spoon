local obj = { name = "Sync" }
obj.__index = obj

function obj.new(displayPath, interval)
   local self = {
      displayPath = displayPath,
      interval = interval,
      lastSync = nil,
      status = nil,
      started = nil,
      timer = nil,
      task = nil
   }
   setmetatable(self, obj)
   return self
end

function obj:start()
   print("starting sync for ", self.displayPath)
   self.timer = hs.timer.new(
      self.interval,
      function()
         self:go()
      end,
      true -- continueOnError
   )
   self.started = os.time()
   self.status = nil
   self.timer:start()
end

function obj:pause()
   print("pausing sync", self.displayPath)
   self.timer:stop()
end

function obj:unpause()
   print("unpausing sync", self.displayPath)
   self.timer:start()
end

function obj:stop()
   print("stopping sync for ", self.displayPath)
   self:updateStatus("stopped")
   if self.timer then
      self.timer:stop()
      self.timer = nil
      self.started = nil
   end
end

function obj:go()
   -- savedStatus complexity is to allow running a manual sync even when the
   -- service is stopped and go back to the same status it was in before
   local savedStatus = self.status
   if "running" == savedStatus then
      return
   end
   self.lastSync = os.time()
   local realPath = hs.fs.pathToAbsolute(self.displayPath)
   if nil == realPath then
      self:updateStatus("error")
      return
   end
   -- do actual work
   self:updateStatus("running")
   self.task = hs.task.new(
      self.app.conf.gitSyncScript,
      function(code, stdout, stderr)
         if 0 == code then
            print("sync successful") -- FIXME: Remove this.
            if "stopped" == savedStatus then
               self:updateStatus("stopped")
            else
               self:updateStatus("ok")
            end
         else
            print("sync failed: " .. stdout .. stderr)
            self:updateStatus("error")
         end
      end
   )
   local env = self.task:environment()
   env["PATH"] = self.app.conf.gitDirectory .. ":/usr/bin:/bin"
   self.task:setEnvironment(env)
   self.task:setWorkingDirectory(realPath)
   self.task:start()
end

function obj:display()
   local fmt = "%H:%M:%S"
   local resTitle = ""
   -- status
   if "ok" == self.status then
      resTitle = resTitle .. "✓"
   elseif "error" == self.status then
      resTitle = resTitle .. "!"
   elseif "running" == self.status then
      resTitle = resTitle .. "⟳"
   elseif "stopped" == self.status then
      resTitle = resTitle .. "×"
   else
      resTitle = resTitle .. "•"
   end
   -- path
   resTitle = resTitle .. " " .. self.displayPath
   -- last sync
   if self.lastSync then
      resTitle = resTitle ..
         " (last: " .. os.date(fmt, self.lastSync) ..
         "; next: " .. os.date(fmt, self.lastSync + self.interval) .. ")"
   elseif self.started then
      resTitle = resTitle ..
         " (next: " .. os.date(fmt, self.started + self.interval) .. ")"
   end
   -- done
   return {
      title = resTitle,
      disabled = ("running" == self.status),
      fn = function()
         self:go()
      end
   }
end

function obj:updateStatus(newStatus)
   self.status = newStatus
   self.app:updateMenuIcon()
end

return obj
