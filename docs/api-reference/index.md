# Vanguard API Reference

This page lists every public field and method on the main Vanguard module. Concept guides provide deeper examples and behavioral explanation.

Public main-module methods accept both dot and colon syntax:

```lua
Vanguard.GetService("InventoryService")
Vanguard:GetService("InventoryService")
```

Utility object methods use normal colon syntax unless documented otherwise.

## Public Fields

| Field | Runtime | Description |
| --- | --- | --- |
| `Name` | Both | `"Vanguard"` |
| `Version` | Both | Installed framework version, currently `0.1.13` |
| `NetworkProtocol` | Both | Network compatibility version, currently `1` |
| `Player` | Client | `Players.LocalPlayer` |
| `Util` | Both | Folder containing all utility ModuleScripts |
| `Logger` | Both | Root framework logger |
| `Services` | Server | Service registry |
| `Controllers` | Client | Controller registry |
| `Components` | Both | Component registry |
| `Classes` | Both | Class registry |

## Configuration and Startup

### Configure

```lua
Vanguard.Configure(options: StartOptions?): StartOptions
```

Merges options and returns the selected configuration. Must be called before `Start`.

### GetConfig

```lua
Vanguard.GetConfig(): StartOptions
```

Returns a shallow clone of selected options.

### Start

```lua
Vanguard.Start(options: StartOptions?): Promise
```

Starts the current runtime. Resolves after init hooks, start-hook scheduling, component startup, and readiness. Rejects when called more than once or when init fails.

### Bootstrap

```lua
Vanguard.Bootstrap(configOrParent: Instance | BootstrapConfig?, options: StartOptions?): Promise
```

Accepted forms:

```lua
Vanguard.Bootstrap(servicesOrControllersFolder, options)
```

or:

```lua
Vanguard.Bootstrap({
	Services = servicesFolder,
	Controllers = controllersFolder,
	Components = componentsFolder,
	Classes = classesFolder,
	Options = options,
})
```

Server uses `Services`; client uses `Controllers`. Classes load before services/controllers.

### OnStart

```lua
Vanguard.OnStart(): Promise
```

Resolves immediately when startup completed or waits for completion.

### IsStarted

```lua
Vanguard.IsStarted(): boolean
```

Returns whether startup completed.

## Logging and Helpers

### CreateLogger

```lua
Vanguard.CreateLogger(scope: string?): Logger
```

Creates a logger using the current configured `LogLevel`. Default scope is `Vanguard`.

### CreateCache

```lua
Vanguard.CreateCache(options: CacheOptions?): Cache
```

Shortcut for `Vanguard.Util.Cache.new(options)`.

### CreateRateLimiter

```lua
Vanguard.CreateRateLimiter(options: RateLimiterOptions): RateLimiter
```

Shortcut for `Vanguard.Util.RateLimiter.new(options)`.

## Update Check

### CheckForUpdates

```lua
Vanguard.CheckForUpdates()
```

Server only. Starts the asynchronous configured Wally index check. The normal server startup calls this automatically after readiness when enabled.

## Network Information

### GetNetworkInfo

```lua
Vanguard.GetNetworkInfo(): NetworkInfo
```

Returns `Protocol` and `ServerVersion`. Client fields populate when the remote container is resolved.

### GetNetworkStats

```lua
Vanguard.GetNetworkStats(): NetworkStats
```

Server only. Returns cloned accepted/rejected totals, counts by code, and counts by `Service.Remote`.

### ResetNetworkStats

```lua
Vanguard.ResetNetworkStats()
```

Server only. Clears all counters.

## Service API

### CreateService

```lua
Vanguard.CreateService<T>(definition: T): T
```

Server only. Validates and registers a service before startup. Creates an empty `Client` table and scoped logger when omitted.

### AddServices

```lua
Vanguard.AddServices(parent: Instance): { any }
```

Loads direct ModuleScript children before startup.

### AddServicesDeep

```lua
Vanguard.AddServicesDeep(parent: Instance): { any }
```

Loads all descendant ModuleScripts before startup.

`LoadServices` and `LoadServicesDeep` are aliases.

### GetService

