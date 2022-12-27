# lua-object

Minimalistic approach to OOP by instantiating objects directly from user-defined classes. Works with Lua 5.1+ and LuaJIT.

Only `object.lua` is required. The source file (`object.erde`) is written in [Erde](https://erde-lang.github.io/) and compiled to Lua.

## Usage

The module returns a table, which can be called in order to create a new object:

```lua
local Object = require('object')
local myobject = Object()
```

You can optionally pass in a class, as well as varargs that will be proxied to the [class' constructor](#class_init) (if defined):

```lua
local Object = require('object')

local MyClass = {
  _init = function(self, a, b)
    print(a, b)
  end,
}

local myobject = Object(MyClass, "hello", "world") -- hello world
```

## API

- [`Class:_init(...)`](#class_init)
- [`Class:_get_XXX()`](#class_get_xxx)
- [`Class:_set_XXX(value)`](#class_set_xxxvalue)
- [`Class:_on_XXX(...)`](#class_on_xxx)
- [`Object:rawget(key)`](#objectrawgetkey)
- [`Object:rawset(key, value)`](#objectrawsetkey-value)
- [`Object:publish(event, ...)`](#objectpublishevent-)
- [`Object:subscribe(event, callback)`](#objectsubscribeevent-callback)
- [`Object:unsubscribe(event, callback)`](#objectunsubscribeevent-callback)

### `Class:_init(...)`

The class constructor. The arguments passed here are directly proxied from the `Object(class, ...)` call. Class defined [getters](#class_get_xxx) and [setters](#class_set_xxxvalue) are _not_ called and `change_XXX` events are _not_ emitted.

```lua
local Object = require('object')

local MyClass = {}
function MyClass:_init(a, b)
  self.sum = a + b
end

local myobject = Object(MyClass, 1, 2)
print(myobject.sum) -- 3
```

### `Class:_get_XXX()`

Class defined getter on property `XXX`. When defined, accessing `myobject.XXX` will return the result from the getter. You can use [`Object:rawget`](#objectrawgetkey) to bypass getters. Getters are _not_ called in [`Class:_init`](#class_init).

```lua
local Object = require('object')

local MyClass = {}
function MyClass:_get_myprop()
  return 42
end

local myobject = Object(MyClass)
print(myobject.myprop) -- 42
```

### `Class:_set_XXX(value)`

Class defined setter on property `XXX`. When defined, assigning `myobject.XXX = myvalue` will call the setter with `myvalue`. You can use [`Object:rawset`](#objectrawsetkey-value) to bypass setters. Setters are _not_ called in [`Class:_init`](#class_init). `change_XXX` events are _not_ automatically called after setters, but _are_ called in [`Object:rawset`](#objectrawsetkey-value).

```lua
local Object = require('object')

local MyClass = {}
function MyClass:_set_myprop(value)
  self:rawset('myprop', value + 10)
end

local myobject = Object(MyClass)
myobject.myprop = 42
print(myobject.myprop) -- 52
```

### `Class:_on_XXX(...)`

Class defined event handler. When defined, gets called whenever the event XXX is [published](#objectpublishevent-).

```lua
local Object = require('object')

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

Get the value indexed by `key` from the object _without_ invoking getters. First checks for `key` in the object, then searches for `key` in the class, and finally defaults to indexing `Object` directy.

```lua
local Object = require('object')

local MyClass = {}
function MyClass:_get_myprop(value)
  return 42
end

local myobject = Object(MyClass)
myobject.myprop = 24
print(myobject.myprop) -- 42
print(myobject:rawget('myprop')) -- 24
```

### `Object:rawset(key, value)`

Set the index of `key` to `value` _without_ invoking setters. Emits a `change_XXX` event (where XXX is the value of `key`) that passes the new value.

```lua
local Object = require('object')

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

### `Object:publish(event, ...)`

Invoke all [subscribers](#objectsubscribeevent-callback) of `event`, passing in the provided varargs to each subscription callback.

```lua
local Object = require('object')
local myobject = Object()

myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
```

### `Object:subscribe(event, callback)`

Add a callback to be called whenever `event` is [published](#objectpublishevent-). Returns the callback itself (useful for [unsubscribing](#objectunsubscribeevent-callback)).

```lua
local Object = require('object')
local myobject = Object()

myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
```

### `Object:unsubscribe(event, callback)`

Remove a callback from being called when `event` is [published](#objectpublishevent-).

```lua
local Object = require('object')
local myobject = Object()

local subscription = myobject:subscribe('myevent', function(a, b)
  print(a + b)
end)

myobject:publish('myevent', 1, 2) -- 3
myobject:unsubscribe('myevent', subscription)
myobject:publish('myevent', 1, 2) -- nothing prints!
```
