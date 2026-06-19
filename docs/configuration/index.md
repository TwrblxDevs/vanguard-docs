# Configuration

Vanguard configuration controls startup, logging, networking, component activation, remote behavior, and update checks.

## Configure, Start, and Bootstrap

There are three supported entry points:

```lua
Vanguard.Configure(options)
Vanguard.Start(options)
Vanguard.Bootstrap(config)
```

`Configure` merges options without starting the framework. It must be called before `Start`.

```lua
Vanguard.Configure({
	LogLevel = "debug",
	StartComponents = false,
})

Vanguard.Start()
```

Passing options directly to `Start` performs the same merge immediately before startup:

```lua
Vanguard.Start({
	LogLevel = "warn",
})
```

`Bootstrap` loads configured folders and forwards `Options` to `Start`:

```lua
Vanguard.Bootstrap({
	Services = servicesFolder,
	Classes = classesFolder,
	Components = componentsFolder,
	Options = {
		LogLevel = "info",
	},
})
```

On the client, use `Controllers` instead of `Services`.

## StartOptions Reference

| Option | Runtime | Default | Description |
| --- | --- | --- | --- |
| `CheckForUpdates` | Server | `true` | Checks the configured Wally index after startup |
| `FreezeServices` | Server | `true` | Freezes the service registry table during startup |
| `FreezeControllers` | Client | `true` | Freezes the controller registry table during startup |
| `LogLevel` | Both | `"info"` | Root and automatically-created logger threshold |
| `Network` | Server | `nil` | Global authentication, verification, rejection handling, and default rules |
| `RemoteTimeout` | Client | `15` | Seconds to wait for remote folders and service remotes |
| `ServicePromises` | Client | `true` | Makes client remote methods return promises instead of yielding directly |
| `StartComponents` | Both | `true` | Starts registered components when framework startup completes |
| `UpdateCheckUrl` | Server | Wally index URL | Source used by the update checker |

Options that do not apply to the current runtime are ignored by that runtime.

## Logging

Accepted named levels are:

```text
trace < debug < info < warn < error < silent
```

Numeric levels are also accepted. See [Logger](../utilities/logger/index.md) for exact behavior.

## Network Options

```lua
Vanguard.Start({
	Network = {
		Default = {
			RateLimit = { Limit = 30, Window = 1 },
		},
		Authenticate = function(player, context)
			return true
		end,
		Verify = function(player, context, ...)
			return true
		end,
		OnRejected = function(context, rejection)
			-- Record metrics, flag abuse, or apply game policy.
		end,
		LogRejected = true,
	},
})
```

Unknown fields in `StartOptions.Network`, global default rules, and service rules fail startup. This catches misspelled security configuration instead of silently ignoring it.

Read [Network Security](../network-security/index.md) before configuring these callbacks.

## Registry Freezing

`FreezeServices` and `FreezeControllers` freeze the registry tables, not every object stored inside them.

```lua
local services = Vanguard.GetServices()
-- With FreezeServices enabled, assigning services.New = value fails.
```

Service and controller creation is already prohibited after `Start`, even when registry freezing is disabled. Disable freezing only when a tool genuinely needs mutable registry tables.

Classes and components have different rules:

- Classes can be registered and unregistered after startup.
- Components can be registered after startup and start immediately when `StartComponents` is enabled.

## Promise or Yielding Remote Methods

The default client behavior is asynchronous:

```lua
InventoryService:GetItems():andThen(function(items)
	print(items)
end)
```

Set `ServicePromises = false` to make remote methods yield and return values directly:

```lua
Vanguard.Start({ ServicePromises = false })
local items = InventoryService:GetItems()
```

Promise mode makes rejection handling explicit and avoids unexpectedly yielding the calling thread. It is recommended for most projects.

## Update Checks

The update check runs on the server after successful startup. It is asynchronous and does not delay the startup promise.

```lua
Vanguard.Start({
	CheckForUpdates = false,
})
```

HTTP failures are logged only at `debug`. A newer package version produces a visible warning with the Wally dependency string.

## Reading Configuration

```lua
local config = Vanguard.GetConfig()
print(config.LogLevel)
```

`GetConfig` returns a shallow clone of the selected options. Top-level assignment does not mutate Vanguard's registry, but nested tables are still shared references. Treat returned nested configuration as read-only.

## Reconfiguration Rules

- Call `Configure` only before `Start`.
- Call `Start` or `Bootstrap` once per runtime.
- A second start returns a rejected promise.
- Changing a source options table after startup does not rebuild remotes or network guards.
- Configure service network rules before server startup.

See [Lifecycle](../lifecycle/index.md) for startup timing.
