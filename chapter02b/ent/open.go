package ent

import (
	"context"

	"github.com/NucleusEngineering/dogcat/chapter02b/ent/db"
	"github.com/NucleusEngineering/dogcat/chapter02b/ent/db/migrate"

	"entgo.io/ent/dialect/sql/schema"
	"github.com/rs/zerolog/log"
)

type entStorage struct {
	*db.Client
}

func Open(ctx context.Context, driverName, connStr string) (*db.Client, error) {
	log := log.With().Str("component", "storage").Logger()
	log.Info().Str("driver", driverName).Msg("Opening connection to database...")
	client, err := db.Open(driverName, connStr)
	if err != nil {
		return nil, err
	}

	// Run the automatic migration tool to create all schema resources.
	log.Info().Msg("Running schema migrations (if required)...")
	err = client.Schema.Create(
		ctx,
		migrate.WithGlobalUniqueID(true), // Well, important to use GraphQL
		schema.WithAtlas(true),
	)
	if err != nil {
		client.Close() // We have to handle close explicitly here
		return nil, err
	}
	return client, nil
}
