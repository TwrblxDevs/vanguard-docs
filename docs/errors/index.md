# Error Reference

Vanguard `0.1.14` gives framework-owned failures stable error codes and direct
links to this page. Codes are designed for search, logging, support, and
long-lived diagnostics even when the surrounding message becomes more precise.

## Error Format

```text
[Vanguard VG-NET-001] Vanguard network protocol mismatch (client 1, server 2)
Docs: https://twrblxdevs.github.io/vanguard-docs/errors/#vg-net-001
```

Every formatted error contains:

| Part | Meaning |
| --- | --- |
| `Vanguard` | Identifies the framework as the source |
| Stable code | Identifies the failure family and documentation anchor |
| Message | Describes the specific object, value, or lifecycle state involved |
| Cause | Preserves a wrapped lower-level failure when one exists |
| Docs URL | Opens the exact catalog entry for the stable code |

Application errors thrown inside your own service methods remain application
errors. Vanguard wraps failures that occur at framework boundaries such as
module discovery, registration, lifecycle dispatch, network setup, and utility
argument validation.

## Error Utility

The utility is available as both `Vanguard.Error` and
`require(Vanguard.Util.Error)`.

```lua
local message = Vanguard.Error.format(
	"VG-CORE-001",
	"Inventory configuration is missing CurrencyName"
)

warn(message)
```

### API

| Method | Returns | Purpose |
| --- | --- | --- |
| `new(code, message?, cause?)` | Error object | Creates structured error metadata without throwing |
| `format(code, message?, cause?)` | `string` | Produces the complete user-facing message and docs link |
| `raise(code, message?, cause?, level?)` | Never normally returns | Throws a formatted Vanguard error |
| `assert(condition, code, message?, level?)` | Original condition | Returns truthy values or throws a formatted error |
| `is(value)` | `boolean` | Checks for a structured Vanguard error object |
| `getDefinition(code)` | Definition or nil | Returns catalog title and summary |
| `getDefinitions()` | Definition map | Returns a cloned catalog for tooling |
| `getDocsUrl(code)` | `string` | Builds the direct documentation URL |
| `getNetworkErrorCode(rejectionCode)` | `string` | Maps a network rejection name to its catalog code |

Unknown codes still format safely and link to a matching lowercase anchor, but
library and game code should prefer registered codes so support guidance exists.

## Core And Lifecycle

### VG-CORE-001: Invalid Framework Usage { #vg-core-001 }

**Meaning:** A Vanguard API received an unsupported type, empty name, invalid
marker, or call shape.

**Common causes:**

- passing a non-table service, controller, class, or options value;
- passing a non-Instance to an `Add*` loader;
- assigning to the read-only `service.Client.Server` field;
- using a utility object after it was cleaned up or destroyed.

**Resolution:** Read the complete message, inspect the value type at the call
site, and compare the call with the relevant API reference. Do not suppress the
assertion: it normally protects a registry or lifecycle invariant.

### VG-CORE-002: Wrong Runtime { #vg-core-002 }

**Meaning:** `VanguardServer` was required on a client or `VanguardClient` was
required on a server.

**Resolution:** Require the package root from shared code:

```lua
local Vanguard = require(ReplicatedStorage.Packages.Vanguard)
```

The root selects the correct runtime module. Do not require
`VanguardServer` or `VanguardClient` directly from game code.

### VG-CONFIG-001: Invalid Configuration { #vg-config-001 }

**Meaning:** A start, bootstrap, or framework configuration value has the wrong
type or an unsupported value.

**Resolution:** Compare the failing field with the
[Configuration reference](../configuration/index.md). Configuration must be
complete before `Start`; later mutation is not supported.

### VG-LIFE-001: Invalid Lifecycle State { #vg-life-001 }

**Meaning:** A lifecycle API was called at the wrong time or a lifecycle hook
threw.

**Common causes:**

- creating a service or controller after `Start`;
- calling `Start` or `Bootstrap` twice;
- calling registry APIs that require startup too early;
- throwing inside `VanguardInit` or `VanguardStart`.

`VanguardInit` failures reject startup. `VanguardStart` hooks are asynchronous;
Vanguard logs their linked failure without reversing completed readiness.

See [Lifecycle](../lifecycle/index.md).

### VG-MODULE-001: Module Discovery Failure { #vg-module-001 }

**Meaning:** A ModuleScript found by an `Add*` loader failed while being
required or registered.

The loader logs the module's full path, preserves the original cause, skips the
failed definition, and continues loading siblings. Startup may continue, but
the skipped object is absent from its registry.

**Resolution:** Fix the first cause associated with this code. Confirm the
module returns exactly one supported definition and that nested requires use
valid package paths.

## Registries And Classes

### VG-REG-001: Duplicate Registration { #vg-reg-001 }

**Meaning:** A different service, controller, component, or class already uses
the requested name.

Re-registering the same object is idempotent where documented. Registering a
different object under the same key is rejected.

**Resolution:** Search definitions and bootstrap scripts for the duplicated
name. Ensure one folder loader and one bootstrap path own registration.

### VG-REG-002: Registration Not Found { #vg-reg-002 }

**Meaning:** A named object was requested but is absent from the current
runtime's registry.

**Common causes:** a spelling mismatch, a skipped module, a server-only object
requested on the client, or a class registered on only one runtime.

**Resolution:** Check startup output for `VG-MODULE-001`, verify runtime scope,
and inspect `GetServices`, `GetControllers`, `GetComponents`, or `GetClasses`.

