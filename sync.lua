local obj = { name = "Sync" }
obj.__index = obj

function obj.new(display_path, interval)
   local self = {
      display_path = display_path,
      interval = interval,
      last_sync = nil,
      status = nil,
      message = nil,
      started = nil,
      timer = nil
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
   self.message = nil
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
   self.message = "Stopped"
   if self.timer then
      self.timer:stop()
      self.timer = nil
      self.started = nil
   end
end

function obj:go()
   local saved_status = self.status
   if "running" == saved_status then
      return
   end
   self.last_sync = os.time()
   local real_path = hs.fs.pathToAbsolute(self.display_path)
   if nil == real_path then
      self.status = "error"
      self.message = "Not found"
      return
   end
   self.running = true
   self.message = "Running"
   -- do actual work
   print("will sync " .. real_path)
   print("using " .. self.git)
   -- status
   self.running = false
   if "stopped" == saved_status then
      self.status = "stopped"
      self.message = "Stopped"
   else
      self.status = "ok"
      self.message = nil
   end
end

function obj:display()
   local fmt = "%H:%M:%S %b %d"
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
   -- extra info
   if self.message then
      res_title = res_title .. ": " .. self.message
   end
   return {
      title = res_title,
      disabled = ("running" == self.status),
      fn = function()
         self:go()
      end
   }
end

return obj
