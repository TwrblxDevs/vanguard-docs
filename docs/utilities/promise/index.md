# Promise

`Vanguard.Util.Promise` is a small asynchronous primitive used by framework startup and client remote methods. It supports fulfillment, rejection, chaining, event conversion, delays, aggregation, finalization, and yielding await.

## Require

```lua
local Promise = require(Vanguard.Util.Promise)
type Promise = Promise.Promise
```

## States

```lua
Promise.Status.Pending
Promise.Status.Fulfilled
Promise.Status.Rejected
```

A promise settles once. Later calls to `resolve` or `reject` are ignored.

## Create

```lua
local promise = Promise.new(function(resolve, reject)
	task.delay(1, function()
		resolve("ready")
	end)
end)
```

The executor runs inside `task.spawn`. If it throws before settlement, the promise rejects with the error.

Executor signature:

```lua
type Executor = (
	resolve: (...any) -> (),
	reject: (...any) -> ()
) -> ()
```

Promises may resolve or reject with multiple values, including nil values.

## Resolve

```lua
local promise = Promise.resolve(value)
local multiple = Promise.resolve(first, second, nil)
```

Creates an asynchronously-executed fulfilled promise.

When a promise resolves with exactly one value and that value is another Vanguard Promise, it adopts the inner promise's eventual state and values.

```lua
return Promise.resolve(
	Promise.delay(1):andThen(function()
		return "done"
	end)
)
```

Non-Vanguard thenable tables are treated as ordinary values.

## Reject

```lua
local promise = Promise.reject("not available")
```

Creates a rejected promise. Rejections may also contain multiple values.

## Check a Value

```lua
if Promise.is(value) then
	-- Exact Vanguard Promise instance.
end
```

`Promise.is` checks that the value is a table whose metatable is the bundled Promise implementation.

## andThen

```lua
promise:andThen(function(value)
	return transform(value)
end, function(err)
	return recover(err)
end)
```

Returns a new promise.

Fulfillment behavior:

- calls `onFulfilled` when provided;
- passes all resolved values;
- resolves the returned promise with callback return values;
- rejects the returned promise if the callback throws.

Rejection behavior:

- calls `onRejected` when provided;
- passes all rejection values;
- resolves with callback return values, allowing recovery;
- propagates rejection unchanged when no rejection callback exists.

Returning one Vanguard Promise adopts it because normal promise resolution assimilation applies.

```lua
Promise.resolve(2):andThen(function(value)
	return Promise.delay(0.5):andThen(function()
		return value * 2
	end)
end):andThen(function(value)
	print(value) -- 4
end)
```

Callbacks attached after settlement are scheduled with `task.defer`; they are not called inline inside `andThen`.

## catch

```lua
promise:catch(function(err)
	warn(err)
	return fallbackValue
end)
```

Equivalent to `promise:andThen(nil, onRejected)`.

Returning an ordinary value recovers the chain. To preserve rejection, return `Promise.reject(err)` or throw.

## finally

```lua
promise:finally(function()
	busy = false
end)
```

Runs for both fulfillment and rejection.

- Original fulfillment values pass through.
- Original rejection values remain rejected.
- Callback return values are ignored.
- If the finalizer throws, the returned promise rejects with that new error.

## all

```lua
Promise.all({
	loadProfile(),
	loadInventory(),
	Promise.resolve("ready"),
}):andThen(function(results)
	print(results[1], results[2], results[3])
end)
```

`Promise.all` accepts an array of promises or ordinary values. Ordinary values are wrapped with `Promise.resolve`.

Behavior:

- resolves when every entry fulfills;
- preserves array index order, not completion order;
- rejects as soon as an entry rejects;
- resolves an empty input to `{}`;
- stores a one-value result directly;
- stores multi-value results as a packed table containing `n`.

Example multi-value result:

```lua
Promise.all({
	Promise.resolve("a", nil, "c"),
}):andThen(function(results)
	local packed = results[1]
	print(packed.n) -- 3
	print(table.unpack(packed, 1, packed.n))
end)
```

## fromEvent

```lua
Promise.fromEvent(button.Activated):andThen(function()
	print("Clicked")
end)
```

Optional predicate:

```lua
Promise.fromEvent(valueChanged, function(value)
	return value >= 10
end):andThen(function(value)
	print("Reached", value)
end)
```

The connection remains active until an event passes the predicate. It disconnects before resolving.

The bundled Promise has no cancellation API, so an event promise cannot be cancelled through Promise itself.

## delay

```lua
Promise.delay(2):andThen(function()
	print("Two seconds later")
end)
```

Uses `task.delay` and resolves without values.

## await

```lua
local success, value = promise:await()

if success then
	print(value)
else
	warn(value)
end
```

If pending, `await` yields the current coroutine until settlement. If already settled, it returns immediately.

Multiple values are preserved:

```lua
local success, first, second = Promise.resolve("a", "b"):await()
```

Always check the first boolean. `await` does not throw on promise rejection.

## Client Remote Methods

With default configuration, client service calls return Vanguard promises:

```lua
InventoryService:GetItems()
	:andThen(renderItems)
	:catch(function(err)
		self.Logger:Warn(err)
	end)
```

Network errors, server method errors, and Vanguard network rejections reject the promise.

## Startup Promises

`Start`, `Bootstrap`, and `OnStart` return Vanguard promises:

```lua
Vanguard.Bootstrap(config)
	:andThen(function()
		print("Ready")
	end)
	:catch(warn)
```

## Limitations

- No cancellation method is implemented.
- No timeout, race, retry, or status getter helper is included.
- Executors are spawned and cannot be forced to stop by settling the promise.
- Rejecting `Promise.all` does not cancel remaining work.

Build cancellation or timeout policy explicitly around task ownership when required.
