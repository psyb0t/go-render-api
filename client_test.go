package render_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	render "github.com/psyb0t/go-render-api"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	testAuthHeader = "Bearer test-value"
	testServiceID  = "srv-test123"
	testServiceOne = `[{"cursor":"c1","service":` +
		`{"id":"srv-test123","name":"web-a","ownerId":"tea-1"}}]`
	testService = `{"id":"srv-test123","name":"worker-b","ownerId":"tea-2"}`
	testErrBody = `{"id":"unauthorized","message":"invalid key"}`
)

func newTestClient(
	t *testing.T,
	handler http.HandlerFunc,
) *render.ClientWithResponses {
	t.Helper()

	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)

	auth := render.WithRequestEditorFn(
		func(_ context.Context, req *http.Request) error {
			req.Header.Set("Authorization", testAuthHeader)

			return nil
		},
	)

	client, err := render.NewClientWithResponses(server.URL, auth)
	require.NoError(t, err)

	return client
}

func writeJSON(w http.ResponseWriter, status int, body string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write([]byte(body))
}

func TestListServices(t *testing.T) {
	t.Parallel()

	client := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, http.MethodGet, r.Method)
		assert.Equal(t, "/services", r.URL.Path)
		assert.Equal(t, testAuthHeader, r.Header.Get("Authorization"))
		assert.Equal(t, "web-a", r.URL.Query().Get("name"))
		assert.Equal(t, "5", r.URL.Query().Get("limit"))

		writeJSON(w, http.StatusOK, testServiceOne)
	})

	limit := render.LimitParam(5)
	params := &render.ListServicesParams{
		Name:  &render.NameParam{"web-a"},
		Limit: &limit,
	}

	res, err := client.ListServicesWithResponse(t.Context(), params)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, res.StatusCode())
	require.NotNil(t, res.JSON200)
	require.Len(t, *res.JSON200, 1)

	item := (*res.JSON200)[0]
	assert.Equal(t, "c1", item.Cursor)
	assert.Equal(t, testServiceID, item.Service.Id)
	assert.Equal(t, "web-a", item.Service.Name)
	assert.Equal(t, "tea-1", item.Service.OwnerId)
}

func TestRetrieveService(t *testing.T) {
	t.Parallel()

	client := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, http.MethodGet, r.Method)
		assert.Equal(t, "/services/"+testServiceID, r.URL.Path)
		assert.Equal(t, testAuthHeader, r.Header.Get("Authorization"))

		writeJSON(w, http.StatusOK, testService)
	})

	res, err := client.RetrieveServiceWithResponse(t.Context(), testServiceID)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, res.StatusCode())
	require.NotNil(t, res.JSON200)
	assert.Equal(t, testServiceID, res.JSON200.Id)
	assert.Equal(t, "worker-b", res.JSON200.Name)
	assert.Equal(t, "tea-2", res.JSON200.OwnerId)
}

func TestRetrieveServiceUnauthorized(t *testing.T) {
	t.Parallel()

	client := newTestClient(t, func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusUnauthorized, testErrBody)
	})

	res, err := client.RetrieveServiceWithResponse(t.Context(), testServiceID)
	require.NoError(t, err)
	assert.Equal(t, http.StatusUnauthorized, res.StatusCode())
	assert.Nil(t, res.JSON200)
	require.NotNil(t, res.JSON401)
	require.NotNil(t, res.JSON401.Message)
	assert.Equal(t, "invalid key", *res.JSON401.Message)
}
