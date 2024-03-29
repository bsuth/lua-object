local unpack = unpack or table.unpack
local ObjectMT = {}
local Object = setmetatable({}, ObjectMT)
function Object:rawget(key)
	local proxy_value = self._proxy[key]
	if proxy_value ~= nil then
		return proxy_value
	end
	local class_value = self._class[key]
	if class_value ~= nil then
		return class_value
	end
	return Object[key]
end
function Object:get(key)
	local getter = self._class[("_get_" .. tostring(key))]
	if type(getter) == "function" then
		return getter(self)
	else
		return Object.rawget(self, key)
	end
end
function Object:rawset(key, value, publish)
	local old_value = Object.rawget(self, key)
	self._proxy[key] = value
	if publish and old_value ~= value then
		Object.publish(self, ("change_" .. tostring(key)), value, old_value)
	end
end
function Object:set(key, value)
	local setter = self._class[("_set_" .. tostring(key))]
	if type(setter) == "function" then
		setter(self, value)
	else
		Object.rawset(self, key, value, true)
	end
end
function Object:publish(event, ...)
	local native_handler = self._class[("_on_" .. tostring(event))]
	if type(native_handler) == "function" then
		native_handler(self, ...)
	end
	if self._subscriptions[event] then
		for _, subscription in ipairs({
			unpack(self._subscriptions[event]),
		}) do
			subscription(...)
		end
	end
end
function Object:subscribe(event, callback)
	self._subscriptions[event] = self._subscriptions[event] or {}
	for _, subscription in ipairs(self._subscriptions[event]) do
		if subscription == callback then
			return callback
		end
	end
	table.insert(self._subscriptions[event], callback)
	return callback
end
function Object:unsubscribe(event, callback)
	if self._subscriptions[event] then
		for i, subscription in ipairs(self._subscriptions[event]) do
			if subscription == callback then
				table.remove(self._subscriptions[event], i)
				break
			end
		end
	end
end
function Object:once(event, callback)
	local function callback_wrapper(...)
		callback(...)
		self:unsubscribe(event, callback_wrapper)
	end
	self:subscribe(event, callback_wrapper)
	return callback_wrapper
end
local InstanceMT = {
	__index = Object.get,
	__newindex = Object.set,
}
function ObjectMT:__call(class, ...)
	if class == nil then
		class = {}
	end
	local instance = setmetatable({
		_class = class,
		_proxy = {},
		_subscriptions = {},
	}, InstanceMT)
	if type(class._init) == "function" then
		class._init(instance, ...)
	end
	return instance
end
return Object
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
