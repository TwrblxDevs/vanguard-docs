# Logger

`Vanguard.Util.Logger` provides scoped, level-filtered Roblox output. Vanguard creates a root logger and automatically adds scoped loggers to services, controllers, and components.

## Require and Create

Framework-aware shortcut:

```lua
local logger = Vanguard.CreateLogger("Inventory")
```

This uses the currently configured `LogLevel`.

Direct utility:

```lua
local Logger = require(Vanguard.Util.Logger)
local logger = Logger.new("Inventory", "debug")
```

Default scope is `Vanguard`. Default level is `info`.

## Levels

| Name | Numeric value | Output function |
| --- | ---: | --- |
| `trace` | 1 | `print` |
| `debug` | 2 | `print` |
| `info` | 3 | `print` |
| `warn` | 4 | `warn` |
| `error` | 5 | `warn` |
| `silent` | 6 | No output |

A logger emits messages whose level value is greater than or equal to its configured threshold.

```lua
local logger = Logger.new("Example", "warn")
logger:Info("hidden")
logger:Warn("visible")
logger:Error("visible")
```

## Writing

```lua
logger:Trace("fine detail")
logger:Debug("loaded", count, "records")
logger:Info("ready")
logger:Warn("retrying", attempt)
logger:Error("failed", err)
```

Arguments are converted with `tostring` and joined by one space.

Output format:

```text
[Inventory] [INFO] ready
```

Lowercase aliases are available:

```lua
logger:info("ready")
logger:warn("problem")
```

## SetLevel

```lua
logger:SetLevel("debug")
logger:SetLevel(4)
```

Numeric levels are floored and clamped between `trace` and `silent`.

Unknown string names fall back to `info` rather than erroring.

## GetLevel

```lua
local numericLevel = logger:GetLevel()
```

Returns the normalized numeric value, not the original string.

## IsEnabled

```lua
if logger:IsEnabled("debug") then
	logger:Debug(buildExpensiveDebugMessage())
end
```

Useful when preparing log arguments is expensive. It compares normalized level values to the current threshold.

## Child Scopes

```lua
local requestLogger = logger:ForScope("Request")
requestLogger:Info("started")
```

Output:

```text
[Inventory.Request] [INFO] started
```

The child receives the parent's current numeric level at creation. Later changes to either logger do not propagate to the other.

## Automatic Framework Loggers

- Service scope: service `Name`
- Controller scope: controller `Name`
- Component scope: `Component.<Name>`
- Root scope: `Vanguard`

Provide a `Logger` field in a definition to use a custom logger instead.

## Production Guidance

- Use `debug` for object-by-object startup details.
- Use `info` for major state changes.
- Use `warn` for recoverable failures or rejected operations worth attention.
- Use `error` for failed framework/application operations.
- Use `silent` only when another observability system fully replaces output.
- Avoid logging unbounded client payloads or secrets.

Network rejection logs are throttled separately by Vanguard before they reach the logger.
