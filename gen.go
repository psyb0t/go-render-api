// Package render is a Go client for the Render public REST API, generated
// with oapi-codegen from the OpenAPI document Render publishes.
package render

//go:generate bash scripts/fetch-spec.sh
//go:generate bash scripts/patch-spec.sh
//go:generate go tool oapi-codegen --config=config.yaml api/openapi.json
