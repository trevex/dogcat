package web

import (
	"embed"
	"io/fs"
)

//go:embed dist
//go:embed dist/_next
//go:embed dist/_next/static/chunks/pages/*.js
//go:embed dist/_next/static/*/*.js
var distFS embed.FS

func FS() (fs.FS, error) {
	return fs.Sub(distFS, "dist")
}
