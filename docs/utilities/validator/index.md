# Validator

`Vanguard.Util.Validator` builds composable runtime validators. It is designed for untrusted network payloads and application data that must be checked before use.

## Require

```lua
local Validator = require(Vanguard.Util.Validator)
type Validator = Validator.Validator
```

A validator returns:

```lua
true
```

or:

```lua
false, "reason"
```

Callbacks must explicitly return true to pass.

## Safe Invocation

```lua
local valid, message = Validator.validate(validator, value, "item")
```

`Validator.validate` catches validator errors and converts them into `false, message`.

Composite validators also safely invoke their child validators.

Calling a primitive/custom validator directly does not add a new outer `pcall`; use `validate` when arbitrary custom validators may throw.

## any

```lua
local anyValue = Validator.any()
```

Always returns true, including for nil.

Use sparingly at network boundaries.

## type

```lua
local tableValue = Validator.type("table")
```

Uses Lua `type` and reports expected/actual types.

Common names: `nil`, `boolean`, `number`, `string`, `function`, `thread`, `table`, and `userdata`.

## robloxType

```lua
local vector = Validator.robloxType("Vector3")
```

Uses Roblox `typeof` for values such as `Vector3`, `CFrame`, `Color3`, `Instance`, and `EnumItem`.

## string

```lua
local itemId = Validator.string({
	MinLength = 1,
	MaxLength = 64,
	Pattern = "^[%w_%-]+$",
})
```

Options:

- `MinLength`: minimum byte length;
- `MaxLength`: maximum byte length;
- `Pattern`: Lua pattern that must match.

Length uses Lua `#`, which counts bytes rather than Unicode graphemes. Apply domain-specific Unicode rules separately when user-facing text requires them.

Invalid Lua patterns throw during validation; network guards convert the throw to `GUARD_ERROR`. Test patterns when constructing schemas.

## number

```lua
local price = Validator.number({
	Min = 0,
	Max = 1_000_000,
})
```

NaN and positive/negative infinity are rejected by default.

Allow non-finite values only explicitly:

```lua
Validator.number({ Finite = false })
```

Network gameplay values should almost always remain finite.

## integer

```lua
local slot = Validator.integer({ Min = 1, Max = 10 })
```

Runs number checks and then requires `value % 1 == 0`.

## boolean

```lua
local enabled = Validator.boolean()
```

Equivalent to `Validator.type("boolean")`.

## literal

```lua
local action = Validator.literal("Equip")
```

Requires equality with the provided value. Tables compare by identity.

## optional and nullable

```lua
local optionalName = Validator.optional(Validator.string({ MaxLength = 32 }))
```

Passes nil; otherwise runs the child validator.

`Validator.nullable` is an alias.

## oneOf

```lua
local identifier = Validator.oneOf(
	Validator.string({ MinLength = 1 }),
	Validator.integer({ Min = 1 })
)
```

Passes when any child passes. Failure reports a generic â€œdid not match any allowed shapeâ€ message rather than every child reason.

## array

```lua
local itemIds = Validator.array(
	Validator.string({ MinLength = 1, MaxLength = 64 }),
	{
		MinLength = 1,
		MaxLength = 20,
	}
)
```

Requires:

- a table;
- sequential integer keys from 1 through length;
- no string or out-of-range keys;
- no gaps;
- every item to pass the child validator;
- optional length bounds.

This rejects mixed array/map payloads.

## map

```lua
local quantities = Validator.map(
	Validator.string({ MinLength = 1, MaxLength = 64 }),
	Validator.integer({ Min = 0, Max = 999 })
)
```

Validates every key and value in a table. Map does not enforce a maximum entry count; add a custom wrapper when untrusted maps need size limits.

## shape

```lua
local item = Validator.shape({
	Id = Validator.string({ MinLength = 1, MaxLength = 64 }),
	Count = Validator.integer({ Min = 0, Max = 999 }),
	Equipped = Validator.optional(Validator.boolean()),
})
```

By default, unknown keys are rejected. Missing fields are passed as nil to their validators, so wrap optional fields with `Validator.optional`.

Allow extra fields explicitly:

```lua
Validator.shape(schema, { AllowExtra = true })
```

Strict shapes are recommended for network payloads.

## instance

```lua
local partInMap = Validator.instance("BasePart", workspace.Map)
```

Checks:

- value has Roblox type `Instance`;
- optional `IsA(className)` condition;
- optional equality/descendancy under `ancestor`.

Do not accept arbitrary client-supplied Instances merely because they pass a class check. Verify that the Instance represents an action the Player may perform.

## custom

```lua
local evenNumber = Validator.custom(function(value)
	return type(value) == "number" and value % 2 == 0
end, "value must be even")
```

The callback receives the value and may return `true` or `false, message`. The explicit callback message wins, then the default message, then the generated path message.

## tuple

```lua
local purchasePayload = Validator.tuple(
	Validator.string({ MinLength = 1, MaxLength = 64 }),
	Validator.integer({ Min = 1, Max = 10 }),
	Validator.optional(Validator.string({ MaxLength = 32 }))
)
```

Tuple validates function arguments rather than one value.

Behavior:

- each configured validator receives its positional argument;
- missing positions receive nil;
- optional validators allow missing arguments;
- extra arguments beyond the configured validator count reject;
- errors identify `argument N`.

Use tuple directly as a network rule:

```lua
Network = {
	Purchase = {
		Validate = purchasePayload,
	},
}
```

## Nested Schema Example

```lua
local loadout = Validator.shape({
	Name = Validator.string({ MinLength = 1, MaxLength = 32 }),
	Slots = Validator.array(
		Validator.shape({
			ItemId = Validator.string({ MinLength = 1, MaxLength = 64 }),
			Skin = Validator.optional(Validator.string({ MaxLength = 64 })),
		}),
		{ MaxLength = 10 }
	),
})
```

Errors include nested paths such as `value.Slots[2].ItemId`.

## Security Guidance

- Bound every untrusted string and collection.
- Prefer strict shapes.
- Reject unexpected tuple arguments.
- Keep numbers finite and range-limited.
- Validate data shape before authentication/verification does expensive work.
- Validation does not prove ownership, permission, freshness, or authenticity.
- Re-check authoritative state in verification and mutation logic.
