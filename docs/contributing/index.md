# Contributing to Vanguard

Vanguard grows through focused, reviewable contributions. This guide defines the shared workflow for runtime code, utilities, tests, documentation, and developer tooling.

[View the source repository](https://github.com/TwrblxDevs/vanguard){ .md-button .md-button--primary }

## Where contributions fit

Contributions are welcome in several areas:

| Area | Good first contributions | Coordinate before implementation |
| --- | --- | --- |
| Runtime | Bug fixes, clearer types, lifecycle tests | Public service or controller APIs |
| Networking | Validation tests, documentation, diagnostics | Protocol, authentication, or authorization changes |
| Utilities | Focused helpers, edge-case tests, examples | New modules or broad behavioral changes |
| Documentation | Corrections, examples, migration notes | Navigation or information architecture changes |
| Tooling | Repeatable checks and local workflows | CI, release, or publishing changes |

!!! tip "Start with context"
    Search existing issues and pull requests before starting. For public APIs, security boundaries, Network Protocol 1, or large features, open an issue or discussion first so compatibility and scope can be agreed on early.

## Development setup

### Framework repository

Fork and clone the Vanguard repository, then install the pinned Roblox toolchain and Wally dependencies:

```sh
rokit install
wally install
```

The repository currently pins Rojo, Wally, and Wally Package Types in `rokit.toml`. Install [Lune](https://lune-org.github.io/docs) separately to run the utility test suite.

Run the primary checks from the repository root:

```sh
lune run tests/utilities.luau
rojo build default.project.json --output Vanguard.rbxm
```

### Documentation repository

The documentation is maintained in the separate `vanguard-docs` repository. Install its pinned Python packages and run a local preview:

```sh
py -3.13 -m pip install -r requirements.txt
py -3.13 -m mkdocs serve
```

Before submitting documentation changes, run the strict build:

```sh
py -3.13 -m mkdocs build --strict
```

The strict build treats broken internal links, invalid navigation, and MkDocs warnings as failures.

## Branch naming

Use a short, descriptive branch with a category prefix:

| Prefix | Use |
| --- | --- |
| `feat/` | New user-facing behavior |
| `fix/` | Bug fixes |
| `docs/` | Documentation-only work |
| `refactor/` | Internal restructuring without a behavior change |
| `test/` | Test-only improvements |
| `chore/` | Maintenance and dependency work |

Examples include `feat/class-visibility`, `fix/remote-property-set`, and `docs/network-protocol`.

## Conventional Commits

Every commit should follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
<type>(<scope>)!: <description>
```

The scope is optional. The `!` is required when the commit introduces a breaking change.

### Commit types

| Type | Use |
| --- | --- |
| `feat` | A new feature or public capability |
| `fix` | A user-visible bug fix |
| `docs` | Documentation only |
| `refactor` | Code changes without a feature or fix |
| `perf` | Performance improvements |
| `test` | Tests only |
| `build` | Build system or dependency changes |
| `ci` | Continuous integration changes |
| `chore` | Maintenance that does not fit another type |
| `revert` | Reverts a previous commit |

Use a focused scope when it adds useful context. Common Vanguard scopes include `server`, `client`, `network`, `classes`, `utilities`, `docs`, and `tooling`.

```text
feat(classes): add protected member support
fix(network): reject expired authentication challenges
docs(protocol): clarify request envelope validation
test(cache): cover expiration after overwrite
```

Commit subjects should be imperative, lowercase, concise, and should not end with a period. Describe the reason and important implementation details in the body when the subject cannot carry enough context.

### Breaking changes

Mark a breaking commit with `!` and include a `BREAKING CHANGE:` footer that explains what changed and how users should migrate:

```text
feat(network)!: require authenticated request envelopes

BREAKING CHANGE: Remote requests must include the Protocol 1 authentication
challenge response. See the migration notes for the new client handshake.
```

## Code standards

- Match the surrounding Luau style and existing module boundaries.
- Prefer explicit Luau types for public functions, callbacks, and exported objects.
- Keep public APIs small and document their inputs, outputs, errors, and lifecycle.
- Preserve server authority. Client input is untrusted until validated, authenticated, authorized, and rate limited where appropriate.
- Use Vanguard error codes for actionable failures and add new codes to the [error catalog](../errors/index.md).
- Do not change Network Protocol 1 for an internal refactor. A protocol change is justified only when the serialized wire contract changes.
- Preserve established dot and colon calling behavior where an API supports both forms.
- Add a helper only when it has a clear framework-level use case and cannot be expressed cleanly with an existing utility.

Avoid unrelated formatting or refactoring in the same pull request. Smaller diffs are easier to review, test, and release safely.

## Testing expectations

Testing should follow the behavior being changed:

| Change | Expected verification |
| --- | --- |
| Utility module | Add focused Lune coverage and run `lune run tests/utilities.luau` |
| Runtime module | Exercise lifecycle and failure paths, then complete a Rojo build |
| Networking | Test valid and hostile input, authorization failures, replay behavior, and rate limits |
| Protocol 1 | Update protocol documentation and test compatibility or provide migration coverage |
| Documentation | Run `mkdocs build --strict` and inspect the changed pages on desktop and mobile |

Tests should cover expected behavior, meaningful edge cases, and at least one failure path. A regression fix should include a test that fails without the fix whenever practical.

## Documentation and changelog

User-facing behavior is not complete until users can discover and understand it.

- Update the relevant guide and API reference for new or changed public behavior.
- Include runnable examples for non-obvious APIs.
- Add error codes and recovery guidance to the error catalog.
- Update Network Protocol 1 documentation when any envelope, handshake, validation, or authentication contract changes.
- Add a concise entry to the [changelog](../changelog/index.md) under the appropriate release.
- Add migration guidance for breaking changes.

Roadmap items describe direction, not ownership. Check the [roadmap](../roadmap/index.md) and coordinate with maintainers before taking on a planned release feature.

## Security reports

Do not open a public issue containing exploit instructions, credentials, tokens, private user data, or enough detail to reproduce an unpatched vulnerability.

Use GitHub private vulnerability reporting when it is available. Otherwise, open a minimal issue asking a maintainer to establish a private contact channel without including sensitive details. Security fixes should include a regression test and documentation that is safe to publish after the patch is available.

## Pull request checklist

- [ ] The pull request solves one focused problem and links relevant context.
- [ ] Commits follow Conventional Commits.
- [ ] New public APIs have useful Luau types and documentation.
- [ ] Server authority, validation, authentication, authorization, and rate limits remain intact.
- [ ] Tests cover new behavior and important failure paths.
- [ ] The applicable Lune tests and Rojo build pass.
- [ ] Documentation builds with `mkdocs build --strict`.
- [ ] User-facing changes update the docs and changelog.
- [ ] Breaking changes are marked and include migration guidance.
- [ ] No generated packages, build artifacts, secrets, or unrelated edits are included.

## Review and merge

Reviewers may ask for changes to behavior, tests, naming, types, documentation, or compatibility. Resolve conversations with code or a clear explanation, keep the branch current, and avoid rewriting reviewed sections without calling out the change.

A contribution is ready to merge when required checks pass, review feedback is resolved, documentation matches the implementation, and the release impact is understood. By contributing, you agree that your work may be distributed under Vanguard's MIT License.
