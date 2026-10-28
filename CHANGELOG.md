# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.4.2, 2026-10-28

- Updated Semgrep in the development image to 1.182.1 and refreshed its locked dependencies. certifi 2026.10.23 drops the emSign root CAs whose intermediate keys were compromised (GHSA-6q48-6c7w-9gw2).
- Dependabot no longer opens pull requests for `mcp` or the OpenTelemetry packages in `requirements-semgrep.txt`. Semgrep pins their versions itself, so bumping one of them on its own cannot install.
- Updated kin-openapi, which the code generator uses, from 0.142.0 to 0.149.0. The newer version fixes several panics on malformed specs reported in GitHub security advisories.
- The security scan merges its two gitleaks runs into one SARIF run. GitHub code scanning rejects a report with two runs from the same tool, so no scan results had been uploaded.

## v0.4.1, 2026-10-27

- The development image is based on Debian (`golang:1.26.10-trixie`) instead of Alpine. Alpine keeps only the latest build of each package, so the exact pins broke the image build whenever a package was updated. System packages now come from the snapshot.debian.org date the base image was built from, which keeps them fixed for a given base image digest. jq 1.8.2, shellcheck 0.11.0 and shfmt 3.13.1 keep their versions, and Semgrep runs in its own virtual environment.

## v0.4.0, 2026-10-27

- Removed the `AuditLogEventCreateArtifactSourceEvent` constant and added `AuditLogEventCreateBuildSourceEvent` (`"CreateBuildSourceEvent"`). `AuditLogEvent.Valid` accepts the new value and rejects `"CreateArtifactSourceEvent"`. Code that names the old constant must change.
- Removed `ServicePATCH.BuildId`. Code that sets it must change. Use `ServicePATCH.BuildSourceId` to link a service to a Build Source.
- Added `Deploy.BuildId`, a `*string` with the ID of the build a deploy shipped. It is only set for deploys of a build from a Build Source.

## v0.3.0, 2026-10-23

- Added the `DiskSnapshotRestored` event type: `EventTypeParamDiskSnapshotRestored`, `ListEventsParamsTypeDiskSnapshotRestored`, `CreateWebhookJSONBodyEventFilterDiskSnapshotRestored` and `CreateWebhook201JSONResponseBodyEventFilterDiskSnapshotRestored`.
- Added a new event details variant with `FromServiceEventWithCursorEventDetails46`, `MergeServiceEventWithCursorEventDetails46` and the matching `FromRetrieveEvent200JSONResponseBodyDetails046`, `MergeRetrieveEvent200JSONResponseBodyDetails046` and `AsRetrieveEvent200JSONResponseBodyDetails046`.
- The new variant is inserted in the middle of the numbered event details types, so the generator renumbers the types after it. `ServiceEventWithCursorEventDetails22` to `46` and `RetrieveEvent200JSONResponseBodyDetails022` to `046` now name different shapes than in v0.2.0. For example `...Details22Status` is now `...Details23Status`, and `...Details29PreDeployStatus` is now `...Details30PreDeployStatus`. Code that names these types or calls their `From` and `As` methods must change.
- Some numbered types switched between a struct and `map[string]interface{}`, for example `ServiceEventWithCursorEventDetails25` and `26`. The `Trigger` field of `...Details27` and `...Details41` changed type, and `...Details41.Trigger` is now a `string`.
- Added fields `InstanceId`, `SnapshotCreatedAt` and `TriggeredByUser` on the disk snapshot event details type, and `DiskId` on the disk event details type.

## v0.2.0, 2026-10-22

- Added `UpdateBlueprintJSONBody.Branch` (and so `UpdateBlueprintJSONRequestBody.Branch`), a `*string` for the Git branch to read the Blueprint file from. It needs Blueprint onboarding early access, and updating it does not plan a sync.
- Added `UpdateBlueprintResponse.JSON400` and `UpdateBlueprintResponse.GetJSON400`. `ParseUpdateBlueprintResponse` now decodes a 400 JSON response into `Error`.
- Changed `UpdateBlueprintResponse.JSON404` and `GetJSON404` from `*N404NotFound` to `*Error`. `ParseUpdateBlueprintResponse` decodes a 404 response into `Error`. Code that uses the old type must change.

## v0.1.6, 2026-10-21

- `ServicePATCH.BuildSourceId` doc comment now says the field cannot be combined with other `serviceDetails` fields except `startCommand`. It also says a native runtime needs a start command and a Docker or image runtime rejects one. No API or behavior change in the client.
- The module now requires Go 1.26.10 in `go.mod` (was 1.26.9), which includes the fix for GO-2026-6809 in `crypto/x509` reported by govulncheck. The development image and the setup reference in the agent skill use the same version.

## v0.1.5, 2026-10-20

- `CreateTaskJSONBody.IdempotencyKey` doc comment now says idempotency keys are scoped to a workflow, not to a single workflow version. No API or behavior change in the client.

## v0.1.4, 2026-10-17

- Documentation only. The agent skill explains how to look up every endpoint, parameter and model with `go doc` or on pkg.go.dev, and declares its license.
- The skill no longer lists the API credentials under OpenClaw's `requires.env`, which kept OpenClaw from loading it until they were set. It requires only `go`; the credentials are still documented as what your program reads.
- The README points to the full API reference, and the examples in the README and the skill were checked against the current code.
- The README example matches `example_test.go` again.

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
