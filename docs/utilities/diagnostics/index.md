# Diagnostics

`Vanguard.Util.Diagnostics` is responsible for exposing Roblox provided diagnostics and Vanguard's in a simple to use way. This Util is still in early development. Diagnostics are seperated into categories which are access by functions to keep everything up to date. (Ex: `Diagnostics.Render()`.)

## Render

```lua
local Render = Diagnostics.Render()
```

Returns the current rendering diagnostics.

Returns `RenderDiag`

## RenderDiag

```lua
export type RenderDiag = {
	Frametime: {
		CPU: number,
		GPU: number
	},

	Scene: CountBase,

	Shadows: CountBase,

	UI2D: CountBase,
	UI3D: CountBase,
	
	Physics: {
		Networking: {
			RX: number,
			TX: number
		},

		StepTime: number
	},

	Sync: (self: RenderDiag) -> RenderDiag
}
```

The function `Sync()` updates the information to what is currently
known by Vanguard. Majority of the information in `RenderDiag` is
pulled from `game:GetService("Stats")`. This is used as a more
readable wrapper of all of the useful rendering information
exposed via the Roblox API.


## API Summary

| Function | Signature |
| --- | --- |
| `Render` | `() -> RenderDiag` |
