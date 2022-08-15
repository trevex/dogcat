package ent

import (
	"database/sql"
	"database/sql/driver"
	"fmt"

	"entgo.io/ent/dialect"
	"modernc.org/sqlite"
)

const (
	SQLite                 = dialect.SQLite
	SQLLiteInMemoryConnStr = "file:ent?mode=memory&cache=shared"
)

type sqliteDriver struct {
	*sqlite.Driver
}

func (d sqliteDriver) Open(name string) (driver.Conn, error) {
	conn, err := d.Driver.Open(name)
	if err != nil {
		return conn, err
	}
	c := conn.(interface {
		Exec(stmt string, args []driver.Value) (driver.Result, error)
	})
	if _, err := c.Exec("PRAGMA foreign_keys = on;", nil); err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to enable enable foreign keys: %w", err)
	}
	return conn, nil
}

func init() {
	sql.Register(SQLite, sqliteDriver{Driver: &sqlite.Driver{}})
}
