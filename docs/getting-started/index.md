# Getting Started

This guide installs Vanguard, creates a server service and client controller, and starts both runtimes.

## Requirements

- Roblox Studio
- A Rojo project
- Wally `0.3.x`
- Vanguard `0.1.13`

Vanguard is dependency-free. Its utility modules are included in the package.

## Install with Wally

Add Vanguard to the game project's `wally.toml`:

```toml
[dependencies]
Vanguard = "twrblxdevs/vanguard@0.1.13"
```

Install dependencies:

```bash
wally install
```

Map the generated `Packages` directory into `ReplicatedStorage`:

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

Prefer a direct require path. It preserves Vanguard's exported Luau types for Studio autocomplete:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)
```

If the package must be awaited, retain its static type explicitly:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Vanguard = require(Packages:WaitForChild("Vanguard") :: ModuleScript)
	:: typeof(require(ReplicatedStorage.Packages.Vanguard))
```

## Recommended Layout

```text
src
  server
    Bootstrapper.server.luau
    Services
      GreetingService.luau
  client
    Bootstrapper.client.luau
    Controllers
      GreetingController.luau
  shared
    Classes
    Components
```

The exact folders are not required. Bootstrap accepts any Instance containing ModuleScripts.

## Create a Service

Create `GreetingService.luau` on the server:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)

local GreetingService = Vanguard.CreateService({
	Name = "GreetingService",

	Client = {
		Greeted = Vanguard.CreateSignal(),
	},
})

function GreetingService.Client:Greet(player, name)
	local message = self.Server:BuildGreeting(name)
	self.Greeted:Fire(player, message)
	return message
end

function GreetingService:BuildGreeting(name)
	return `Hello, {name}!`
end

function GreetingService:VanguardStart()
	self.Logger:Info("Greeting service ready")
end

return GreetingService
```

Anything in `Client` becomes a remote visible through a client service proxy:

- Functions become remote methods.
- `CreateSignal()` becomes a two-way reliable event.
- `CreateUnreliableSignal()` becomes an unreliable event when Roblox supports it.
- `CreateProperty(value)` becomes a server-owned replicated property.

## Start the Server

Create `Bootstrapper.server.luau`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)

Vanguard.Bootstrap({
	Services = script.Parent.Services,
	Options = {
		LogLevel = "info",
	},
}):catch(function(err)
	warn(`Vanguard server failed: {err}`)
end)
```

`Bootstrap` loads every descendant ModuleScript in `Services`, registers valid service definitions, and calls `Start`.

## Create a Controller

Create `GreetingController.luau` on the client:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)

local GreetingController = Vanguard.CreateController({
	Name = "GreetingController",
})

function GreetingController:VanguardStart()
	local GreetingService = Vanguard.GetService("GreetingService")

	GreetingService.Greeted:Connect(function(message)
		self.Logger:Info(message)
	end)

	GreetingService:Greet("Builder"):andThen(function(message)
		self.Logger:Info(`Server returned: {message}`)
	end):catch(function(err)
		self.Logger:Warn(err)
	end)
end

return GreetingController
```

Remote service methods return Vanguard promises by default. Remote signals use `Connect`, `Once`, and `Wait` like local signals.

## Start the Client

Create `Bootstrapper.client.luau`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)

Vanguard.Bootstrap({
	Controllers = script.Parent.Controllers,
	Options = {
		LogLevel = "info",
	},
}):catch(function(err)
	warn(`Vanguard client failed: {err}`)
end)
```

## What Happens During Startup

1. ModuleScripts are required and registered.
2. On the server, remote Instances and network guards are built.
3. `VanguardInit` hooks run and must complete.
4. `VanguardStart` hooks are scheduled.
5. registered components begin watching CollectionService tags.
6. the `Start` or `Bootstrap` promise resolves.

Start hooks are scheduled but not awaited. Use init hooks for work that must finish before the framework becomes ready.

## Next Steps

- Read [Lifecycle](../lifecycle/index.md) before adding dependencies between systems.
- Add server boundary checks using [Network Security](../network-security/index.md).
- Learn the full [Services](../services/index.md) and [Controllers](../controllers/index.md) APIs.
- Use [Components](../components/index.md) for tagged instance behavior.
- Review the [Troubleshooting](../troubleshooting/index.md) checklist when Studio reports a startup error.