### VG-CLASS-001: Invalid Class Definition { #vg-class-001 }

**Meaning:** A class name, base class, constructor, grouped member table, or
method receiver is invalid.

**Resolution:** Ensure `Name` is non-empty, `Extends` resolves to a Vanguard
class, constructors are functions, and grouped public methods are called on an
instance. See [Classes](../classes/index.md).

### VG-CLASS-002: Class Member Conflict { #vg-class-002 }

**Meaning:** One member was declared in incompatible locations or used a
Vanguard-reserved name.

Examples include declaring the same key in `Public` and `Static`, using `new`
instead of `Constructor`, or replacing an inherited public member with a static
member.

**Resolution:** Give the member one access category. Put instance API in
`Public`, hidden per-instance implementation in `Private`, and class-only API
in `Static`.

## Networking

### VG-NET-001: Network Protocol Mismatch { #vg-net-001 }

**Meaning:** The client discovered `_VanguardRemotes`, but its
`VanguardProtocol` attribute does not equal the client's protocol.

Vanguard stops before building service proxies because remote hierarchy or
call semantics may be incompatible.

**Resolution:** Install one Vanguard package version for both runtimes, remove
duplicate package copies, restart the play session, and inspect
`Vanguard.GetNetworkInfo()`. See [Network Protocol 1](../network-protocol/index.md).

### VG-NET-002: Remote Discovery Timeout { #vg-net-002 }

**Meaning:** The client did not find `_VanguardRemotes` or a requested service
folder within `RemoteTimeout`.

**Common causes:** server initialization failed, the service exposes no client
remotes, the requested name is wrong, or the timeout is shorter than legitimate
initialization.

**Resolution:** Check server startup first. Increase `RemoteTimeout` only after
confirming the server reaches readiness and publishes the expected service.

### VG-NET-003: Invalid Network Configuration { #vg-net-003 }

**Meaning:** A network option, rule field, rate limiter, or remote declaration
does not match the protocol contract.

**Resolution:** Use only `RateLimit`, `Validate`, `Authenticate`, and `Verify`
inside rules. Named service rules must match a `Client` remote exactly. See
[Network Security](../network-security/index.md).

### VG-NET-101: Request Rate Limited { #vg-net-101 }

Network rejection name: `RATE_LIMITED`.

The Player exhausted the configured rolling-window budget. `RetryAfter` reports
the remaining delay. Inspect duplicated UI connections and request frequency
before increasing limits.

### VG-NET-102: Invalid Request Payload { #vg-net-102 }

Network rejection name: `INVALID_PAYLOAD`.

The request failed its payload validator. Check argument order, tuple length,
shape keys, string or collection limits, finite numeric values, and ranges.

### VG-NET-103: Request Unauthenticated { #vg-net-103 }

Network rejection name: `UNAUTHENTICATED`.

A global or remote authentication callback did not explicitly return `true`.
Authenticate against server-owned profile, session, role, or ban state rather
than client-provided claims.

### VG-NET-104: Request Unverified { #vg-net-104 }

Network rejection name: `UNVERIFIED`.

A global or remote verification callback denied the requested action. Inspect
ownership, permissions, distance, cooldown, inventory, currency, and current
game state.

### VG-NET-105: Network Guard Failure { #vg-net-105 }

Network rejection name: `GUARD_ERROR`.

A limiter, validator, authentication callback, or verification callback threw.
The client receives a generic failure while server logs and `OnRejected` retain
the internal cause.

## Utilities

### VG-MATH-001: Invalid Math Argument { #vg-math-001 }

A Math helper received a non-number, negative epsilon or delta, non-integer
decimal count, or an empty average input. Correct the caller rather than
coercing arbitrary values inside the helper.

### VG-MATH-002: Invalid Math Range { #vg-math-002 }

A range has no positive width, a ping-pong length is not positive, or a snap
increment is zero or negative. Review argument order and domain assumptions.

See [Math](../utilities/math/index.md).

### VG-SWITCH-001: Invalid Switch Definition { #vg-switch-001 }

A switch case collection or direct case map is not a table, or `Cases` received
an empty array. See [Switch](../utilities/switch/index.md).

### VG-UTIL-001: Invalid Utility Usage { #vg-util-001 }

A general utility received invalid options, callbacks, costs, validators, or
post-destroy operations. The specific message names the violated contract; use
the linked utility guide for its valid range and lifecycle.

## Diagnostics

### VG-DIAG-001: Memory tracking disabled { #vg-diag-001 }

A function requiring memory tracking was invoked while memory tracking is 
disabled. This can be fixed by relaunching Roblox with the Micro-Profiler
open.

## Network Rejection Mapping

Remote rejection names remain stable for metrics and application policy. The
error catalog adds documentation without replacing those names.

| Rejection | Error code | Stage |
| --- | --- | --- |
| `RATE_LIMITED` | `VG-NET-101` | Rate limit |
| `INVALID_PAYLOAD` | `VG-NET-102` | Validation |
| `UNAUTHENTICATED` | `VG-NET-103` | Authentication |
| `UNVERIFIED` | `VG-NET-104` | Verification |
| `GUARD_ERROR` | `VG-NET-105` | Guard callback or limiter exception |

Continue with [Troubleshooting](../troubleshooting/index.md) for symptom-based
diagnostics and [Network Protocol 1](../network-protocol/index.md) for transport
behavior.
