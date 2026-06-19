# Network Security

Vanguard applies one server-authoritative guard pipeline to every inbound remote function, client-fired signal, and remote property read.

This guide explains the threat model, rule configuration, callback contracts, rejection behavior, statistics, and secure patterns.

## Threat Model

Assume a client can:

- call any replicated RemoteFunction or RemoteEvent;
- call it at arbitrary frequency;
- send values of any Roblox-serializable type;
- send malformed, oversized, stale, or contradictory data;
- replay previously-valid requests;
- inspect all client code and replicated values.

A client cannot choose the `Player` argument Roblox supplies to `OnServerInvoke` or `OnServerEvent`. Vanguard uses that server-supplied Player as the identity key for rate limiting and callbacks.

Do not put a secret token in client code and treat it as authentication. Exploiters can read it. Authenticate against server-owned session, profile, ban, role, or capability state.

## Service Rules

Rules live beside a service's `Client` definition and use the same remote keys:

```lua
local Validator = require(Vanguard.Util.Validator)

local TradeService = Vanguard.CreateService({
	Name = "TradeService",

	Client = {
		Offer = function(self, player, targetUserId, itemIds)
			return self.Server:Offer(player, targetUserId, itemIds)
		end,
		OfferChanged = Vanguard.CreateSignal(),
	},

	Network = {
		Default = {
			RateLimit = { Limit = 20, Window = 1 },
		},

		Offer = {
			Validate = Validator.tuple(
				Validator.integer({ Min = 1 }),
				Validator.array(Validator.string({ MinLength = 1, MaxLength = 64 }), {
					MinLength = 1,
					MaxLength = 20,
				})
			),
			Authenticate = function(player, context)
				return ProfileService:IsLoaded(player), "Profile is not loaded"
			end,
			Verify = function(player, context, targetUserId, itemIds)
				return context.Service:CanOffer(player, targetUserId, itemIds), "Trade is not permitted"
			end,
			RateLimit = { Limit = 3, Window = 2 },
		},
	},
})
```

Rule fields:

| Field | Callback or value | Purpose |
| --- | --- | --- |
| `RateLimit` | Options, limiter, `false`, or nil | Per-player rolling-window request cap |
| `Validate` | `(...payload) -> boolean, reason?` | Payload type and shape checks |
| `Authenticate` | `(player, context) -> boolean, reason?` | Server-owned identity/session checks |
| `Verify` | `(player, context, ...payload) -> boolean, reason?` | Action authorization and contextual checks |

Unknown rule fields fail startup. Rules whose names do not match a `Client` remote also fail startup.

## Defaults and Overrides

`Network.Default` applies to every remote in one service. A named rule overrides fields shallowly.

```lua
Network = {
	Default = {
		Authenticate = requireAuthenticatedProfile,
		RateLimit = { Limit = 20, Window = 1 },
	},

	PublicStatus = {
		Authenticate = false,
		RateLimit = { Limit = 5, Window = 1 },
	},
}
```

Set a field to `false` to disable an inherited service/global-default rule field for one remote. Global top-level `Network.Authenticate` and `Network.Verify` callbacks are separate and cannot be disabled by service rules.

## Global Policy

Configure server-wide policy through start options:

```lua
Vanguard.Start({
	Network = {
		Default = {
			RateLimit = { Limit = 60, Window = 1 },
		},

		Authenticate = function(player, context)
			return not BanService:IsBanned(player), "Access denied"
		end,

		Verify = function(player, context, ...)
			return player.Parent ~= nil, "Player is leaving"
		end,

		OnRejected = function(context, rejection)
			SecurityMetrics:Record(context, rejection)
		end,

		LogRejected = true,
	},
})
```

Global default rules merge first, then service defaults, then named remote rules. Global `Authenticate` and `Verify` callbacks run independently after validation.

## Enforcement Order

Vanguard evaluates requests in this order:

1. **RateLimit**: consumes one unit for the server-supplied Player.
2. **Validate**: checks only the client payload.
3. **Global Authenticate**: checks global identity/session policy.
4. **Remote Authenticate**: checks merged service/remote authentication.
5. **Global Verify**: checks global contextual policy.
6. **Remote Verify**: authorizes the specific action.

Rate limiting happens before validation so malformed requests still consume capacity.

Every callback must explicitly return `true` to pass. Returning nil, false, or throwing rejects the request.

## Context

Authentication, verification, and rejection callbacks receive a context table:

```lua
type NetworkContext = {
	Player: Player,
	Service: any,
	ServiceName: string,
	RemoteName: string,
	RemoteType: "Function" | "Signal" | "Property",
	Arguments: { any } & { n: number },
}
```

`Arguments` is packed and includes `n`, preserving trailing nil values.

Use `context.ServiceName` and `context.RemoteName` for metrics. Use the callback's explicit payload parameters for readable verification logic.

## Rejections

```lua
type NetworkRejection = {
	Code: string,
	Message: string,
	Stage: string,
	RetryAfter: number?,
	Detail: any?,
}
```

Built-in codes:

