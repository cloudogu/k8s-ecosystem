package main

import (
	"fmt"
	"os"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/app"
)

func main() {
	if _, err := app.Parse(os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
