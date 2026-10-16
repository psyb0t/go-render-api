---
name: go-render-api
description: Unofficial Go client for the Render public REST API, generated with oapi-codegen. `render.NewClientWithResponses(baseURL, opts...)` from `github.com/psyb0t/go-render-api` returns a `*render.ClientWithResponses` with one typed `<Operation>WithResponse` method per endpoint (services, deploys, env vars, Postgres, Key Value, custom domains, jobs and more). Auth is a bearer API key set through `render.WithRequestEditorFn`; list endpoints page with cursors, and responses decode into `JSON200` and per-status error fields. Use when Go code needs to call the Render API or already imports go-render-api.
homepage: https://github.com/psyb0t/go-render-api
user-invocable: true
metadata:
  openclaw:
    emoji: "☁️"
    requires:
      bins:
        - go
      env:
        - RENDER_API_KEY
permissions:
  filesystem: "Guides edits to the Go source of the current project. The library reads and writes no files."
  shell: "The Go toolchain (`go get`, `go build`, `go test`) to add and compile the dependency."
  network: "HTTPS to the Render API at api.render.com, and `go get` to your Go module proxy."
---

# go-render-api

Typed Go client for the Render API. Every endpoint in Render's OpenAPI document is a method on `ClientWithResponses`.

For install, client options, more operations, paging and response handling, see [references/setup.md](references/setup.md).

## Security & safety

- Read the API key from an environment variable such as `RENDER_API_KEY`. Never hardcode it, commit it or log it, and never print request headers.
- Requests go only to the base URL you pass, `https://api.render.com/v1`.
- Deploy, suspend, scale, update and delete endpoints change live infrastructure. Call them only on services the user named and only when the user asked for that action.

## When to use

- Go code needs to list or inspect Render services, trigger or list deploys, or manage other Render resources.
- The project already imports `github.com/psyb0t/go-render-api`.

## When NOT to use

- A one-off change in the Render Dashboard or with the Render CLI is enough.
- The code is not Go.

## Usage

```go
import (
	"context"
	"fmt"
	"net/http"
	"os"

	render "github.com/psyb0t/go-render-api"
)

auth := render.WithRequestEditorFn(
	func(_ context.Context, req *http.Request) error {
		req.Header.Set(
			"Authorization",
			"Bearer "+os.Getenv("RENDER_API_KEY"),
		)

		return nil
	},
)

client, err := render.NewClientWithResponses(
	"https://api.render.com/v1",
	auth,
)
if err != nil {
	return err
}

limit := render.LimitParam(20)

res, err := client.ListServicesWithResponse(
	ctx,
	&render.ListServicesParams{Limit: &limit},
)
if err != nil {
	return err // transport failure
}

if res.JSON200 == nil {
	return fmt.Errorf("render: status %d", res.StatusCode())
}

for _, item := range *res.JSON200 {
	fmt.Println(item.Service.Id, item.Service.Name, item.Cursor)
}
```

Listing deploys of one service:

```go
deploys, err := client.ListDeploysWithResponse(ctx, serviceID, nil)
if err != nil {
	return err
}

if deploys.JSON200 != nil {
	for _, item := range *deploys.JSON200 {
		if item.Deploy != nil && item.Deploy.Status != nil {
			fmt.Println(item.Deploy.Id, *item.Deploy.Status)
		}
	}
}
```

A method returns an error only when the request could not be sent or the body could not be decoded. An API error is a normal response: check `StatusCode()` and read the matching field, such as `JSON401`, a `*render.Error` with optional `Message`, `Code` and `Id`.
