package client

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"testing"
)

func TestPostJSONWithStatusDoesNotUseFallbackOnFailure(t *testing.T) {
	client := &Client{}
	primary := failingDoer{err: errors.New("primary failed")}
	fallbackDoer := doerFunc(func(req *http.Request) (*http.Response, error) {
		t.Fatal("fallback should not be called")
		return nil, nil
	})

	_, _, err := client.postJSONWithStatus(
		context.Background(),
		primary,
		fallbackDoer,
		"https://example.com/api",
		map[string]string{"x-test": "1"},
		map[string]any{"foo": "bar"},
	)
	if err == nil {
		t.Fatal("expected error from primary doer, got nil")
	}
	if !strings.Contains(err.Error(), "primary failed") {
		t.Fatalf("unexpected error message: %v", err)
	}
}

type doerFunc func(*http.Request) (*http.Response, error)

func (f doerFunc) Do(req *http.Request) (*http.Response, error) {
	return f(req)
}
