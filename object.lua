local
ObjectMT
=
{
}
local
Object
=
setmetatable(
{
}
,
ObjectMT
)
function
ObjectMT:__call
(class,...)
if class == nil then class = 
{
}
end
local
instance
=
{
_class
=
class
,
_proxy
=
{
}
,
_subscriptions
=
{
}
,
}
if
type(
class
._init
)
==
'function'
then
setmetatable(
instance
,
{
__index
=
Object
.rawget
,
__newindex
=
instance
._proxy
,
}
)
class
._init(
instance
,
...
)
end
setmetatable(
instance
,
{
__index
=
Object
.get
,
__newindex
=
Object
.set
,
}
)
return
instance
end
function
Object:rawget
(key)
local
proxyValue
=
self
._proxy
[
key
]
if
proxyValue
~=
nil
then
return
proxyValue
end
local
classValue
=
self
._class
[
key
]
if
classValue
~=
nil
then
return
classValue
end
return
Object
[
key
]
end
function
Object:get
(key)
local
getter
=
self
._class
[
"_get_"
..
tostring(
key
)
]
if
type(
getter
)
==
'function'
then
return
getter(
self
)
else
return
Object
.rawget(
self
,
key
)
end
end
function
Object:rawset
(key,value)
local
changed
=
Object
.rawget(
self
,
key
)
~=
value
self
._proxy
[
key
]
=
value
if
changed
then
Object
.publish(
self
,
"change_"
..
tostring(
key
)
,
value
)
end
end
function
Object:set
(key,value)
local
setter
=
self
._class
[
"_set_"
..
tostring(
key
)
]
if
type(
setter
)
==
'function'
then
setter(
self
,
value
)
else
Object
.rawset(
self
,
key
,
value
)
end
end
function
Object:publish
(event,...)
local
native_handler
=
self
._class
[
"_on_"
..
tostring(
event
)
]
if
type(
native_handler
)
==
'function'
then
native_handler(
self
,
...
)
end
if
self
._subscriptions
[
event
]
then
for
_
,
subscription
in
ipairs(
self
._subscriptions
[
event
]
)
do
subscription(
...
)
end
end
end
function
Object:subscribe
(event,callback)
self
._subscriptions
[
event
]
=
self
._subscriptions
[
event
]
or
{
}
for
_
,
subscription
in
ipairs(
self
._subscriptions
[
event
]
)
do
if
subscription
==
callback
then
return
callback
end
end
table
.insert(
self
._subscriptions
[
event
]
,
callback
)
return
callback
end
function
Object:unsubscribe
(event,callback)
if
self
._subscriptions
[
event
]
then
for
i
,
subscription
in
ipairs(
self
._subscriptions
[
event
]
)
do
if
subscription
==
callback
then
table
.remove(
self
._subscriptions
[
event
]
,
i
)
break
end
end
end
end
return
Object
-- __ERDE_COMPILED__