| Code | Meaning |
| --- | --- |
| `RATE_LIMITED` | The Player exceeded the configured rolling-window limit |
| `INVALID_PAYLOAD` | Validation returned false |
| `UNAUTHENTICATED` | An authentication callback returned false |
| `UNVERIFIED` | A verification callback returned false |
| `GUARD_ERROR` | A guard callback or limiter threw |

`RetryAfter` is set for rate-limit rejections. `Detail` contains internal callback errors and is used only in server logging/callbacks; the formatted client error remains generic for guard failures.

## Transport Behavior

### Remote Functions

Rejected calls throw a formatted server error:

```text
[VanguardNetwork/INVALID_PAYLOAD] argument 1 must be a string; got number
```

In default client promise mode, this rejects the promise.

### Remote Signals

Rejected client events are dropped before any server listener runs. The client receives no response because RemoteEvents are one-way.

### Remote Properties

Property `Get` requests are authenticated and verified. Rejected reads throw like remote functions. Property update delivery from server to client is not an inbound client request and does not run guards.

## Rejection Logging

Logging is enabled unless `LogRejected = false`.

To avoid output floods, identical rejection logs are throttled for five seconds per Player, service, remote, and rejection code. Statistics and `OnRejected` still process every rejection.

Disable logs when a custom security pipeline owns reporting:

```lua
Network = {
	LogRejected = false,
	OnRejected = function(context, rejection)
		-- Custom reporting.
	end,
}
```

If `OnRejected` throws, Vanguard logs that callback failure.

## Statistics

Server only:

```lua
local stats = Vanguard.GetNetworkStats()

print(stats.Accepted)
print(stats.Rejected)
print(stats.ByCode.RATE_LIMITED)

for remoteName, remoteStats in stats.ByRemote do
	print(remoteName, remoteStats.Accepted, remoteStats.Rejected)
end
```

Stats count all inbound requests, including requests to remotes without explicit rules.

Reset counters:

```lua
Vanguard.ResetNetworkStats()
```

Returned stats are cloned and can be safely modified by the caller.

## Rate Limit Configuration

Options create a dedicated limiter for each remote:

```lua
RateLimit = {
	Limit = 10,
	Window = 1,
}
```

`WeakKeys` defaults to true for framework-created network limiters so departed Player keys can be collected.

An existing limiter may be shared intentionally:

```lua
local sharedLimiter = Vanguard.CreateRateLimiter({
	Limit = 20,
	Window = 1,
	WeakKeys = true,
})

Network = {
	FirstRemote = { RateLimit = sharedLimiter },
	SecondRemote = { RateLimit = sharedLimiter },
}
```

Both remotes then consume the same per-Player budget.

## Authentication Pattern

Authentication checks whether a Player currently has a valid server-owned session:

```lua
Authenticate = function(player)
	local profile = ProfileService:GetProfile(player)
	return profile ~= nil and profile:IsActive(), "Profile unavailable"
end
```

Good authentication inputs:

- loaded profile/session state;
- server-maintained login or tutorial completion state;
- server-owned role or access capability;
- ban and moderation state.

Bad authentication inputs:

- a client-provided boolean;
- a token embedded in a LocalScript;
- a replicated StringValue treated as secret;
- a UserId sent in the payload instead of `player.UserId`.

## Verification Pattern

Verification checks the requested action against authoritative state:

```lua
Verify = function(player, context, itemId, targetSlot)
	local inventory = InventoryService:GetInventory(player)
	if not inventory:Owns(itemId) then
		return false, "Item is not owned"
	end

	if not inventory:IsValidSlot(targetSlot) then
		return false, "Invalid slot"
	end

	return true
end
```

Re-check the same critical conditions in mutation code when concurrency can change state between verification and mutation. Guards improve boundaries; they do not provide transactions.

## Validation Pattern

```lua
Validate = Validator.tuple(
	Validator.string({ MinLength = 1, MaxLength = 64 }),
	Validator.shape({
		Slot = Validator.integer({ Min = 1, Max = 10 }),
		Equipped = Validator.boolean(),
	})
)
```

Validation should reject impossible types, unexpected keys, oversized arrays/strings, NaN, infinity, and out-of-range numbers before application logic sees them.

See the complete [Validator guide](../utilities/validator/index.md).

## Protocol Verification

The server stamps `_VanguardRemotes` with:

- `VanguardProtocol`;
- `VanguardVersion`.

The client rejects an incompatible protocol before building service proxies and warns when package versions differ.

Protocol verification prevents accidental client/server framework incompatibility. It is not player authentication and does not prove that a client is unmodified.

```lua
local info = Vanguard.GetNetworkInfo()
print(info.Protocol, info.ServerVersion)
```

Current protocol: `1`.

## Security Checklist

- Validate every mutable or sensitive request payload.
- Cap string and collection sizes.
- Reject NaN and infinity for numeric gameplay values.
- Rate-limit expensive and state-changing operations.
- Use `player` supplied by Roblox, never a payload UserId as identity.
- Authenticate against server-owned state.
- Verify ownership, distance, cooldown, currency, and permissions on the server.
- Treat signal payloads as untrusted exactly like function payloads.
- Monitor rejection statistics for abuse and configuration mistakes.
- Keep mutation logic authoritative even after a guard passes.
