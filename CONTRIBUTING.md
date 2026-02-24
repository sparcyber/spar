# Contributing to Spar

Thanks for your interest in contributing to Spar. This document covers the basics you need to get started.

## Getting Started

1. Fork the repository and clone your fork
2. Create a branch for your work: `git checkout -b feature/your-feature`
3. Make your changes
4. Run tests and linting before committing
5. Open a pull request against `main`

## Before You Start

For anything beyond a small bug fix, **open an issue first** to discuss the approach. This avoids wasted effort if the change doesn't align with the project direction or if someone else is already working on it.

## Development Requirements

- Go 1.22+
- `golangci-lint` for linting
- Access to a Proxmox VE 8+ instance for integration testing (optional but recommended)

## Building

```bash
make build    # Build the binary
make test     # Run tests
make lint     # Run linter
```

## Code Standards

- Run `go fmt` and `golangci-lint` before committing. CI will reject code that doesn't pass.
- All new packages require tests. Aim for meaningful coverage of the core logic, not 100% line coverage of boilerplate.
- Keep the core library in `internal/`. CLI, HTTP, and MCP handlers should be thin wrappers that call into core library functions.
- Error messages should be actionable. "failed to clone VM: template 'win2022-server' not found on node 'pve1'" is good. "clone failed" is not.
- Use `context.Context` for cancellation and timeouts on all Proxmox API calls and long-running operations.

## Commit Messages

Use conventional commit format:

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`

Examples:
- `feat: add VM snapshot support`
- `fix: handle QGA timeout on Windows boot`
- `docs: add OPNsense router configuration example`
- `refactor: extract SDN operations into dedicated package`

Keep the subject line under 72 characters. Use the body for context on *why*, not *what* — the diff shows what changed.

## Pull Requests

- One logical change per PR. Don't bundle unrelated fixes.
- Reference the relevant issue: `Closes #42` or `Relates to #42`.
- Include tests for new functionality.
- Update `CHANGELOG.md` under the `## Unreleased` section.
- PRs require passing CI and at least one review before merge.

## Project Structure

```
cmd/spar/        CLI entrypoint
internal/
  proxmox/       Proxmox API client
  qga/           QEMU Guest Agent operations
  range/         Range config, state, lifecycle
  network/       SDN, bridges, VLANs
  ansible/       Inventory generation, playbook execution
  server/        HTTP server, HTMX handlers
configs/         Example range definitions
templates/       Go HTML templates for the web UI
```

## Reporting Bugs

Open an issue with:
- What you did
- What you expected
- What happened instead
- Spar version (`spar version`)
- Proxmox VE version
- Relevant log output

## Security Issues

If you find a security vulnerability, **do not open a public issue**. Email security@sparcyber.dev instead.

## License

By contributing, you agree that your contributions will be licensed under the AGPLv3 license.
