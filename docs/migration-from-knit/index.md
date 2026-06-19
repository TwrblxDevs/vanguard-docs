# Migrating from Knit

Vanguard intentionally follows familiar Knit concepts while remaining dependency-free and adding components, class registries, scoped logging, configuration, caching, and server network guards.

This guide focuses on migration behavior rather than general Knit usage.

## API Mapping

| Knit concept | Vanguard equivalent |
| --- | --- |
| `Knit.CreateService` | `Vanguard.CreateService` |
| `Knit.CreateController` | `Vanguard.CreateController` |
| `Knit.AddServices` | `Vanguard.AddServices` |
| `Knit.AddServicesDeep` | `Vanguard.AddServicesDeep` |
| `Knit.AddControllers` | `Vanguard.AddControllers` |
| `Knit.AddControllersDeep` | `Vanguard.AddControllersDeep` |
| `Knit.GetService` | `Vanguard.GetService` |
| `Knit.GetController` | `Vanguard.GetController` |
| `Knit.Start` | `Vanguard.Start` or `Vanguard.Bootstrap` |
| `Knit.OnStart` | `Vanguard.OnStart` |
| `KnitInit` | `VanguardInit` preferred; alias supported |
| `KnitStart` | `VanguardStart` preferred; alias supported |

## Incremental Hook Migration

Existing hook names work:

```lua
function Service:KnitInit()
	-- Supported.
end

function Service:KnitStart()
	-- Supported.
end
```

Rename when convenient:

```lua
function Service:VanguardInit()
end

function Service:VanguardStart()
end
```

When both names exist for the same phase, Vanguard selects `VanguardInit`/`VanguardStart` first.

## Service Migration

Typical change:

```lua
-- Before
local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {},
})

-- After
local InventoryService = Vanguard.CreateService({
	Name = "InventoryService",
	Client = {},
})
```

Client method context remains familiar:

```lua
function InventoryService.Client:GetItems(player)
	return self.Server:GetItems(player)
end
```

Vanguard provides `self.Server` only through the active remote call context and does not store a circular `Client.Server` field.

## Controller Migration

```lua
local InventoryController = Vanguard.CreateController({
	Name = "InventoryController",
})
```

Client `GetService` returns a Vanguard proxy. Remote methods return bundled Vanguard promises by default.

Audit promise APIs if existing code relies on methods beyond:

- `andThen`;
- `catch`;
- `finally`;
- `await`.

The bundled Promise is intentionally small and has no cancellation, timeout, race, or retry helpers.

## Startup Migration

Manual:

```lua
Vanguard.AddServicesDeep(script.Parent.Services)
Vanguard.Start():catch(warn)
```

Recommended bootstrap:

```lua
Vanguard.Bootstrap({
	Services = script.Parent.Services,
	Components = script.Parent.Components,
	Classes = script.Parent.Classes,
	Options = {
		LogLevel = "info",
	},
}):catch(warn)
```

Client uses `Controllers`.

## Lifecycle Differences to Audit

- Service priority is built in; higher priorities initialize first.
- Equal-priority service init hooks run concurrently.
- Controller init hooks run concurrently.
- Start hooks are spawned and not awaited.
- Components start after start hooks are scheduled.
- `IsStarted` means startup completed.

Do not rely on incidental module or alphabetical ordering for dependency completion.

## Module Failure Isolation

Vanguard wraps each module require and automatic registration. One bad module logs an error and does not stop later modules from loading.

This improves resilience but can move the visible failure: startup may continue until another service tries to look up the skipped definition. Treat module-loader errors as primary failures and fix them before debugging missing dependencies.

## Remote Signals and Properties

Define signals through Vanguard markers:

```lua
Client = {
	Changed = Vanguard.CreateSignal(),
	AimUpdated = Vanguard.CreateUnreliableSignal(),
	State = Vanguard.CreateProperty("Loading"),
}
```

Audit method names and behavior against [Networking](../networking/index.md). Remote properties are server-owned and support global/per-player values.

## Network Security Migration

Vanguard validates named network configuration at startup and runs guards before server remote handlers.

Add rules incrementally, starting with state-changing remotes:

```lua
local Validator = require(Vanguard.Util.Validator)

Network = {
	Purchase = {
		Validate = Validator.tuple(
			Validator.string({ MinLength = 1, MaxLength = 64 }),
			Validator.integer({ Min = 1, Max = 10 })
		),
		Authenticate = requireProfile,
		Verify = verifyPurchase,
		RateLimit = { Limit = 5, Window = 2 },
	},
}
```

Validation does not replace checks inside authoritative mutation methods.

## Logger Migration

Services and controllers receive `self.Logger` automatically:

```lua
self.Logger:Info("Ready")
```

Default startup logging is `info`. Set `LogLevel = "debug"` while migrating to see each registered object and lifecycle step.

## Dependency Differences

Vanguard has no external Wally dependencies. Utilities are available under `Vanguard.Util`.

Replace project-specific imports only when desired; migration does not require adopting every Vanguard utility immediately.

## Type Migration

Use Vanguard's exports:

```lua
type Service = Vanguard.Service
type Controller = Vanguard.Controller
type Promise = Vanguard.Promise
type RemoteSignal = Vanguard.RemoteSignal
type RemoteProperty = Vanguard.RemoteProperty
```

For specific service/controller fields, intersect custom shapes with base types. See [Type System](../type-system/index.md).

## Suggested Migration Order

1. Install Vanguard beside the existing package.
2. Convert one isolated service and controller pair.
3. Switch bootstrap for a test place or branch.
4. Confirm init/start timing and client proxy behavior.
5. Convert remaining services/controllers.
6. Add network validators and rate limits.
7. Adopt components/classes/utilities where they simplify existing code.
8. Remove the old framework dependency after no modules require it.

## Migration Checklist

- Every loaded ModuleScript returns exactly one value.
- Server and client require the same Vanguard package.
- Service and controller names remain unique.
- Required init work is in init hooks, not spawned start hooks.
- Client promise chains use supported methods.
- Server-only services are not looked up from the client.
- Client-facing remotes have validation and authorization policy.
- Wally and Rojo mappings point to the new package alias.
- Studio output shows Vanguard `0.1.13` on both runtimes.
