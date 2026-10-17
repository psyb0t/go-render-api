# go-render-api

[![Go Reference](https://pkg.go.dev/badge/github.com/psyb0t/go-render-api.svg)](https://pkg.go.dev/github.com/psyb0t/go-render-api)
[![CI](https://github.com/psyb0t/go-render-api/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/psyb0t/go-render-api/actions/workflows/pipeline.yml)
[![version](https://raw.githubusercontent.com/psyb0t/go-render-api/badges/version.svg)](https://github.com/psyb0t/go-render-api/tags)
[![license](https://raw.githubusercontent.com/psyb0t/go-render-api/badges/license.svg)](LICENSE)
[![imported by](https://raw.githubusercontent.com/psyb0t/go-render-api/badges/importers.svg)](https://github.com/psyb0t/go-render-api/blob/badges/importers.md)

Unofficial Go client for the [Render API](https://api-docs.render.com), generated from the OpenAPI document Render publishes.

| Directory | Package | API | Generator |
|---|---|---|---|
| repo root | `render` | REST, `https://api.render.com/v1` | [oapi-codegen](https://github.com/oapi-codegen/oapi-codegen) |

`client.gen.go` is generated. Don't edit it by hand, regenerate it.

## Install

```sh
go get github.com/psyb0t/go-render-api
```

## Usage

Every endpoint in the spec has a typed method on `ClientWithResponses`.

```go
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"

	render "github.com/psyb0t/go-render-api"
)

func main() {
	auth := render.WithRequestEditorFn(func(_ context.Context, req *http.Request) error {
		req.Header.Set("Authorization", "Bearer "+os.Getenv("RENDER_API_KEY"))

		return nil
	})

	client, err := render.NewClientWithResponses("https://api.render.com/v1", auth)
	if err != nil {
		panic(err)
	}

	limit := render.LimitParam(20)

	res, err := client.ListServicesWithResponse(context.Background(), &render.ListServicesParams{
		Limit: &limit,
	})
	if err != nil {
		panic(err)
	}

	for _, item := range *res.JSON200 {
		fmt.Println(item.Service.Name)
	}
}
```

`example_test.go` runs the same code against a local test server, so `make test` checks it.

The full API is in the [Go reference](https://pkg.go.dev/github.com/psyb0t/go-render-api); from inside your module, `go doc github.com/psyb0t/go-render-api` prints the same.

## Auth

Render authenticates with a bearer token. Create an API key under Account Settings in the Render Dashboard and send it as `Authorization: Bearer <key>`. The `RequestEditorFn` above adds the header to every request. Pass a different one per call through the trailing `reqEditors` argument if you need to.

## Agent integrations

The [skill](.agents/skills/go-render-api) teaches a coding agent how to use go-render-api when it writes Go. It works in any agent that reads `.agents/skills/`, and installs natively in the clients below.

### Claude Code

```bash
claude plugin marketplace add psyb0t/agents
claude plugin install go-render-api@psyb0t
```

### Codex

```bash
codex plugin marketplace add psyb0t/agents
codex plugin add go-render-api@psyb0t
```

Codex also picks the skill up with no install in any checkout of this repo.

### OpenClaw

The skill is published to ClawHub on every release:

```bash
openclaw skills install @psyb0t/go-render-api
```

## Regenerating

Render's spec is not committed. `make generate` downloads the current OpenAPI document into the gitignored `api/` directory and regenerates the client:

```sh
make generate
```

`gen.go` declares the steps, so `make generate` is just `go generate ./...`:

- `scripts/fetch-spec.sh` downloads `openapi.json`.
- `scripts/patch-spec.sh` makes the spec something oapi-codegen accepts. It inlines every `$ref` that points inside an operation or a schema property instead of at a whole component, and collapses `anyOf`/`oneOf` unions that have a single inline branch. The original references stay valid JSON Schema, oapi-codegen just can't follow them.
- oapi-codegen runs with `config.yaml`.

`.github/workflows/regen.yml` does the same every day in CI. When the new spec changes the client, it runs `make lint`, `make test` and `make sec`. If a check fails, Claude edits the code and the checks run again, up to three times, and a review step reads the result. A passing change is committed with a CHANGELOG entry and tagged as the next release: a patch version for fixes and additions, a minor version for breaking changes.

## Development

Every command runs in the `Dockerfile.dev` image. The host needs only Docker and Make.

```sh
make help      # list targets
make dep       # go mod tidy + vendor
make lint      # shellcheck, shfmt, go fix, golangci-lint
make test      # go test -race
make sec       # gitleaks, govulncheck, semgrep
make generate  # download the spec and regenerate
```

## License

[MIT](LICENSE). The generated code comes from Render's published API specification. The specification itself is not redistributed here. This project is not affiliated with Render.
