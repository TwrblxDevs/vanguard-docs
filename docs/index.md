# Vanguard Documentation

This directory is the complete guide and reference for Vanguard. The root project README is a quick introduction; these documents cover behavior, guarantees, edge cases, and the full public API.

## Start Here

| Guide | What it covers |
| --- | --- |
| [Getting Started](getting-started/index.md) | Installation, project layout, first service, first controller, and bootstrap |
| [Configuration](configuration/index.md) | Every `StartOptions` field and server/client defaults |
| [Lifecycle](lifecycle/index.md) | Registration, init ordering, priorities, start hooks, and `OnStart` |
| [API Reference](api-reference/index.md) | Every method and public field on the main Vanguard module |
| [Type System](type-system/index.md) | Exported Luau types and autocomplete patterns |

## Framework Concepts

| Guide | What it covers |
| --- | --- |
| [Services](services/index.md) | Server-owned systems, client-facing methods, priority, and discovery |
| [Controllers](controllers/index.md) | Client-owned systems and service proxies |
| [Components](components/index.md) | CollectionService-backed behavior and per-instance cleanup |
| [Classes](classes/index.md) | Constructors, inheritance, registries, and runtime checks |
| [Networking](networking/index.md) | Remote functions, signals, properties, client proxies, and protocol checks |
| [Network Security](network-security/index.md) | Validation, authentication, verification, rate limits, and rejection handling |

## Utilities

The [utility index](utilities/index.md) explains when to use each utility.

| Utility | Guide |
| --- | --- |
| Cache | [Cache](utilities/cache/index.md) |
| Class | [Class](classes/index.md) |
| Cleaner | [Cleaner](utilities/cleaner/index.md) |
| Component | [Components](components/index.md) |
| Logger | [Logger](utilities/logger/index.md) |
| NetworkGuard | [NetworkGuard](utilities/network-guard/index.md) |
| Promise | [Promise](utilities/promise/index.md) |
| RateLimiter | [RateLimiter](utilities/rate-limiter/index.md) |
| RemoteProperty | [Networking](networking/index.md#remote-properties) |
| RemoteSignal | [Networking](networking/index.md#remote-signals) |
| Signal | [Signal](utilities/signal/index.md) |
| Validator | [Validator](utilities/validator/index.md) |

## Operations

| Guide | What it covers |
| --- | --- |
| [Troubleshooting](troubleshooting/index.md) | Startup errors, Wally paths, remote failures, and debugging checklists |
| [Migrating from Knit](migration-from-knit/index.md) | Hook aliases, API mapping, and migration differences |

## Documentation Conventions

- `Vanguard.Method(...)` and `Vanguard:Method(...)` are both supported by public methods on the main module.
- Utility objects use normal Lua method conventions. Call instance methods with `:` unless a guide explicitly says otherwise.
- Server examples belong in `ServerScriptService`; client examples belong in `StarterPlayerScripts` or another client container.
- A callback shown as returning `boolean, string?` should return `true` on success or `false, reason` on rejection.
- Ordering described as alphabetical uses the registered object's `Name`.

## Version

These docs describe Vanguard `0.1.13` and network protocol `1`.