```lua
Vanguard.GetService(name: string | { Name: string }): any
```

Server: returns a registered service after startup begins.

Client: returns or builds a remote service proxy after startup begins.

### GetServices

```lua
Vanguard.GetServices(): { [string]: ServiceDefinition }
```

Returns the server service registry after startup begins.

## Controller API

### CreateController

```lua
Vanguard.CreateController<T>(definition: T): T
```

Client only. Validates and registers a controller before startup and creates its logger when omitted.

### AddControllers

```lua
Vanguard.AddControllers(parent: Instance): { any }
```

Loads direct ModuleScript children before startup.

### AddControllersDeep

```lua
Vanguard.AddControllersDeep(parent: Instance): { any }
```

Loads all descendant ModuleScripts before startup.

`LoadControllers` and `LoadControllersDeep` are aliases.

### GetController

```lua
Vanguard.GetController(name: string | { Name: string }): any
```

Returns a registered client controller. Unknown lookup errors with registered names.

### GetControllers

```lua
Vanguard.GetControllers(): { [string]: ControllerDefinition }
```

Returns the controller registry after startup begins.

## Component API

### CreateComponent

```lua
Vanguard.CreateComponent(definition: ComponentDefinition | Component): Component
```

Creates or registers a component. Components created after startup start immediately when `StartComponents` is enabled.

### AddComponents

```lua
Vanguard.AddComponents(parent: Instance): { any }
```

Loads direct ModuleScript children.

### AddComponentsDeep

```lua
Vanguard.AddComponentsDeep(parent: Instance): { any }
```

Loads descendant ModuleScripts.

`LoadComponents` and `LoadComponentsDeep` are aliases.

### GetComponent

```lua
Vanguard.GetComponent(name: string | { Name: string }): Component
```

Returns the named component or errors.

### GetComponents

```lua
Vanguard.GetComponents(): { [string]: Component }
```

Returns the component registry.

## Class API

### CreateClass

```lua
Vanguard.CreateClass<T>(definition: T): Class & T
```

Creates and registers a class. A string `Extends` field resolves an already-registered parent.

### RegisterClass

```lua
Vanguard.RegisterClass<T>(class: T): T
```

Registers a class created by `Vanguard.Util.Class`.

### AddClasses

```lua
Vanguard.AddClasses(parent: Instance): { any }
```

Loads direct class ModuleScript children.

### AddClassesDeep

```lua
Vanguard.AddClassesDeep(parent: Instance): { any }
```

Loads descendant class ModuleScripts.

`LoadClasses` and `LoadClassesDeep` are aliases.

### GetClass

```lua
Vanguard.GetClass(name: string | Class): Class
```

Returns the registered class or errors.

### HasClass

```lua
Vanguard.HasClass(name: string | Class): boolean
```

Checks registry membership by name.

### GetClasses

```lua
Vanguard.GetClasses(): { [string]: Class }
```

Returns a shallow clone of the class registry.

### UnregisterClass

```lua
Vanguard.UnregisterClass(name: string | Class): Class?
```

Removes and returns the registry entry. Existing instances are unaffected.

## Remote Definition API

### CreateSignal

```lua
Vanguard.CreateSignal(): RemoteSignal
```

Server definition marker for a reliable bidirectional remote signal.

### CreateUnreliableSignal

```lua
Vanguard.CreateUnreliableSignal(): RemoteSignal
```

Server definition marker for an unreliable signal with reliable fallback.

### CreateProperty

```lua
Vanguard.CreateProperty(initialValue: any?): RemoteProperty
```

Server definition marker for a server-owned replicated property.

## Module Loading Behavior

Every `Add*` method:

1. validates the parent is an Instance;
2. collects matching ModuleScripts;
3. sorts by full name;
4. requires each module inside `pcall`;
5. registers the returned definition inside `pcall`;
6. logs and skips failures;
7. returns successful values.

One bad module does not stop the remaining modules from loading.

## Related References

- [Configuration](../configuration/index.md)
- [Lifecycle](../lifecycle/index.md)
- [Type System](../type-system/index.md)
- [Utilities](../utilities/index.md)
