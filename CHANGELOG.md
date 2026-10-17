# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.3, 2026-10-17

- Documentation only. The README and `AGENTS.md` describe the daily regeneration workflow: what it checks, how it fixes failing checks, how it picks the next version and which paths a fix may not touch.

## v0.1.2, 2026-10-17

- Regenerated `render` from Render's OpenAPI document, spec version 1.0.0.
- `ListBlueprintSyncs` and `ListBlueprintSyncsWithResponse` doc comments now say that syncs in the `created` state, planned but not approved, are not included in the returned list.

## v0.1.1, 2026-10-16

- Added the `go-render-api` agent skill. It installs with `claude plugin install go-render-api@psyb0t` in Claude Code, `codex plugin add go-render-api@psyb0t` in Codex and `openclaw skills install @psyb0t/go-render-api` from ClawHub.

## v0.1.0, 2026-10-16

- Added `render`, a REST client generated with oapi-codegen from Render's public OpenAPI document (OpenAPI 3.0.2, spec version 1.0.0, 140 paths).
- `make generate` downloads the current spec from api-docs.render.com, patches the references and single-branch unions oapi-codegen can't handle, and regenerates the client. The spec is not committed.
