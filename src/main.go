// caddy2 is a custom build of Caddy with third-party modules compiled in.
//
// This is the "xcaddy-style" wrapper: the binary is Caddy's own cmd entry
// point plus blank imports of the plugins we want. Because this module is
// the main module, `go mod vendor` includes everything the build needs.
//
// To add another plugin, add a blank import here and re-run
// ../update-sources.sh to regenerate go.mod/go.sum and the tarballs.
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// Third-party modules:
	_ "github.com/mholt/caddy-ratelimit" // rate_limit directive (http.handlers.rate_limit)
)

func main() {
	caddycmd.Main()
}
