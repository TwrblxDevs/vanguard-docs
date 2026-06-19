# Signal

`Vanguard.Util.Signal` is a local event abstraction backed by `BindableEvent`. It supports connections, one-shot listeners, waiting, firing, and destruction.

It does not cross the client/server boundary. Use Vanguard remote signals for networking.

## Require and Create

```lua
local Signal = require(Vanguard.Util.Signal)
local changed = Signal.new()
```

## Connect

```lua
local connection = changed:Connect(function(newValue, oldValue)
	print(newValue, oldValue)
end)
```

Returns an `RBXScriptConnection`.

Callbacks receive exactly the values passed to `Fire`.

Connecting to a destroyed signal errors. Callback must be a function.

## Once

```lua
local connection = changed:Once(function(value)
	print("First change only", value)
end)
```

The connection disconnects before invoking the callback, preventing nested fires from invoking it again.

## Fire

```lua
changed:Fire(newValue, oldValue)
```

Firing a destroyed signal errors.

Values follow Roblox BindableEvent serialization behavior within the same runtime.

## Wait

```lua
local newValue, oldValue = changed:Wait()
```

Yields the calling thread until the next fire and returns its values.

Waiting on a destroyed signal errors before yielding. Destroying a signal while another thread is already waiting follows the underlying BindableEvent behavior; do not use destruction as a wake-up mechanism.

## Destroy

```lua
changed:Destroy()
```

Destroys the underlying BindableEvent and marks the signal destroyed. Calling Destroy repeatedly is safe.

## Cleaner Integration

Connections:

```lua
cleaner:Add(changed:Connect(callback))
```

Signal ownership:

```lua
cleaner:Add(changed)
```

Cleaner sees Signal's `Destroy` method.

## Promise Integration

```lua
local Promise = require(Vanguard.Util.Promise)

Promise.fromEvent(changed):andThen(function(value)
	print(value)
end)
```

`Promise.fromEvent` accepts the Signal because it exposes `Connect`.

## Signal vs RemoteSignal

| Behavior | Signal | RemoteSignal |
| --- | --- | --- |
| Scope | One runtime | Client/server boundary |
| Backing object | BindableEvent | RemoteEvent or UnreliableRemoteEvent |
| Server callback Player | No | Yes, for client-fired events |
| Network guards | No | Yes, inbound to server |
| `FireAll` / `FireExcept` | No | Server RemoteSignal only |

Use local Signal for in-process domain events. Use remote signals only when information must cross the network.
