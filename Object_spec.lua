local Object = require("Object")
describe("creation", function()
	spec("can construct", function()
		assert.has_no.errors(function()
			Object()
			Object({})
			Object({
				_get_x = function()
					return 1
				end,
			})
		end)
	end)
	spec("can init", function()
		local can_init = false
		local init_class_property = false
		local test_object = Object({
			class_property = 1,
			_init = function(self)
				can_init = true
				init_class_property = self.class_property
				self.proxy_property = 2
			end,
		})
		assert.are.equal(true, can_init)
		assert.are.equal(test_object._class.class_property, init_class_property)
		assert.are.equal(2, test_object._proxy.proxy_property)
	end)
end)
describe("getters", function()
	spec("has Object properties", function()
		local test_object = Object()
		assert.are.equal("function", type(test_object.rawget))
		assert.are.equal("function", type(test_object.get))
		assert.are.equal("function", type(test_object.rawset))
		assert.are.equal("function", type(test_object.set))
	end)
	spec("has class properties", function()
		local test_object = Object({
			class_property = 1,
		})
		assert.are.equal(1, test_object.class_property)
	end)
	spec("prioritizes class over Object properties", function()
		local test_object = Object({
			publish = 2,
		})
		assert.are.equal(2, test_object.publish)
	end)
	spec("prioritizes instance over class properties", function()
		local test_object = Object({
			instance_default = 3,
		})
		test_object.instance_default = test_object.instance_default * -1
		assert.are.equal(-3, test_object.instance_default)
	end)
	spec("has custom getter", function()
		local test_object = Object({
			_get_x = function()
				return 4
			end,
		})
		assert.are.equal(4, test_object.x)
	end)
end)
describe("setters", function()
	spec("stores properties in proxy", function()
		local test_object = Object()
		test_object.x = 1
		assert.are.equal(1, test_object._proxy.x)
	end)
	spec("does not override class properties", function()
		local test_object = Object({
			class_property = 1,
		})
		test_object.class_property = test_object.class_property * -1
		assert.are.equal(-1, test_object.class_property)
		assert.are.equal(1, test_object._class.class_property)
	end)
	spec("has custom setter", function()
		local test_object = Object({
			_set_y = function(self, new_y)
				return self:rawset("y", new_y + 1)
			end,
		})
		test_object.y = 1
		assert.are.equal(2, test_object.y)
	end)
	spec("rawset does not publish", function()
		local published_change_event = false
		local test_object = Object({
			_on_change_x = function(self)
				published_change_event = true
			end,
		})
		test_object:rawset("x", 1)
		assert.are.equal(false, published_change_event)
	end)
	spec("can force rawset publish", function()
		local published_change_event = false
		local test_object = Object({
			_on_change_x = function(self)
				published_change_event = true
			end,
		})
		test_object:rawset("x", 1, true)
		assert.are.equal(true, published_change_event)
	end)
end)
describe("pubsub", function()
	spec("has change events", function()
		local published_override_change_event = false
		local published_new_key_change_event = false
		local published_existing_key_change_event = false
		local test_object = Object({
			class_key = 0,
		})
		test_object:subscribe("change_class_key", function()
			published_override_change_event = true
		end)
		test_object:subscribe("change_x", function()
			if not published_new_key_change_event then
				published_new_key_change_event = true
			else
				published_existing_key_change_event = true
			end
		end)
		test_object.class_key = 1
		test_object.x = 1
		test_object.x = 2
		assert.are.equal(true, published_override_change_event)
		assert.are.equal(true, published_new_key_change_event)
		assert.are.equal(true, published_existing_key_change_event)
	end)
	spec("has custom events", function()
		local published_custom_event = false
		local test_object = Object()
		test_object:subscribe("myevent", function()
			published_custom_event = true
		end)
		assert.are.equal(false, published_custom_event)
		test_object:publish("myevent")
		assert.are.equal(true, published_custom_event)
	end)
	spec("can pass custom event args", function()
		local event_arg_1, event_arg_2 = 0, 0
		local test_object = Object()
		test_object:subscribe("myevent", function(new_event_arg_1, new_event_arg_2)
			event_arg_1, event_arg_2 = new_event_arg_1, new_event_arg_2
		end)
		assert.are.equal(0, event_arg_1)
		assert.are.equal(0, event_arg_2)
		test_object:publish("myevent", 1, 2)
		assert.are.equal(1, event_arg_1)
		assert.are.equal(2, event_arg_2)
	end)
	spec("has native handlers", function()
		local published_native_handler = false
		local test_object = Object({
			_on_myevent = function(self)
				published_native_handler = true
			end,
		})
		assert.are.equal(false, published_native_handler)
		test_object:publish("myevent", 1, 2)
		assert.are.equal(true, published_native_handler)
	end)
	spec("can pass native handler args", function()
		local event_arg_1, event_arg_2 = 0, 0
		local test_object = Object()
		local test_object = Object({
			_on_myevent = function(self, new_event_arg_1, new_event_arg_2)
				event_arg_1, event_arg_2 = new_event_arg_1, new_event_arg_2
			end,
		})
		assert.are.equal(0, event_arg_1)
		assert.are.equal(0, event_arg_2)
		test_object:publish("myevent", 1, 2)
		assert.are.equal(1, event_arg_1)
		assert.are.equal(2, event_arg_2)
	end)
	spec("can mutate subscriptions while publishing", function()
		local test_object = Object()
		local called_f1 = 0
		local called_f2 = 0
		local called_f3 = 0
		local f1 = function()
			called_f1 = called_f1 + 1
		end
		function f2()
			called_f2 = called_f2 + 1
			test_object:unsubscribe("test", f2)
		end
		local f3 = function()
			called_f3 = called_f3 + 1
		end
		test_object:subscribe("test", f1)
		test_object:subscribe("test", f2)
		test_object:subscribe("test", f3)
		test_object:publish("test")
		assert.are.equal(1, called_f1)
		assert.are.equal(1, called_f2)
		assert.are.equal(1, called_f3)
		test_object:publish("test")
		assert.are.equal(2, called_f1)
		assert.are.equal(1, called_f2)
		assert.are.equal(2, called_f3)
	end)
	spec("can subscribe once", function()
		local test_object = Object()
		local counter = 0
		local increment = function()
			counter = counter + 1
		end
		test_object:once("test", increment)
		test_object:publish("test")
		assert.are.equal(1, counter)
		test_object:publish("test")
		assert.are.equal(1, counter)
	end)
end)
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
