package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

type Score struct {
	ent.Schema
}

func (Score) Fields() []ent.Field {
	return []ent.Field{
		field.Time("created_at").
			Default(time.Now),
		field.String("username"),
		field.Int("score"),
	}
}

func (Score) Edges() []ent.Edge {
	return nil
}
