# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.0, 2026-10-16

- Added `render`, a REST client generated with oapi-codegen from Render's public OpenAPI document (OpenAPI 3.0.2, spec version 1.0.0, 140 paths).
- `make generate` downloads the current spec from api-docs.render.com, patches the references and single-branch unions oapi-codegen can't handle, and regenerates the client. The spec is not committed.
