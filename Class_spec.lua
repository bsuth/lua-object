local Class = require("Class")
spec("can construct", function()
	assert.has_no.errors(function()
		Class()
		Class({})
	end)
end)
spec("can pass instance", function()
	assert.are.equal(nil, Class().mycustomkey)
	assert.are.equal(
		1,
		Class({
			mycustomkey = 1,
		}).mycustomkey
	)
end)
spec("can construct object", function()
	local can_init = false
	local init_class_property = false
	local TestClass = Class({
		class_property = 1,
		_init = function(self)
			can_init = true
			init_class_property = self.class_property
			self.proxy_property = 2
		end,
	})
	assert.are.equal(false, can_init)
	local test_object = TestClass()
	assert.are.equal(true, can_init)
	assert.are.equal(test_object._class.class_property, init_class_property)
	assert.are.equal(2, test_object._proxy.proxy_property)
end)
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
