# RateLimiter

`Vanguard.Util.RateLimiter` implements a per-key rolling-window budget. Vanguard network rules use it to limit inbound requests per Player.

## Create

```lua
local limiter = Vanguard.CreateRateLimiter({
	Limit = 10,
	Window = 1,
	WeakKeys = true,
})
```

Or directly:

```lua
local RateLimiter = require(Vanguard.Util.RateLimiter)
local limiter = RateLimiter.new(options)
```

## Options

| Field | Required | Description |
| --- | --- | --- |
| `Limit` | Yes | Positive capacity inside one rolling window |
| `Window` | Yes | Positive window length in seconds |
| `Clock` | No | Time function; defaults to `os.clock` |
| `WeakKeys` | No | Uses weak-key bucket storage when true |

Limit and Window may be fractional positive numbers. Request cost may also be fractional.

Use `WeakKeys = true` for Instance or table keys whose buckets should disappear when the key is no longer referenced. Primitive string/number keys are not collectible in the same way and should be pruned or reset explicitly when unbounded.

## Check

```lua
local allowed, retryAfter = limiter:Check(key)
```

Default cost is `1`.

When allowed:

- records the current timestamp and cost;
- returns `true, 0`.

When rejected:

- does not consume cost;
- returns `false, retryAfter`;
- retryAfter is the earliest time enough prior cost will expire.

`Allow` is an alias:

```lua
local allowed, retryAfter = limiter:Allow(key)
```

## Weighted Cost

```lua
local allowed = limiter:Check(player, 3)
```

This consumes three units when allowed.

A cost larger than total Limit always rejects and returns the full Window as retry time.

Cost must be greater than zero.

## Global Bucket

Omit key or pass nil to use one internal global key:

```lua
local allowed = limiter:Check()
```

All nil-key checks share that bucket.

## GetRemaining

```lua
local remaining, resetAfter = limiter:GetRemaining(key)
```

Prunes expired entries first.

- `remaining` is current unused capacity.
- `resetAfter` is time until the oldest active entry expires.
- an empty bucket returns `Limit, 0`.

The window is rolling, so resetAfter is not necessarily when all active cost disappears.

## Reset

```lua
limiter:Reset(key)
```

Removes one key's entire bucket. Passing nil resets the global bucket.

## Prune

```lua
local removedBuckets = limiter:Prune()
```

Removes expired entries from every bucket, deletes empty buckets, and returns the number of buckets removed.

Checks and remaining queries also prune the accessed bucket.

## Clear and Destroy

```lua
limiter:Clear()
limiter:Destroy()
```

`Destroy` aliases `Clear`. The limiter can be reused afterward.

## Rolling-Window Example

With `Limit = 2`, `Window = 1`:

```text
t=0.0 check -> allowed
t=0.2 check -> allowed
t=0.3 check -> rejected, retry after about 0.7
t=1.0 first cost expires
t=1.0 check -> allowed
```

Unlike a fixed wall-clock window, traffic does not receive a fresh full budget at arbitrary second boundaries.

## Network Rules

```lua
Network = {
	Purchase = {
		RateLimit = {
			Limit = 3,
			Window = 2,
		},
	},
}
```

Vanguard creates one limiter for that remote and uses Player as key. Framework-created network limiters default `WeakKeys` to true.

Share one limiter object across rules when several remotes should consume one combined budget.

## Deterministic Tests

```lua
local now = 0
local limiter = Vanguard.CreateRateLimiter({
	Limit = 1,
	Window = 5,
	Clock = function()
		return now
	end,
})

assert(limiter:Check("key"))
assert(not limiter:Check("key"))

now = 5
assert(limiter:Check("key"))
```

## Memory Guidance

Buckets store one timestamp/cost entry per allowed check until it expires. Choose limits that match realistic traffic. Call `Prune` periodically for large primitive-key populations or reset keys when their owners leave.
