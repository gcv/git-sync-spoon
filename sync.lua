local obj = { name = "Sync" }
obj.__index = obj

function obj.new(display_path, real_path, interval)
   local self = { display_path = display_path, real_path = real_path, interval = interval }
   setmetatable(self, obj)
   return self
end

function obj:start()
end

function obj:stop()
end

function obj:go()
   print("will sync " .. self.real_path)
   print("using " .. self.git)
end

return obj
