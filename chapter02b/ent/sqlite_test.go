package ent

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSQLite(t *testing.T) {
	ctx := context.Background()
	client, err := Open(ctx, SQLite, SQLLiteInMemoryConnStr)
	require.NoError(t, err)
	require.NoError(t, client.Close())
}
