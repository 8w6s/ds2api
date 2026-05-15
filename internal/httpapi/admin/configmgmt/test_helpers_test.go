package configmgmt

import (
	"testing"

	"neutronapi/internal/account"
	"neutronapi/internal/config"
)

func newAdminTestHandler(t *testing.T, raw string) *Handler {
	t.Helper()
	t.Setenv("NEUTRON_CONFIG_JSON", raw)
	store := config.LoadStore()
	return &Handler{
		Store: store,
		Pool:  account.NewPool(store),
	}
}
