# Services

Services are named server-side systems. They own authoritative game state, expose selected remotes through `Client`, and participate in server lifecycle ordering.

## Definition

```lua
local InventoryService = Vanguard.CreateService({
	Name = "InventoryService",
	Priority = 20,
	Client = {},
})
```

Required and recognized fields:

| Field | Required | Description |
| --- | --- | --- |
| `Name` | Yes | Non-empty unique service name |
| `Client` | No | Client-facing remote definitions; defaults to an empty table |
| `Priority` | No | Numeric init/start ordering value; defaults to `0` |
| `Network` | No | Validation, authentication, verification, and rate-limit rules |
| `Logger` | No | Custom logger; Vanguard creates one when omitted |

All other fields and methods belong to your service.

## Defining Server Methods

```lua
function InventoryService:GetItems(player)
	return self.ItemsByPlayer[player] or {}
end
```

Server methods are ordinary Lua methods. They are not remotely callable unless a corresponding function exists in `Client`.

## Exposing Remote Methods

Define client-facing functions inside `Client`:

```lua
function InventoryService.Client:GetItems(player)
	return self.Server:GetItems(player)
end
```

At invocation time:

- Roblox supplies `player`; clients cannot choose that argument.
- `self` is a temporary client-call context.
- `self.Server` points to the owning service.
- other `self` lookups read from the service's `Client` table.

`Client.Server` is not stored as a circular table field. It exists only through the call context.

Do not trust client arguments. Apply [Network Security](../network-security/index.md) rules and re-check authoritative state in server methods.

## Signals and Properties

```lua
local MatchService = Vanguard.CreateService({
	Name = "MatchService",
	Client = {
		MatchStarted = Vanguard.CreateSignal(),
		AimUpdated = Vanguard.CreateUnreliableSignal(),
		State = Vanguard.CreateProperty("Waiting"),
	},
})
```

Vanguard replaces these markers with server remote objects during startup.

```lua
function MatchService:VanguardStart()
	self.Client.MatchStarted:FireAll({ Map = "Arena" })
	self.Client.State:Set("Running")

	self.Client.AimUpdated:Connect(function(player, direction)
		-- Already passed configured network guards.
	end)
end
```

See [Networking](../networking/index.md) for every method.

## Lifecycle and Priority

```lua
function InventoryService:VanguardInit()
	self.ItemsByPlayer = {}
end

function InventoryService:VanguardStart()
	self.Logger:Info("Ready")
end
```

Higher priorities initialize first. Services with equal priority initialize concurrently. Start hooks are scheduled after all init hooks complete and are not awaited.

Read [Lifecycle](../lifecycle/index.md) for the exact guarantees.

## Automatic Registration

A service module may return a plain table:

```lua
return {
	Name = "AnalyticsService",
	Client = {},
	VanguardStart = function(self)
		self.Logger:Info("Ready")
	end,
}
```

When loaded through `AddServices` or `AddServicesDeep`, Vanguard automatically passes a valid plain definition to `CreateService`.

Calling `CreateService` inside the module is also valid. The loader recognizes that the returned object is already registered and does not register it twice.

## Loading Services

```lua
Vanguard.AddServices(servicesFolder) -- Direct ModuleScript children only
Vanguard.AddServicesDeep(servicesFolder) -- All descendant ModuleScripts
```

`LoadServices` and `LoadServicesDeep` are aliases.

Return value:

```lua
local loaded = Vanguard.AddServicesDeep(servicesFolder)
```

The array contains successfully-required values. A module that fails to require or register is logged and skipped; other modules continue loading.

Services must be loaded before `Start`.

## Looking Up Services on the Server

```lua
local InventoryService = Vanguard.GetService("InventoryService")
local services = Vanguard.GetServices()
```

Server `GetService` requires startup to have begun. During init, all registered services are available. Unknown names produce an error listing registered services.

`GetServices` returns the registry table. With the default `FreezeServices = true`, that table is frozen during startup.

## Looking Up Services on the Client

Client `GetService` creates or returns a remote proxy:

```lua
local InventoryService = Vanguard.GetService("InventoryService")
InventoryService:GetItems():andThen(print)
```

Only `Client` members exist on the proxy. Server-only methods and fields are never replicated.

## Logging

Services without a custom `Logger` receive a scoped logger named after the service:

```lua
self.Logger:Info("Loaded", count, "items")
```

## Creation Rules

- Names must be non-empty strings.
- Names must be unique within the server runtime.
- `Priority`, when present, must be a number.
- `Network`, when present, must be a table.
- services cannot be created after `Start` begins.
- unsupported values inside `Client` fail remote construction.

## Recommended Boundaries

- Put authoritative data mutation in server methods.
- Keep remote wrappers small.
- Validate shape at the network boundary.
- Authenticate sessions before protected requests.
- Verify ownership and permissions against server state.
- Use signals for notifications, not request/response work.
- Use properties for current server-owned state, not unbounded event history.
