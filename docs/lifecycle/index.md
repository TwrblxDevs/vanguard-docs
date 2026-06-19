# Lifecycle

Vanguard separates registration, initialization, startup scheduling, and readiness. Choosing the correct phase prevents race conditions between services and controllers.

## Lifecycle Hooks

Services and controllers may define:

```lua
function Object:VanguardInit()
	-- Required setup that must complete before start hooks are scheduled.
end

function Object:VanguardStart()
	-- Runtime work scheduled after every init hook completes.
end
```

For Knit migration, `KnitInit` and `KnitStart` are recognized when the corresponding Vanguard hook is absent.

## Registration Phase

Before `Start`:

1. `CreateService` or `CreateController` registers explicit definitions.
2. `AddServices`, `AddControllers`, and their deep variants require modules and register plain returned definitions.
3. classes and components may be registered from their configured folders.
4. duplicate names fail registration.

Module loading is isolated. If one ModuleScript throws or does not return exactly one value, Vanguard logs the module path and continues loading other modules.

Registration does not call lifecycle hooks.

## Server Initialization

Services support numeric `Priority` values. Higher values initialize first.

```lua
local DatabaseService = Vanguard.CreateService({
	Name = "DatabaseService",
	Priority = 100,
	Client = {},
})
```

Server initialization follows these rules:

1. services are sorted by descending priority;
2. ties are sorted alphabetically by `Name`;
3. every init hook in one priority group runs concurrently;
4. Vanguard waits for the entire group;
5. the next lower priority group begins.

Example:

| Service | Priority | Init phase |
| --- | ---: | ---: |
| `DatabaseService` | 100 | 1 |
| `ProfileService` | 50 | 2 |
| `InventoryService` | 50 | 2 |
| `AnalyticsService` | 0 | 3 |

`ProfileService` and `InventoryService` initialize concurrently. If Inventory truly requires Profile to finish first, assign them different priorities or explicitly await a shared promise.

## Client Initialization

Controllers are sorted alphabetically and all controller init hooks run concurrently. Controllers do not currently have a priority field.

Use explicit promises or shared state when one controller must wait for another. Avoid relying on alphabetical launch order as a completion guarantee.

## Init Hook Errors

Init hooks run inside Vanguard promises. A thrown error rejects startup and prevents the normal startup-complete sequence.

Use init for:

- loading required configuration;
- connecting required internal dependencies;
- creating state needed by other systems;
- work that must finish before remotes become available.

Do not silently spawn required init work. Return only after required setup is complete.

## Start Hooks

After all init hooks complete, Vanguard schedules start hooks with `task.spawn`.

Server start hooks are scheduled in service priority order, then alphabetical order for ties. Client start hooks are scheduled alphabetically.

Important: Vanguard does not await start hooks.

```lua
function MatchService:VanguardStart()
	while true do
		self:RunMatchLoop()
		task.wait(1)
	end
end
```

Long-running loops belong in `VanguardStart` because they do not block readiness. Required one-time setup belongs in `VanguardInit`.

An error thrown after a start hook is spawned does not reject the already-running startup chain. Handle runtime failures inside long-lived start tasks when recovery or reporting is required.

## Components

After start hooks are scheduled, Vanguard starts registered components when `StartComponents` is enabled.

Each component then:

1. attaches to currently-tagged matching Instances;
2. subscribes to tag-added events;
3. subscribes to tag-removed events.

Component instance `Start` callbacks are also scheduled asynchronously.

## Readiness APIs

### Start

```lua
Vanguard.Start():andThen(function()
	print("Framework ready")
end)
```

The promise resolves after init hooks complete, start hooks are scheduled, components are started, and readiness is marked complete.

### OnStart

```lua
Vanguard.OnStart():andThen(function()
	print("Framework ready")
end)
```

`OnStart` resolves immediately when startup already completed. Otherwise it waits for the startup-complete event.

### IsStarted

```lua
if Vanguard.IsStarted() then
	-- Startup completed.
end
```

`IsStarted` reports completed startup, not merely that `Start` was called.

## Dependency Guidance

Prefer this pattern:

```lua
function InventoryService:VanguardInit()
	self.ProfileService = Vanguard.GetService("ProfileService")
	self.Ready = false

	-- Perform required initialization here.
	self.Ready = true
end
```

All services are registered before any init hook runs, so dependency lookup is safe during init. Priority controls completion order, not whether a service exists in the registry.

Avoid using arbitrary waits such as `task.wait(1)` to coordinate systems. Use priorities, explicit promises, events, or well-defined readiness methods.

## Startup Timeline

```text
require modules
  -> register definitions
  -> build server remotes and guards
  -> run init hooks (awaited)
  -> schedule start hooks (not awaited)
  -> start components
  -> mark ready
  -> resolve Start and OnStart
```

Related guides: [Services](../services/index.md), [Controllers](../controllers/index.md), [Components](../components/index.md), and [Promise](../utilities/promise/index.md).
