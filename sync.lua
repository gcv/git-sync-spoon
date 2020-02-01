local obj = { name = "Sync" }
obj.__index = obj

function obj.new(display_path, interval)
   local self = {
      display_path = display_path,
      interval = interval,
      last_sync = nil,
      status = nil,
      started = nil,
      timer = nil,
      task = nil
   }
   setmetatable(self, obj)
   return self
end

function obj:start()
   print("starting sync for ", self.display_path)
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
   print("pausing sync", self.display_path)
   self.timer:stop()
end

function obj:unpause()
   print("unpausing sync", self.display_path)
   self.timer:start()
end

function obj:stop()
   print("stopping sync for ", self.display_path)
   self.status = "stopped"
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
   self.last_sync = os.time()
   local real_path = hs.fs.pathToAbsolute(self.display_path)
   if nil == real_path then
      self.status = "error"
      return
   end
   -- do actual work
   self.status = "running"
   self.task = hs.task.new(
      self.conf.gitSyncScript,
      function(code, stdout, stderr)
         if 0 == code then
            print("sync successful") -- FIXME: Remove this.
            if "stopped" == savedStatus then
               self.status = "stopped"
            else
               self.status = "ok"
            end
         else
            print("sync failed: " .. stdout .. stderr)
            self.status = "error"
         end
      end
   )
   local env = self.task:environment()
   env["PATH"] = self.conf.gitDirectory .. ":/usr/bin:/bin"
   self.task:setEnvironment(env)
   self.task:setWorkingDirectory(real_path)
   self.task:start()
end

function obj:display()
   local fmt = "%H:%M:%S"
   local res_title = ""
   -- status
   if "ok" == self.status then
      res_title = res_title .. "✓"
   elseif "error" == self.status then
      res_title = res_title .. "!"
   elseif "running" == self.status then
      res_title = res_title .. "⟳"
   elseif "stopped" == self.status then
      res_title = res_title .. "×"
   else
      res_title = res_title .. "•"
   end
   -- path
   res_title = res_title .. " " .. self.display_path
   -- last sync
   if self.last_sync then
      res_title = res_title ..
         " (last: " .. os.date(fmt, self.last_sync) ..
         "; next: " .. os.date(fmt, self.last_sync + self.interval) .. ")"
   elseif self.started then
      res_title = res_title ..
         " (next: " .. os.date(fmt, self.started + self.interval) .. ")"
   end
   -- done
   return {
      title = res_title,
      disabled = ("running" == self.status),
      fn = function()
         self:go()
      end
   }
end

return obj
