# NetworkGuard

`Vanguard.Util.NetworkGuard` is the composable guard pipeline used internally by Vanguard's server network layer. It can also protect non-remote application boundaries that use the same validation/authentication model.

Most games should configure service `Network` rules instead of constructing this utility directly. Read [Network Security](../../network-security/index.md) first.

## Require

```lua
local NetworkGuard = require(Vanguard.Util.NetworkGuard)
local RateLimiter = require(Vanguard.Util.RateLimiter)
```

## Create

```lua
local limiter = RateLimiter.new({
	Limit = 5,
	Window = 1,
	WeakKeys = true,
})

local guard = NetworkGuard.new({
	Authenticate = function(player, context)
		return context.SessionActive, "Session inactive"
	end,
	Verify = function(player, context, ...)
		return true
	end,
	Rule = {
		RateLimit = limiter,
		Validate = payloadValidator,
		Authenticate = remoteAuthenticator,
		Verify = remoteVerifier,
	},
})
```

Unlike Vanguard service configuration, direct NetworkGuard requires `RateLimit` to already expose `:Check()`. It does not turn options tables into RateLimiter instances.

## Check

```lua
local allowed, rejection = guard:Check(context, ...payload)
```

Context must be a table containing non-nil `Player`. Other fields are application-defined when using the utility directly.

On success:

```lua
true, nil
```

On rejection:

```lua
false, {
	Code = "INVALID_PAYLOAD",
	Message = "...",
	Stage = "Validate",
}
```

## Pipeline Order

1. Rule `RateLimit`
2. Rule `Validate(...payload)`
3. Global `Authenticate(player, context)`
4. Rule `Authenticate(player, context)`
5. Global `Verify(player, context, ...payload)`
6. Rule `Verify(player, context, ...payload)`

Every callback must return exactly true to pass.

## Rejection Codes

| Code | Stage |
| --- | --- |
| `RATE_LIMITED` | `RateLimit` returned false |
| `INVALID_PAYLOAD` | `Validate` returned false |
| `UNAUTHENTICATED` | either authentication callback returned false |
| `UNVERIFIED` | either verification callback returned false |
| `GUARD_ERROR` | a callback or limiter threw |

Rate-limit rejections include numeric `RetryAfter` when the limiter returns it.

Callback errors become `GUARD_ERROR` with internal error value in `Detail`. They do not throw from `Check`.

Construction and context contract violations still assert because they are programming/configuration errors.

## Rule Fields Set to False

Direct rules accept `false` for `Validate`, `Authenticate`, `Verify`, and `RateLimit`:

```lua
Rule = {
	Authenticate = false,
}
```

This disables that rule field. It does not disable the separate global callbacks passed in options.

## Merge Rules

```lua
local merged = NetworkGuard.mergeRules(globalDefault, serviceDefault, remoteRule)
```

Rules are shallow-merged left to right. Later keys replace earlier values. Nil rule arguments are skipped. Non-table non-nil rules assert.

Example:

```lua
local merged = NetworkGuard.mergeRules(
	{ Authenticate = authenticate, RateLimit = sharedLimiter },
	{ RateLimit = false },
	{ Validate = validator }
)
```

Result retains Authenticate, disables RateLimit, and adds Validate.

## Standalone Example

```lua
local context = {
	Player = player,
	SessionActive = true,
	Action = "Equip",
}

local allowed, rejection = guard:Check(context, itemId, slot)
if not allowed then
	warn(rejection.Code, rejection.Message)
	return false
end

return equipItem(player, itemId, slot)
```

## Framework Integration Differences

The Vanguard server layer adds behavior around NetworkGuard:

- merges global, service-default, and remote rules;
- converts RateLimiter option tables into limiter objects;
- defaults network limiter weak keys to true;
- constructs standard contexts;
- tracks accepted/rejected statistics;
- runs `OnRejected`;
- throttles rejection logs;
- formats RemoteFunction and property errors;
- drops rejected signal events.

Use service rules when you want those features.

## Testing

Inject a RateLimiter clock to test guard timing deterministically:

```lua
local now = 0
local limiter = RateLimiter.new({
	Limit = 1,
	Window = 1,
	Clock = function()
		return now
	end,
})
```

Then check both `allowed` and structured rejection codes rather than matching complete human-readable messages.
