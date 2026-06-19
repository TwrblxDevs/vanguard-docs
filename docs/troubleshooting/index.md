# Troubleshooting

This guide maps common Vanguard, Wally, Rojo, Studio, remote, lifecycle, and typing failures to concrete checks.

## First Diagnostic Pass

Before changing code:

1. read the complete first error, not only the final â€œrequested module experienced an errorâ€ line;
2. note whether the stack is Server or Client;
3. inspect the installed version in the Wally `_Index` path;
4. confirm the game dependency and package source version match;
5. start Vanguard with `LogLevel = "debug"`;
6. identify whether failure occurs during module require, registration, init, remote construction, or runtime calls.

```lua
Vanguard.Start({
	LogLevel = "debug",
})
```

## `vanguard is not a valid member of Folder ReplicatedStorage.Packages`

Likely causes:

- Wally dependencies were not installed;
- Rojo does not map `Packages` into ReplicatedStorage;
- require path casing does not match generated package name;
- the game uses a stale Wally lock/install directory;
- a package alias differs from the require path.

Checks:

```toml
[dependencies]
Vanguard = "twrblxdevs/vanguard@0.1.13"
```

Run:

```bash
wally install
```

Require the alias used in the dependency table:

```lua
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)
```

Confirm the game Rojo project maps the generated `Packages` folder.

## Studio Stack Shows an Older `_Index` Version

Example:

```text
ReplicatedStorage.Packages._Index.twrblxdevs_vanguard@0.1.9...
```

If source code says `0.1.13` but Studio shows `0.1.9`, the game is executing an installed old package.

1. update the game project's `wally.toml`;
2. run `wally install` in the game project, not only the Vanguard source repository;
3. sync the game again through Rojo;
4. inspect `ReplicatedStorage.Packages` in Studio;
5. restart the play session.

Editing this framework repository does not automatically update a different game's Wally installation.

## `Module code did not return exactly one value`

Every ModuleScript loaded by `AddServices*`, `AddControllers*`, `AddComponents*`, or `AddClasses*` must return exactly one value.

Valid:

```lua
local Service = Vanguard.CreateService({
	Name = "ExampleService",
})

return Service
```

Invalid:

```lua
-- No return statement.
Vanguard.CreateService({ Name = "ExampleService" })
```

Vanguard catches module require failures, logs the full module path, skips that module, and continues loading others. The failed definition will still be unavailable later.

## `Requested module experienced an error while loading`

This is usually a secondary error. Find the earlier stack entry from inside the required module.

Common causes:

- bad package require path;
- code running on the wrong runtime;
- missing return value;
- assertion in `CreateService`, `CreateController`, class, component, or utility construction;
- requiring another module that failed first.

The framework's module loader isolates modules it loads, but Roblox still reports the underlying require error in output.

## Service or Controller Already Exists

Names are registry keys and must be unique.

Common accidental duplicate pattern:

- one bootstrap loads a folder;
- another script separately requires and registers the same definition;
- two modules use the same `Name`.

Returning an object already registered by its own module is supported and idempotent. Registering a different object under the same name is not.

Search all definitions:

```bash
rg 'Name = "InventoryService"' src
```

## `Vanguard already started`

`Start` and `Bootstrap` are one-shot per runtime.

Check for:

- two bootstrap scripts;
- calling `Start` after `Bootstrap`;
- a module that starts Vanguard as a side effect;
- test harness setup running twice.

Use `OnStart` to wait for existing startup instead of calling Start again:

```lua
Vanguard.OnStart():andThen(function()
	-- Ready.
end)
```

## Create Service or Controller After Start

Services and controllers must be registered before startup because remotes and lifecycle ordering are built from the complete registry.

Load all service/controller folders before `Start`, or use `Bootstrap`.

Classes and components intentionally allow later registration.

## Init Hook Hangs Startup

All init hooks are awaited.

Look for:

- infinite loops in `VanguardInit`;
- waiting for an event that can only happen after start hooks;
- yielding remote calls during a circular client/server startup dependency;
- a promise/event that never settles;
- same-priority services waiting on one another.

Move long-running loops to `VanguardStart`. Use different service priorities when completion order is required.

## Start Hook Work Is Not Finished When `OnStart` Resolves

This is expected. Start hooks are scheduled with `task.spawn` and are not awaited.

Move required readiness work to `VanguardInit`, or expose and await a domain-specific readiness promise.

## Client `GetService` Times Out

Possible causes:

- server Vanguard did not start;
- server init failed before remotes were parented;
- service name is misspelled;
- service has no `Client` remote members, so no service remote folder exists;
- client/server package protocol mismatch;
- `RemoteTimeout` is shorter than legitimate server initialization.

Verify server output first. Then inspect `_VanguardRemotes` beneath the Vanguard package while playing.

Increase timeout only after ruling out startup failure:

```lua
Vanguard.Start({
	RemoteTimeout = 30,
})
```

## Network Protocol Mismatch

```text
Vanguard network protocol mismatch (client 1, server ...)
```

Server and client are executing incompatible Vanguard packages or a stale remotes folder.

