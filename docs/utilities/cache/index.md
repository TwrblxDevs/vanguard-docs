# Cache

`Vanguard.Util.Cache` is an in-memory key/value cache with optional per-entry expiration, a default TTL, least-recently-used capacity eviction, cached nil support, lazy production, and test clock injection.

## Create

```lua
local cache = Vanguard.CreateCache({
	DefaultTTL = 60,
	MaxSize = 100,
})
```

Or directly:

```lua
local Cache = require(Vanguard.Util.Cache)
local cache = Cache.new(options)
```

## Options

| Field | Default | Description |
| --- | --- | --- |
| `DefaultTTL` | nil | Entry lifetime in seconds when `Set` receives no TTL |
| `MaxSize` | nil | Positive integer capacity; overflow evicts least-recently-used entries |
| `Clock` | `os.clock` | Monotonic time function |

TTL must be non-negative. A nil TTL means no expiration. `MaxSize` must be a positive integer.

## Set

```lua
cache:Set(key, value)
cache:Set(key, value, 10)
```

Returns `value`.

Behavior:

1. expired entries are pruned;
2. the value is inserted or replaced;
3. expiration is calculated from the current clock;
4. the entry becomes most recently used;
5. LRU overflow is evicted.

An explicit TTL overrides `DefaultTTL`.

TTL `0` removes an existing entry immediately and does not store the new value, though `Set` still returns the provided value.

Keys cannot be nil. Values may be nil.

## Get

```lua
local value, found = cache:Get(key)
```

Returns `value, true` for a live entry and `nil, false` for a miss or expired entry.

Get refreshes LRU recency.

Always use `found` when nil may be cached:

```lua
cache:Set("optional", nil)

local value, found = cache:Get("optional")
print(value, found) -- nil, true
```

## Peek

```lua
local value, found = cache:Peek(key)
```

Same expiry and return behavior as `Get`, but does not refresh LRU recency.

Use Peek for diagnostics or reads that should not protect an entry from eviction.

## Has

```lua
if cache:Has(key) then
	-- Live entry exists.
end
```

Uses `Get`, so it refreshes LRU recency.

## GetOrSet

```lua
local profile, wasCached = cache:GetOrSet(userId, function(key)
	return loadProfile(key)
end)
```

On hit:

- producer is not called;
- returns cached value and `true`.

On miss:

- calls `producer(key)`;
- stores its first returned value using the provided/default TTL;
- returns that value and `false`.

Producer errors propagate and no value is stored.

`GetOrSet` is not a single-flight lock. Concurrent misses for the same key can run the producer more than once. Store a Promise or add external coordination when duplicate work must be prevented.

## Remove

```lua
local value, existed = cache:Remove(key)
```

Returns the removed value and membership flag. It does not need to check expiration first; an expired but not-yet-pruned entry may still be returned by direct Remove.

## Prune

```lua
local removedCount = cache:Prune()
```

Removes all expired entries at the current clock and returns their count.

Get, Peek, Count, Keys, and Set also clean relevant/all expired entries as part of normal work.

## Count

```lua
local count = cache:Count()
```

Prunes expired entries, then returns live entry count.

## Keys

```lua
for _, key in cache:Keys() do
	print(key)
end
```

Prunes first. Key ordering is unspecified.

## Clear and Destroy

```lua
cache:Clear()
cache:Destroy()
```

`Destroy` is an alias of `Clear`. The object is reusable after clearing; Destroy does not mark it permanently unusable.

## LRU Example

```lua
local cache = Vanguard.CreateCache({ MaxSize = 2 })

cache:Set("a", 1)
cache:Set("b", 2)
cache:Get("a") -- a becomes most recent
cache:Set("c", 3) -- b is evicted

print(cache:Has("a")) -- true
print(cache:Has("b")) -- false
print(cache:Has("c")) -- true
```

Eviction finds the oldest access by scanning current entries. Keep capacity appropriate for an in-memory utility; this implementation is not intended as an enormous database index.

## Deterministic Tests

```lua
local now = 0
local cache = Vanguard.CreateCache({
	DefaultTTL = 5,
	Clock = function()
		return now
	end,
})

cache:Set("key", "value")
now = 5
assert(not cache:Has("key"))
```

## What Cache Is Not

- It is not replicated.
- It is not persistent.
- It is not shared between Roblox servers.
- It does not serialize values.
- It does not automatically refresh expiring entries.
- It does not prevent concurrent producer duplication.

Use DataStore/Profile systems for persistence and MemoryStore for cross-server coordination.
