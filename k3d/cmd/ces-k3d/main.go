package main

import (
	"fmt"
	"os"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/app"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/cli"
)

func main() {
	application, err := app.New()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	if err := cli.Parse(application, os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
