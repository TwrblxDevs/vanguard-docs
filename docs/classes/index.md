# Classes

Vanguard provides a lightweight class utility plus independent server and client class registries. Classes support constructors, inheritance, callable class tables, inherited methods and metamethods, and runtime type checks.

## Create and Register a Class

```lua
local Entity = Vanguard.CreateClass({
	Name = "Entity",

	Constructor = function(self, id)
		self.Id = id
	end,
})

function Entity:GetId()
	return self.Id
end
```

`Vanguard.CreateClass` creates and immediately registers the class in the current runtime.

Instantiate with `.new` or by calling the class:

```lua
local first = Entity.new("entity-1")
local second = Entity("entity-2")
```

Both forms are equivalent.

## Definition Fields

| Field | Required | Description |
| --- | --- | --- |
| `Name` | Yes | Non-empty class and registry name |
| `Extends` | No | Parent Vanguard class; main API also accepts a registered class name |
| `Constructor` | No | Called for every new instance |

All other fields are copied onto the class. Define instance methods in the definition or assign them afterward.

Class definitions may not define `new`; use `Constructor` instead. Vanguard reserves `Extends`, `Extend`, `IsA`, `Super`, `new`, `__index`, and `__vanguardClass`.

## Inheritance

```lua
local PlayerEntity = Vanguard.CreateClass({
	Name = "PlayerEntity",
	Extends = Entity,

	Constructor = function(self, _id, player)
		self.Player = player
	end,
})
```

Or extend from the parent:

```lua
local PlayerEntity = Entity:Extend({
	Name = "PlayerEntity",
	Constructor = function(self, _id, player)
		self.Player = player
	end,
})

Vanguard.RegisterClass(PlayerEntity)
```

`Class:Extend` creates a class but does not automatically register it. Register explicitly when registry lookup is needed.

## Constructor Order

Every constructor in the inheritance chain runs base-first. Every constructor receives the same argument list.

```lua
local playerEntity = PlayerEntity("entity-1", player)
```

Call order:

```text
Entity.Constructor(instance, "entity-1", player)
PlayerEntity.Constructor(instance, "entity-1", player)
```

Do not manually call the base constructor; Vanguard already does it.

If a constructor throws, instance creation throws and no instance is returned. Constructors do not have automatic cleanup, so avoid acquiring resources before validation that may fail.

## Method and Static Inheritance

Instances resolve methods through the child class, then parent classes.

```lua
print(playerEntity:GetId())
```

Class table reads also inherit static values through the parent class metatable.

Metamethods directly defined on a parent are copied into child classes when the child does not define its own. `__index`, `__metatable`, and Vanguard's internal marker are not copied.

## Runtime Checks

Instance method:

```lua
playerEntity:IsA(PlayerEntity) -- true
playerEntity:IsA(Entity) -- true
playerEntity:IsA("Entity") -- true
```

Utility checks:

```lua
local Class = require(Vanguard.Util.Class)

Class.isClass(Entity) -- true
Class.isInstance(playerEntity) -- true
Class.isInstance(playerEntity, Entity) -- true
Class.isA(PlayerEntity, Entity) -- true
Class.getClass(playerEntity) == PlayerEntity -- true
```

String checks compare class names across the inheritance chain. Class-object checks are stronger when you already hold the expected class.

## Registry API

### CreateClass

```lua
local class = Vanguard.CreateClass(definition)
```

Creates and registers. If `Extends` is a string, the named parent must already be registered.

### RegisterClass

```lua
local Class = require(Vanguard.Util.Class)
local Item = Class.create({ Name = "Item" })
Vanguard.RegisterClass(Item)
```

Registering the same class object again is idempotent. Registering a different class with the same name errors.

### GetClass and HasClass

```lua
local Item = Vanguard.GetClass("Item")
if Vanguard.HasClass("Item") then
	-- Registered.
end
```

`GetClass` errors when missing. `HasClass` returns a boolean.

### GetClasses

```lua
local classes = Vanguard.GetClasses()
```

Returns a shallow clone of the registry.

### UnregisterClass

```lua
local removed = Vanguard.UnregisterClass("Item")
```

Returns the removed class or nil. Existing instances continue working; unregistering only removes discovery by name.

## Loading Class Modules

```lua
Vanguard.AddClasses(folder)
Vanguard.AddClassesDeep(folder)
```

`LoadClasses` and `LoadClassesDeep` are aliases.

Modules may return:

- a class already made with `Vanguard.CreateClass`;
- a class made with `Vanguard.Util.Class.create`; or
- a plain class definition.

Plain definitions are passed to `Vanguard.CreateClass` automatically.

## Bootstrap

```lua
Vanguard.Bootstrap({
	Classes = script.Parent.Classes,
	Services = script.Parent.Services,
})
```

Class folders load before service or controller folders. This allows those modules to call `GetClass` while they are being required.

## Runtime Scope

Server and client registries are separate. Register a shared class on both runtimes when both need name-based discovery. Requiring the same shared class module separately on server and client produces runtime-local class objects.

Classes have no Vanguard lifecycle and may be registered or unregistered after startup.

## Class Utility Without the Registry

```lua
local Class = require(Vanguard.Util.Class)

local Temporary = Class.create({
	Name = "Temporary",
})
```

Use the utility directly for private classes that do not need global discovery. Use the Vanguard registry for shared framework-level concepts, factories, or classes referenced by name.
