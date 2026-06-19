# Components

Components attach reusable behavior to Instances tagged with CollectionService. They run on the server or client and create one isolated object per matching Instance.

## Create a Component

```lua
local TaggedButton = Vanguard.CreateComponent({
	Name = "TaggedButton",
	Tag = "VanguardButton",

	Construct = function(self)
		assert(self.Instance:IsA("GuiButton"), "VanguardButton must tag a GuiButton")

		self.Cleaner:Connect(self.Instance.Activated, function()
			self.Logger:Info(`Activated {self.Instance:GetFullName()}`)
		end)
	end,

	Start = function(self)
		self.Instance.Visible = true
	end,

	Stop = function(self)
		self.Instance.Visible = false
	end,
})
```

`Tag` is required. `Name` defaults to `Tag`.

## Definition Fields

| Field | Required | Description |
| --- | --- | --- |
| `Tag` | Yes | CollectionService tag to observe |
| `Name` | No | Registry name; defaults to `Tag` |
| `Ancestor` | No | One allowed Instance ancestor |
| `Ancestors` | No | Array of allowed Instance ancestors |
| `Logger` | No | Logger shared by component instance objects |
| `Construct` | No | Synchronous setup called when an Instance attaches |
| `Start` | No | Asynchronously scheduled after successful construction |
| `Stop` | No | Called before per-instance cleanup on detach |
| `OnError` | No | Custom lifecycle error handler |

All other definition keys are shallow-copied onto every component instance object.

## Instance Object

Each tagged Instance receives an object containing:

| Field | Description |
| --- | --- |
| `Instance` | The tagged Roblox Instance |
| `Cleaner` | A fresh Cleaner owned by this attachment |
| `Component` | The registered component object |
| `Vanguard` | Current server or client Vanguard runtime |
| `Logger` | Component logger |

Definition methods and custom fields are copied onto this object. Mutable table fields are shallow copies by reference, so initialize per-instance mutable state in `Construct`.

```lua
Construct = function(self)
	self.State = {}
end
```

## Attachment Lifecycle

When a matching Instance is discovered:

1. ancestor filters are checked;
2. the instance object and Cleaner are created;
3. `Construct(self)` runs synchronously;
4. if construction succeeds, `Start(self)` is scheduled with `task.spawn`.

When the tag is removed or the component stops:

1. the attachment is removed from the component registry;
2. `Stop(self)` runs;
3. `self.Cleaner:Cleanup()` runs in reverse task order.

If `Construct` fails, the attachment is discarded and its Cleaner runs. `Start` is not scheduled.

## Ancestor Filtering

Restrict a component to one hierarchy:

```lua
return Vanguard.CreateComponent({
	Tag = "EnemyHealthBar",
	Ancestor = workspace.Enemies,
})
```

Or several:

```lua
return Vanguard.CreateComponent({
	Tag = "Interactable",
	Ancestors = {
		workspace.Map,
		workspace.EventMap,
	},
})
```

An Instance matches when it equals an allowed ancestor or is its descendant.

## Error Handling

Without `OnError`, errors are logged through the component logger or `warn`:

```text
Component "TaggedButton" failed in Construct for Players.Name.PlayerGui.Button: ...
```

Custom handling:

```lua
OnError = function(component, instance, methodName, err)
	warn(component.Name, instance, methodName, err)
end
```

The handler receives the component object, tagged Instance, lifecycle method name, and error value.

## Component Object API

### Start

```lua
component:Start()
```

Starts tag observation and attaches current matching Instances. Calling it again is idempotent and returns the component.

### Stop and Destroy

```lua
component:Stop()
component:Destroy() -- Alias of Stop
```

Disconnects CollectionService listeners and detaches every current instance. A stopped component can be started again.

### IsStarted

```lua
local active = component:IsStarted()
```

### Get

```lua
local object = component:Get(instance)
```

Returns the attached instance object or nil.

### GetAll

```lua
for _, object in component:GetAll() do
	print(object.Instance)
end
```

Ordering is unspecified.

## Registration and Loading

```lua
Vanguard.AddComponents(folder)
Vanguard.AddComponentsDeep(folder)
```

`LoadComponents` and `LoadComponentsDeep` are aliases. A module may return an existing component or a plain definition containing `Tag`.

Components may be registered after Vanguard starts. When `StartComponents` is enabled, a newly-created component starts immediately.

## Cleanup Pattern

Always put attachment-owned resources in `self.Cleaner`:

```lua
Construct = function(self)
	self.Cleaner:Add(workspace.ChildAdded:Connect(function(child)
		-- Handle child.
	end))

	local highlight = Instance.new("Highlight")
	highlight.Parent = self.Instance
	self.Cleaner:Add(highlight)
end
```

This guarantees disconnection and destruction when the tag disappears.

See [Cleaner](../utilities/cleaner/index.md) for supported task types.
