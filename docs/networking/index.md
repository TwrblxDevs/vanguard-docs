# Networking

Vanguard converts service `Client` definitions into Roblox remotes and builds typed-feeling client proxy objects around them. The network layer supports request/response functions, reliable and unreliable signals, and server-owned properties.

All client-to-server traffic passes through the configured [Network Security](../network-security/index.md) pipeline before service code receives it.

## Remote Definition Table

```lua
local MatchService = Vanguard.CreateService({
	Name = "MatchService",

	Client = {
		GetMatch = function(self, player)
			return self.Server:GetMatchFor(player)
		end,
		ReadyChanged = Vanguard.CreateSignal(),
		AimUpdated = Vanguard.CreateUnreliableSignal(),
		State = Vanguard.CreateProperty("Waiting"),
	},
})
```

Supported `Client` values:

| Definition value | Server runtime object | Client proxy object |
| --- | --- | --- |
| Function | `RemoteFunction` callback | Promise-returning or yielding method |
| `CreateSignal()` | Server RemoteSignal | Client RemoteSignal |
| `CreateUnreliableSignal()` | Server RemoteSignal | Client RemoteSignal |
| `CreateProperty(value)` | Server RemoteProperty | Client RemoteProperty |

Unsupported values fail server startup with the service and key name.

## Remote Functions

### Server Definition

```lua
function MatchService.Client:GetMatch(player)
	return self.Server:GetMatchFor(player)
end
```

Roblox supplies `player` as the first payload argument after `self`. The client cannot spoof this Player value.

The `self` object is a temporary context:

- `self.Server` returns the owning server service;
- `self.OtherRemote` reads another member from `service.Client`;
- assigning `self.Server` errors;
- assigning other fields writes to `service.Client`.

Errors thrown by the remote method propagate through `RemoteFunction` and reject the default client promise.

### Client Call

```lua
local MatchService = Vanguard.GetService("MatchService")

MatchService:GetMatch():andThen(function(match)
	print(match)
end):catch(function(err)
	warn(err)
end)
```

Dot and colon calls are both accepted on generated service methods:

```lua
MatchService.GetMatch()
MatchService:GetMatch()
```

The proxy removes itself from the outgoing argument list when called with `:`.

### Promise Mode

With `ServicePromises = true`, the default, client calls return a Vanguard Promise. Remote invocation happens inside the promise executor and errors reject it.

### Yielding Mode

```lua
Vanguard.Start({ ServicePromises = false })
local match = MatchService:GetMatch()
```

The calling thread yields until Roblox returns or throws. Use `pcall` when direct error handling is needed.

## Remote Signals

Signals are bidirectional remote events.

### Reliable Signal

```lua
Updated = Vanguard.CreateSignal()
```

Uses `RemoteEvent`.

### Unreliable Signal

```lua
AimUpdated = Vanguard.CreateUnreliableSignal()
```

Vanguard attempts to create `UnreliableRemoteEvent`. On runtimes where that class is unavailable, it falls back to `RemoteEvent`.

Use unreliable signals for high-frequency, replaceable information such as aim direction or cosmetic motion. Do not use them for purchases, inventory mutations, or events that must arrive.

### Server Receiving from a Client

```lua
function MatchService:VanguardStart()
	self.Client.ReadyChanged:Connect(function(player, ready)
		self:SetReady(player, ready)
	end)
end
```

Server callbacks receive `player, ...payload`. The payload passes rate limiting, validation, authentication, and verification once before any connected listener runs.

### Client Sending to the Server

```lua
MatchService.ReadyChanged:Fire(true)
```

### Server Sending to Clients

```lua
self.Client.Updated:Fire(player, payload)
self.Client.Updated:FireFor(player, payload) -- Alias of Fire
self.Client.Updated:FireAll(payload)
self.Client.Updated:FireExcept(excludedPlayer, payload)
self.Client.Updated:FireWhere(function(candidate)
	return candidate.Team == team
end, payload)
```

`FireWhere` evaluates the predicate for each current Player.

### Client Receiving from the Server

```lua
MatchService.Updated:Connect(function(payload)
	print(payload)
end)
```

Client callbacks receive only the server payload.

### Shared Signal Methods

```lua
local connection = signal:Connect(callback)
local onceConnection = signal:Once(callback)
local values = table.pack(signal:Wait())
signal:Destroy()
```

Destroying a server RemoteSignal destroys its underlying remote Instance. Treat framework-owned remote objects as service-lifetime resources and normally leave destruction to framework teardown.

## Remote Properties

Remote properties are server-owned values with an optional per-player override.

### Definition

```lua
State = Vanguard.CreateProperty("Waiting")
```

The initial value may be nil. Vanguard internally packs values so nil is preserved.

### Server Set

```lua
self.Client.State:Set("Running")
```

Updates the global value, fires the change remote to every client, and fires the server-side `Changed` signal with `nil, value`.

### Per-Player Override

```lua
self.Client.State:SetFor(player, "Spectating")
```

The override applies only to that Player. The server-side `Changed` signal fires with `player, value`.

### Clear Override

```lua
self.Client.State:ClearFor(player)
```

Removes the override and sends the current global value to that Player.

Per-player entries are removed automatically when Players leave.

### Server Get

```lua
local globalValue = self.Client.State:Get()
local effectiveValue = self.Client.State:Get(player)
local sameValue = self.Client.State:GetFor(player)
```

When a Player has no override, `Get(player)` returns the global value.

### Server Observe

```lua
local connection = self.Client.State:Observe(function(player, value)
	if player == nil then
		print("Global value changed", value)
	else
		print("Override changed", player, value)
	end
end)
```

The returned value is an `RBXScriptConnection`.

### Client Get

```lua
local value = MatchService.State:Get()
```

This invokes the server and passes through property network authentication and verification rules.

### Client Observe

```lua
local subscription = MatchService.State:Observe(function(value)
	print("Current or changed value", value)
end)

subscription:Disconnect()
```

Observe connects to future changes and starts an asynchronous fetch of the current value. Fetch failures are warned. The return value is a small object exposing `Disconnect`.

### Dot and Colon Calls

Remote property methods are bound to their instances. Both forms work:

```lua
property:Set(true)
property.Set(true)
```

This applies to the server and client property methods exposed by Vanguard.

## Service Proxy Construction

The first client `GetService(name)`:

1. waits for `_VanguardRemotes` within `RemoteTimeout`;
2. checks the server network protocol;
3. warns when server and client Vanguard package versions differ;
4. waits for the named service folder;
5. maps each child remote to a proxy member;
6. caches and returns the proxy.

Later calls return the same proxy table.

Only services with at least one `Client` remote receive a server remote folder. Looking up a service with no client remotes from the client therefore times out and errors; such a service is intentionally server-only.

## Protocol Information

```lua
local info = Vanguard.GetNetworkInfo()
print(info.Protocol, info.ServerVersion)
```

On the server this immediately returns protocol and server version. On the client fields are populated when the remote container is first resolved.

Current network protocol: `1`.

## Security Boundary

Roblox networking identifies the sending Player, but payload values remain attacker-controlled. Validate structure, authenticate server-owned session state, and verify action permissions for every sensitive inbound remote.

Continue with [Network Security](../network-security/index.md) and [Validator](../utilities/validator/index.md).
