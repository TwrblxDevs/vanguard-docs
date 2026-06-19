# Controllers

Controllers are named client-side systems. They coordinate UI, input, presentation, and calls to server service proxies.

## Definition

```lua
local InventoryController = Vanguard.CreateController({
	Name = "InventoryController",
})
```

Recognized fields:

| Field | Required | Description |
| --- | --- | --- |
| `Name` | Yes | Non-empty unique controller name |
| `Logger` | No | Custom logger; Vanguard creates one when omitted |

Controllers do not have service priority. Their init hooks run concurrently.

## Lifecycle

```lua
function InventoryController:VanguardInit()
	self.Items = {}
end

function InventoryController:VanguardStart()
	self.InventoryService = Vanguard.GetService("InventoryService")
	self:LoadItems()
end
```

All controller init hooks must complete before start hooks are scheduled. Start hooks are not awaited.

`KnitInit` and `KnitStart` remain supported as migration aliases.

## Calling Services

```lua
function InventoryController:LoadItems()
	self.InventoryService:GetItems():andThen(function(items)
		self.Items = items
	end):catch(function(err)
		self.Logger:Warn(`Could not load inventory: {err}`)
	end)
end
```

With the default `ServicePromises = true`, every remote function returns a Vanguard Promise.

With `ServicePromises = false`, the call yields and returns directly:

```lua
local items = self.InventoryService:GetItems()
```

Promise mode is recommended because it makes network failures explicit and keeps yielding behavior visible at the call site.

## Listening to Remote Signals

```lua
function InventoryController:VanguardStart()
	local InventoryService = Vanguard.GetService("InventoryService")

	InventoryService.InventoryChanged:Connect(function(items)
		self.Items = items
	end)
end
```

On the client, remote signal callbacks receive only server-sent payload values. The `Player` argument exists only for server callbacks receiving client events.

## Reading Remote Properties

```lua
local currentState = MatchService.State:Get()

local subscription = MatchService.State:Observe(function(state)
	self.State = state
end)
```

`Observe` immediately fetches the current value asynchronously, then reports later updates. Disconnect it during controller teardown when your controller implements its own teardown lifecycle.

## Automatic Registration

Controller modules loaded by Vanguard may return either:

- an object already created with `CreateController`; or
- a plain table with a valid `Name`.

```lua
return {
	Name = "CameraController",
	VanguardStart = function(self)
		self.Logger:Info("Ready")
	end,
}
```

## Loading Controllers

```lua
Vanguard.AddControllers(controllersFolder)
Vanguard.AddControllersDeep(controllersFolder)
```

`LoadControllers` and `LoadControllersDeep` are aliases.

The shallow form requires direct ModuleScript children. The deep form walks all descendants. Modules are processed in full-path order.

Failed modules are logged and skipped without preventing other modules from loading.

Controllers must be loaded before `Start`.

## Controller Lookup

```lua
local HUDController = Vanguard.GetController("HUDController")
local controllers = Vanguard.GetControllers()
```

An already-registered controller can be retrieved before startup. Unknown controller lookup requires startup and then produces an error listing known controllers.

`GetControllers` requires startup to have begun. The returned registry is frozen by default during startup when `FreezeControllers = true`.

## Service Proxy Lookup

```lua
local service = Vanguard.GetService("InventoryService")
```

Client `GetService` requires `Start` to have been called. The first lookup waits for the server's remote folder, verifies Vanguard's network protocol, builds a proxy, and caches it. Later lookups return that same proxy.

If no server service folder with that name appears within `RemoteTimeout`, lookup errors.

## Logging

Controllers receive a logger scoped to their name:

```lua
self.Logger:Debug("Selected slot", slot)
```

## Creation Rules

- Names must be non-empty strings.
- Names must be unique in the client runtime.
- controllers cannot be created after `Start` begins.
- controller init errors reject startup.
- controller start errors occur in spawned runtime tasks and do not roll startup back.

## Design Guidance

- Keep server authority in services, never controllers.
- Put UI and input state in controllers.
- Keep remote calls behind controller methods when multiple UI elements use them.
- Store remote connections in a [Cleaner](../utilities/cleaner/index.md) when the controller has a custom teardown path.
- Use components for repeated behavior attached to tagged Instances.
