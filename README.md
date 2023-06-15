# lua-object

Minimalistic approach to OOP by instantiating objects directly from user-defined
classes. Works with Lua 5.1+ and LuaJIT.

Only `Object.lua` is required. The source file (`Object.erde`) is written in
[Erde](https://erde-lang.github.io/) and compiled to Lua.

## Usage

The module returns a table, which can be called in order to create a new object:

```lua
local Object = require('Object')
local myobject = Object()
```

You can optionally pass in a user-defined class, as well as varargs that will be
proxied to the [constructor](#myclass_init) (if defined):

```lua
local Object = require('Object')

local MyClass = {
  _init = function(self, a, b)
    print(a, b)
  end,
}

local myobject = Object(MyClass, "hello", "world") -- hello world
```

## API

- [`MyClass:_init(...)`](#myclass_init)
- [`MyClass:_get_XXX()`](#myclass_get_xxx)
- [`MyClass:_set_XXX(value)`](#myclass_set_xxxvalue)
- [`MyClass:_on_XXX(...)`](#myclass_on_xxx)
- [`Object:rawget(key)`](#objectrawgetkey)
- [`Object:get(key)`](#objectgetkey)
- [`Object:rawset(key, value, publish)`](#objectrawsetkey-value-publish)
- [`Object:set(key, value)`](#objectsetkey-value)
- [`Object:publish(event, ...)`](#objectpublishevent-)
- [`Object:subscribe(event, callback)`](#objectsubscribeevent-callback)
- [`Object:unsubscribe(event, callback)`](#objectunsubscribeevent-callback)
- [`Object:once(event, callback)`](#objectonceevent-callback)

### `MyClass:_init(...)`

The class constructor. The arguments passed here are directly proxied from the
`Object(class, ...)` call.

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_init(a, b)
  self.sum = a + b
end

local myobject = Object(MyClass, 1, 2)
print(myobject.sum) -- 3
```

### `MyClass:_get_XXX()`

Class defined getter on property `XXX`. When defined, accessing `myobject.XXX`
will return the result from the getter. You can use [`Object:rawget`](#objectrawgetkey) to bypass getters.

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_get_myprop()
  return 42
end

local myobject = Object(MyClass)
print(myobject.myprop) -- 42
```

### `MyClass:_set_XXX(value)`

Class defined setter on property `XXX`. When defined, assigning
`myobject.XXX = myvalue` will call the setter with `myvalue`. You can use
[`Object:rawset`](#objectrawsetkey-value-publish) to bypass setters. `change_XXX` events
are _not_ automatically published after custom setters and must be published manually.

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_set_myprop(value)
  self:rawset('myprop', value + 10)
end

local myobject = Object(MyClass)
myobject.myprop = 42
print(myobject.myprop) -- 52
```

### `MyClass:_on_XXX(...)`

Class defined event handler. When defined, gets called whenever the event XXX is
[published](#objectpublishevent-).

```lua
local Object = require('Object')

local MyClass = {}

function MyClass:_on_change_myprop(value)
  print('myprop has changed to: ' .. tostring(value))
end

function MyClass:_on_myevent()
  print('emitted myevent')
end

local myobject = Object(MyClass)
myobject.myprop = 42 -- myprop has changed to: 42
myobject:publish('myevent') -- emitted myevent
```

### `Object:rawget(key)`

Gets the value indexed by `key` from the object _without_ invoking getters. First
checks for `key` in the object, then searches for `key` in the class, and
finally defaults to indexing `Object` directy.

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_get_myprop(value)
  return 42
end

local myobject = Object(MyClass)
myobject.myprop = 24
print(myobject.myprop) -- 42
print(myobject:rawget('myprop')) -- 24
```

### `Object:get(key)`

The getter function for the object. Calling this is equivalent to simply accessing the key directly.

```lua
local Object = require('Object')
local myobject = Object()

-- equivalent
print(myobject.mykey)
print(myobject:get('mykey'))
```

### `Object:rawset(key, value, publish)`

Sets the index of `key` to `value` _without_ invoking setters. If `publish` is
set to true, publishes a `change_XXX` event (where XXX is the value of `key`)
that passes the new and old values.

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_set_myprop(value)
  self:rawset('myprop', value + 10)
end

local myobject = Object(MyClass)
myobject.myprop = 42
print(myobject.myprop) -- 52
myobject:rawset('myprop', 42)
print(myobject.myprop) -- 42
```

```lua
local Object = require('Object')

local MyClass = {}
function MyClass:_on_change_myprop(new_value, old_value)
  print(new_value, old_value)
end

local myobject = Object(MyClass)
myobject:rawset('myprop', 42, true) -- 42 nil
myobject:rawset('myprop', 24, true) -- 24 42
```

### `Object:set(key, value)`

The setter function for the object. Calling this is equivalent to simply assigning the key directly.

```lua
local Object = require('Object')
local myobject = Object()

-- equivalent
myobject.mykey = 42
myobject:set('mykey', 42)
```

### `Object:publish(event, ...)`

Invokes all [subscribers](#objectsubscribeevent-callback) of `event`, passing in
the provided varargs to each subscription callback.

```lua
local Object = require('Object')
local myobject = Object()

myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
```

### `Object:subscribe(event, callback)`

Adds a callback to be called whenever `event` is [published](#objectpublishevent-).
Returns the callback itself (useful for [unsubscribing](#objectunsubscribeevent-callback)).
The same function cannot be subscribed to the same event multiple times (no duplicate subscriptions).

```lua
local Object = require('Object')
local myobject = Object()

myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
```

### `Object:unsubscribe(event, callback)`

Removes a callback from being called when `event` is [published](#objectpublishevent-).

```lua
local Object = require('Object')
local myobject = Object()

local subscription = myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
myobject:unsubscribe('myevent', subscription)
myobject:publish('myevent', 1, 2) -- nothing prints!
```

### `Object:once(event, callback)`

Adds a callback to be called the next time `event` is [published](#objectpublishevent-).
This callback only fires once and then immediately unsubscribes itself. Similarly to
[Object:subscribe](#objectsubscribeevent-callback), this returns the subscribed function
and can be removed via [Object:unsubscribe](#objectunsubscribeevent-callback) (note that
the subscribed function is _not_ the same as `callback`). Unlike
[Object:subscribe](#objectsubscribeevent-callback), the same callback may be registered
multiple times.

```lua
local Object = require('Object')
local myobject = Object()

local subscription = myobject:once('myevent', function()
  print('hello world')
end)

myobject:publish('myevent') -- hello world
myobject:publish('myevent') -- nil
```

## Class.lua

This repo also contains a `Class.lua` helper, which is simply a light wrapper
that allows calling user-defined classes directly to instantiate a corresponding
Object. Note that this requires overriding the metatable for the class:

```lua
local Class = require('Class')

local MyClass = Class()

function MyClass:_init(a, b)
  self.sum = a + b
end

-- equivalent to Object(MyClass, 1, 2)
local myobject = MyClass(1, 2)
```

You can also pass the class definition directly to `Class`:

```lua
local Class = require('Class')

local MyClass = Class({
  _init = function(self, a, b)
    self.sum = a + b
  end
})
```
