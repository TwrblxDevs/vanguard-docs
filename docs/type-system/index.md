# Type System

Vanguard exports Luau types from its main module and from each utility module. This guide shows reliable autocomplete patterns for services, controllers, remotes, classes, and utility objects.

## Preserve the Main Module Type

Preferred:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)
```

The direct path lets Studio resolve the ModuleScript and exported types.

When using `WaitForChild`, cast the required module:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Vanguard = require(Packages:WaitForChild("Vanguard") :: ModuleScript)
	:: typeof(require(ReplicatedStorage.Packages.Vanguard))
```

Without the cast, `WaitForChild` returns generic `Instance`, which can degrade autocomplete or produce `*error-type*`.

## Main Exported Types

```lua
type VanguardType = Vanguard.Vanguard
type StartOptions = Vanguard.StartOptions

type Service = Vanguard.Service
type ServiceDefinition = Vanguard.ServiceDefinition
type Controller = Vanguard.Controller
type ControllerDefinition = Vanguard.ControllerDefinition
type Component = Vanguard.Component
type ComponentDefinition = Vanguard.ComponentDefinition
type ComponentInstance = Vanguard.ComponentInstance

type Class = Vanguard.Class
type ClassDefinition = Vanguard.ClassDefinition
type Cache = Vanguard.Cache
type Cleaner = Vanguard.Cleaner
type Logger = Vanguard.Logger
type Promise = Vanguard.Promise
type RateLimiter = Vanguard.RateLimiter
type Signal = Vanguard.Signal

type RemoteSignal = Vanguard.RemoteSignal
type RemoteProperty = Vanguard.RemoteProperty

type NetworkContext = Vanguard.NetworkContext
type NetworkInfo = Vanguard.NetworkInfo
type NetworkOptions = Vanguard.NetworkOptions
type NetworkRejection = Vanguard.NetworkRejection
type NetworkRule = Vanguard.NetworkRule
type NetworkStats = Vanguard.NetworkStats
type Validator = Vanguard.Validator
```

## Strongly-Typed Services

Intersect your own API with the Vanguard base type:

```lua
type InventoryService = Vanguard.Service & {
	Client: {
		Changed: Vanguard.RemoteSignal,
		State: Vanguard.RemoteProperty,
		GetItems: (self: any, player: Player) -> { string },
	},

	ItemsByPlayer: { [Player]: { string } },
	GetItems: (self: InventoryService, player: Player) -> { string },
}

local InventoryService: InventoryService = Vanguard.CreateService({
	Name = "InventoryService",
	Client = {
		Changed = Vanguard.CreateSignal(),
		State = Vanguard.CreateProperty("Loading"),
	},
}) :: any
```

The final cast may be necessary while constructing a table incrementally because generated remote markers become runtime remote objects only during startup.

## ServiceWith and ControllerWith

Vanguard provides convenience intersections:

```lua
type InventoryService = Vanguard.ServiceWith<{
	ItemsByPlayer: { [Player]: { string } },
}>

type HUDController = Vanguard.ControllerWith<{
	Visible: boolean,
}>
```

These are equivalent to intersecting the base definitions manually.

## Client Service Proxies

Server `Client` function signatures include `player`; client calls do not:

```lua
-- Server definition shape
GetItems: (self: any, player: Player) -> { string }

-- Client proxy shape in promise mode
GetItems: (self: any) -> Vanguard.Promise
```

The framework cannot automatically export a service-specific proxy type across separate server and client modules. Define a shared client-facing type when stronger client autocomplete is needed:

```lua
export type InventoryClient = {
	GetItems: (self: InventoryClient) -> Vanguard.Promise,
	Changed: Vanguard.RemoteSignal,
	State: Vanguard.RemoteProperty,
}
```

Then cast lookup:

```lua
local InventoryService = Vanguard.GetService("InventoryService") :: InventoryClient
```

## Remote Union Types

`Vanguard.RemoteSignal` describes the shared server/client surface. Server-only methods such as `FireAll` are optional because the main module type is shared between runtimes.

For precise runtime types, require the utility module and use its exports:

```lua
local RemoteSignal = require(Vanguard.Util.RemoteSignal)
type ServerRemoteSignal = RemoteSignal.ServerRemoteSignal
type ClientRemoteSignal = RemoteSignal.ClientRemoteSignal
```

Likewise for remote properties:

```lua
local RemoteProperty = require(Vanguard.Util.RemoteProperty)
type ServerRemoteProperty = RemoteProperty.ServerRemoteProperty
type ClientRemoteProperty = RemoteProperty.ClientRemoteProperty
```

## Utility Types

Every utility module exports its own detailed types:

```lua
local Cache = require(Vanguard.Util.Cache)
local Class = require(Vanguard.Util.Class)
local Cleaner = require(Vanguard.Util.Cleaner)
local NetworkGuard = require(Vanguard.Util.NetworkGuard)
local Promise = require(Vanguard.Util.Promise)
local RateLimiter = require(Vanguard.Util.RateLimiter)
local Validator = require(Vanguard.Util.Validator)

type CacheOptions = Cache.Options
type ClassDefinition = Class.Definition
type Cleaner = Cleaner.Cleaner
type GuardRule = NetworkGuard.Rule
type Promise = Promise.Promise
type RateLimiterOptions = RateLimiter.Options
type ValidatorFunction = Validator.Validator
```

Use utility-module types when you need fields more specific than the shared main export.

## Typed Classes

Class construction is dynamic. Define an instance shape and cast instances at the boundary:

```lua
type Entity = {
	Id: string,
	GetId: (self: Entity) -> string,
	IsA: (self: Entity, expected: Vanguard.Class | string) -> boolean,
}

local EntityClass = Vanguard.CreateClass({
	Name = "Entity",
	Constructor = function(self, id: string)
		self.Id = id
	end,
	GetId = function(self)
		return self.Id
	end,
})

local entity = EntityClass("entity-1") :: Entity
```

## Typed Validators

Validators prove runtime shape but do not currently narrow Luau types automatically:

```lua
local valid, message = itemValidator(value)
if not valid then
	return false, message
end

local item = value :: {
	Id: string,
	Count: number,
}
```

Keep the runtime schema and static type near one another to reduce drift.

## Network Callback Types

```lua
local function authenticate(player: Player, context: Vanguard.NetworkContext): (boolean, string?)
	return true
end

local function onRejected(context: Vanguard.NetworkContext, rejection: Vanguard.NetworkRejection)
	print(context.RemoteName, rejection.Code)
end
```

## Promise Result Types

The bundled Promise type is intentionally broad because promises may carry multiple values:

```lua
local ok, value = promise:await()
```

For application-specific promises, document the resolved value at the producing method and cast after resolution when needed.

## Type Caveats

- Runtime class inheritance is more dynamic than Luau's structural type system.
- Remote markers change into runtime objects during server startup.
- The main `Vanguard` type covers both server and client, so runtime-specific methods may be optional.
- `GetService` and `GetController` return broad values because names are dynamic.
- `GetConfig` is typed as `StartOptions`, but its nested tables should be treated as read-only references.
