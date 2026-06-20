# Vanguard Documentation

This directory is the complete guide and reference for Vanguard. The root project README is a quick introduction; these documents cover behavior, guarantees, edge cases, and the full public API.

!!! warning "Developer Notice"
    Vanguard is currently available through [Wally](https://wally.run/package/twrblxdevs/vanguard). The source is available on [GitHub](https://github.com/TwrblxDevs/vanguard).
!!! warning "Developer Notice"
    Vanguard is in early development and receives frequent updates. Check [Wally](https://wally.run/package/twrblxdevs/vanguard) for the newest published version and the [changelog](changelog/index.md) for work in progress.
!!! tip "Developer Workflow"
    Use Rojo and Wally together with Vanguard for the smoothest development experience.

    
## Start Here

| Guide | What it covers |
| --- | --- |
| [Getting Started](getting-started/index.md) | Installation, project layout, first service, first controller, and bootstrap |
| [Configuration](configuration/index.md) | Every `StartOptions` field and server/client defaults |
| [Lifecycle](lifecycle/index.md) | Registration, init ordering, priorities, start hooks, and `OnStart` |
| [API Reference](api-reference/index.md) | Every method and public field on the main Vanguard module |
| [Type System](type-system/index.md) | Exported Luau types and autocomplete patterns |
| [Roadmap](roadmap/index.md) | Next release focus, later initiatives, sequencing, and completion criteria |

## Framework Concepts

| Guide | What it covers |
| --- | --- |
| [Services](services/index.md) | Server-owned systems, client-facing methods, priority, and discovery |
| [Controllers](controllers/index.md) | Client-owned systems and service proxies |
| [Components](components/index.md) | CollectionService-backed behavior and per-instance cleanup |
| [Classes](classes/index.md) | Constructors, inheritance, registries, and runtime checks |
| [Networking](networking/index.md) | Remote functions, signals, properties, client proxies, and protocol checks |
| [Network Security](network-security/index.md) | Validation, authentication, verification, rate limits, and rejection handling |
| [Network Protocol 1](network-protocol/index.md) | Replicated hierarchy, handshake, transport semantics, guards, and compatibility |
| [Errors](errors/index.md) | Stable framework error codes, direct links, causes, and resolutions |

## Utilities

The [utility index](utilities/index.md) explains when to use each utility.

| Utility | Guide |
| --- | --- |
| Cache | [Cache](utilities/cache/index.md) |
| Class | [Class](classes/index.md) |
| Cleaner | [Cleaner](utilities/cleaner/index.md) |
| Diagnostics | [Diagnostics](utilities/diagnostics/index.md) |
| Component | [Components](components/index.md) |
| Logger | [Logger](utilities/logger/index.md) |
| Math | [Math](utilities/math/index.md) |
| NetworkGuard | [NetworkGuard](utilities/network-guard/index.md) |
| Promise | [Promise](utilities/promise/index.md) |
| RateLimiter | [RateLimiter](utilities/rate-limiter/index.md) |
| RemoteProperty | [Networking](networking/index.md#remote-properties) |
| RemoteSignal | [Networking](networking/index.md#remote-signals) |
| Signal | [Signal](utilities/signal/index.md) |
| Switch | [Switch](utilities/switch/index.md) |
| Validator | [Validator](utilities/validator/index.md) |

## Operations

| Guide | What it covers |
| --- | --- |
| [Troubleshooting](troubleshooting/index.md) | Startup errors, Wally paths, remote failures, and debugging checklists |
| [Migrating from Knit](migration-from-knit/index.md) | Hook aliases, API mapping, and migration differences |
| [Roadmap](roadmap/index.md) | Plugin Developer API, Toolbox distribution, utilities, tooling, docs, and contributions |

## What's Next

Vanguard `0.1.15` is planned around a stable **Plugin Developer API** with
versioned manifests, lifecycle hooks, dependency ordering, cleanup ownership,
and linked diagnostics. Later roadmap work includes a Roblox Toolbox release,
additional utilities, expanded documentation, Studio tooling, and a clearer
community contribution process.

Roadmap features are not available until they appear in the
[Changelog](changelog/index.md) as released behavior.

## Documentation Conventions

- `Vanguard.Method(...)` and `Vanguard:Method(...)` are both supported by public methods on the main module.
- Utility objects use normal Lua method conventions. Call instance methods with `:` unless a guide explicitly says otherwise.
- Server examples belong in `ServerScriptService`; client examples belong in `StarterPlayerScripts` or another client container.
- A callback shown as returning `boolean, string?` should return `true` on success or `false, reason` on rejection.
- Ordering described as alphabetical uses the registered object's `Name`.

## Version

These docs describe Vanguard `0.1.14` and network protocol `1`. Vanguard `0.1.15` is the next planned release; see the [Roadmap](roadmap/index.md).