- install one package version for both runtimes;
- remove duplicate package copies;
- restart the play session;
- verify bootstrap scripts require the same `ReplicatedStorage.Packages.Vanguard` ModuleScript.

A package-version mismatch with the same protocol warns but remains usable. An actual protocol mismatch errors before proxy construction.

## `[VanguardNetwork/INVALID_PAYLOAD]`

The client sent arguments that failed the configured validator.

Check:

- argument order;
- string/array limits;
- strict shape extra keys;
- optional fields wrapped with `Validator.optional`;
- tuple validator count;
- numeric range and finite requirements.

Do not remove validation simply to silence the error. Align the client payload with the server contract.

## `[VanguardNetwork/UNAUTHENTICATED]`

An authentication callback returned false.

Check server-owned session/profile state and whether the request is arriving before profile initialization completes. Authentication receives `player, context`, not payload arguments.

## `[VanguardNetwork/UNVERIFIED]`

A verification callback denied the specific action.

Inspect ownership, permission, distance, cooldown, inventory, currency, or game-state checks. Verification receives `player, context, ...payload`.

## `[VanguardNetwork/RATE_LIMITED]`

The Player exceeded the rolling-window budget.

Check `Vanguard.GetNetworkStats()` and determine whether traffic is legitimate, duplicated by UI event connections, or abusive.

Do not blindly raise limits. First confirm the client is not connecting the same handler multiple times or firing every frame when a lower-frequency update is enough.

## `[VanguardNetwork/GUARD_ERROR]`

A validation/authentication/verification callback or limiter threw.

The server rejection log includes internal detail. Fix the callback error. Guard callbacks must return explicit true to pass.

## Network Rule Does Not Match a Client Remote

Vanguard fails startup for misspelled or stale service network keys:

```text
Service "TradeService" Network rule "Offfer" does not match a Client remote
```

Rename the rule to the exact `Client` key or remove it.

Unknown network fields also fail startup. Use only `RateLimit`, `Validate`, `Authenticate`, and `Verify` in rules.

## Remote Property `attempt to index boolean with '_value'`

This error came from older Vanguard versions when a bound property method was called with dot syntax:

```lua
Property.Set(true)
```

Vanguard `0.1.10+` binds remote property methods and supports both dot and colon calls. Update the game's installed Wally package. On current versions both are valid:

```lua
Property:Set(true)
Property.Set(true)
```

## Remote Property Observe Does Not Fire Immediately

Client `Observe` performs its initial `Get` asynchronously. Ensure:

- the server property read passes authentication/verification;
- the remote folder exists;
- the subscription has not been disconnected;
- output does not show a warned fetch error.

Future server `Set` and `SetFor` calls arrive through the changed event.

## Component Does Not Attach

Check:

- exact CollectionService tag spelling;
- `StartComponents` is true;
- component is registered;
- ancestor filter includes the Instance;
- `Construct` is not throwing;
- tag was applied to the expected Instance;
- component is running on the correct server/client runtime.

```lua
local component = Vanguard.GetComponent("TaggedButton")
print(component:IsStarted())
print(#component:GetAll())
```

## Cleaner Rejects New Tasks

Cleaner is one-shot. After `Cleanup`, create a new Cleaner:

```lua
self.Cleaner:Cleanup()
self.Cleaner = Cleaner.new()
```

Components do this automatically when their component-level observer restarts and create fresh per-instance Cleaners on reattachment.

## Promise Chain Silently Recovers

A `catch` callback that returns normally converts rejection into fulfillment:

```lua
promise:catch(function(err)
	warn(err)
	return fallback -- Chain is now fulfilled.
end)
```

Preserve rejection explicitly:

```lua
return Promise.reject(err)
```

## Promise Never Resolves

Check custom executors for code paths that call neither `resolve` nor `reject`. Check `fromEvent` predicates and whether the expected event can still fire.

The bundled Promise has no timeout/cancellation helper, so add explicit timeout policy when waiting on external conditions.

## Cache Returns nil

Always inspect the second return:

```lua
local value, found = cache:Get(key)
```

`nil, true` is a cached nil. `nil, false` is a miss or expiration.

## Studio Autocomplete Shows `*error-type*`

Prefer direct require paths. If using `WaitForChild`, add the static type cast shown in [Getting Started](../getting-started/index.md).

## Update Check Does Nothing

Check:

- `CheckForUpdates` is true;
- HttpService requests are enabled;
- `UpdateCheckUrl` is correct;
- log level is `debug` to see non-fatal failures.

The update checker is non-blocking and does not affect framework readiness.

## Useful Runtime Diagnostics

```lua
print(Vanguard.Version)
print(Vanguard.NetworkProtocol)
print(Vanguard.GetConfig().LogLevel)

local info = Vanguard.GetNetworkInfo()
print(info.Protocol, info.ServerVersion)
```

Server:

```lua
print(Vanguard.GetServices())
print(Vanguard.GetNetworkStats())
```

Client:

```lua
print(Vanguard.GetControllers())
```

Both:

```lua
print(Vanguard.GetComponents())
print(Vanguard.GetClasses())
```
