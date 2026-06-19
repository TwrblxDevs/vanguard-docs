# Cleaner

`Vanguard.Util.Cleaner` owns resources and releases them in reverse registration order. Components create one Cleaner per attached Instance automatically.

## Require and Create

```lua
local Cleaner = require(Vanguard.Util.Cleaner)
local cleaner = Cleaner.new()
```

## Supported Tasks

Cleaner understands:

- `RBXScriptConnection`: calls `Disconnect`;
- `Instance`: calls `Destroy`;
- function: calls the function;
- table with `Destroy`: calls `:Destroy()`;
- otherwise table with `Cleanup`: calls `:Cleanup()`;
- otherwise table with `Disconnect`: calls `:Disconnect()`.

For tables with more than one cleanup method, priority is `Destroy`, then `Cleanup`, then `Disconnect`.

## Add

```lua
local taskItem = cleaner:Add(resource)
```

Returns the same resource for convenient construction:

```lua
local highlight = cleaner:Add(Instance.new("Highlight"))
highlight.Parent = character
```

`GiveTask` is an alias:

```lua
cleaner:GiveTask(resource)
```

Adding after cleanup errors. Cleaner is one-shot and should be replaced with a new instance when reuse is needed.

## Connect

```lua
cleaner:Connect(button.Activated, function()
	print("Activated")
end)
```

Connects the `RBXScriptSignal`, adds the connection, and returns it.

Equivalent manual code:

```lua
cleaner:Add(button.Activated:Connect(callback))
```

## GivePromise

```lua
cleaner:GivePromise(promise)
```

Adds a cleanup function that calls `promise:cancel()` or `promise:Cancel()` when one exists.

The bundled Vanguard Promise does not implement cancellation, so `GivePromise` has no cancellation effect on a normal `Vanguard.Util.Promise`. It is intended to interoperate with cancellable promise-like objects.

## Cleanup

```lua
cleaner:Cleanup()
```

Tasks run in reverse order:

```lua
cleaner:Add(function() print("first added") end)
cleaner:Add(function() print("second added") end)
cleaner:Cleanup()

-- second added
-- first added
```

Reverse order is useful when later resources depend on earlier ones.

Cleanup is idempotent. Calling it more than once does nothing after the first pass.

`Destroy` is an alias:

```lua
cleaner:Destroy()
```

## Component Pattern

```lua
Construct = function(self)
	self.Cleaner:Connect(self.Instance.Destroying, function()
		self.Logger:Debug("Instance is being destroyed")
	end)

	local attachment = Instance.new("Attachment")
	attachment.Parent = self.Instance
	self.Cleaner:Add(attachment)

	self.Cleaner:Add(function()
		self.Active = false
	end)
end
```

The component runs Cleaner after `Stop` when the tag is removed.

## Nested Cleaners

Cleaners expose `Destroy`, so one Cleaner can own another:

```lua
local parentCleaner = Cleaner.new()
local childCleaner = parentCleaner:Add(Cleaner.new())
```

Parent cleanup destroys the child cleaner.

## Error Behavior

Cleaner does not wrap task cleanup in `pcall`. If one task throws, cleanup stops and earlier tasks in the reverse-order list are not reached.

Cleanup functions should avoid throwing. When uncertain, contain expected failures inside the task itself:

```lua
cleaner:Add(function()
	local ok, err = pcall(releaseExternalResource)
	if not ok then
		warn(err)
	end
end)
```

## Lifecycle Guidance

- Create one Cleaner per ownership boundary.
- Add resources immediately after creating them.
- Do not share one Cleaner between objects with different lifetimes.
- Call cleanup exactly when the owner stops being valid.
- Replace the Cleaner after cleanup if the owner can restart.
