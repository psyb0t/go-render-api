package render_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"

	render "github.com/psyb0t/go-render-api"
)

// Example is the README usage, pointed at a local test server instead of
// https://api.render.com/v1 so it runs without network access or a key.
func Example() {
	server := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`[{"cursor":"c1","service":{"name":"web"}}]`))
		},
	))
	defer server.Close()

	auth := render.WithRequestEditorFn(
		func(_ context.Context, req *http.Request) error {
			req.Header.Set(
				"Authorization", "Bearer "+os.Getenv("RENDER_API_KEY"),
			)

			return nil
		},
	)

	client, err := render.NewClientWithResponses(server.URL, auth)
	if err != nil {
		panic(err)
	}

	limit := render.LimitParam(20)

	res, err := client.ListServicesWithResponse(
		context.Background(),
		&render.ListServicesParams{Limit: &limit},
	)
	if err != nil {
		panic(err)
	}

	for _, item := range *res.JSON200 {
		fmt.Println(item.Service.Name)
	}

	// Output: web
}
