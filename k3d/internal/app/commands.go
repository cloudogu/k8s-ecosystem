package app

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"runtime"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/output"
)

func (a *App) List() error {
	instances, err := a.ecosystems.List()
	if err != nil {
		return err
	}

	rows := make([][4]string, 0, len(instances))
	for _, instance := range instances {
		rows = append(rows, [4]string{
			instance.Name,
			instance.Status,
			urlFor(instance.FQDN),
			instance.KubeconfigPath,
		})
	}

	output.EcosystemTable(os.Stdout, rows)
	return nil
}

func (a *App) Open(name string) error {
	target, err := a.ecosystems.Open(name)
	if err != nil {
		return err
	}

	var command string
	var commandArgs []string

	switch runtime.GOOS {
	case "darwin":
		command = "open"
		commandArgs = []string{target}
	default:
		command = "xdg-open"
		commandArgs = []string{target}
	}

	if err := a.runner.Run(command, commandArgs...); err != nil {
		return fmt.Errorf("open %s: %w", target, err)
	}

	return nil
}

func (a *App) Doctor() error {
	checks := []struct {
		name string
		err  error
	}{
		{name: "config template", err: requireFile(a.config.Paths.ConfigTemplate)},
		{name: "global config", err: requireFile(a.config.Paths.GlobalEnvFile)},
		{name: "environment dir", err: requireDir(a.config.Paths.EnvironmentDir)},
		{name: "k3d", err: a.runner.LookPath("k3d")},
		{name: "docker", err: a.runner.LookPath("docker")},
		{name: "kubectl", err: a.runner.LookPath("kubectl")},
	}

	hasError := false
	for _, check := range checks {
		status := "ok"
		if check.err != nil {
			status = check.err.Error()
			hasError = true
		}
		fmt.Fprintf(os.Stdout, "%-16s %s\n", check.name+":", status)
	}

	if hasError {
		return errors.New("doctor found issues")
	}
	return nil
}

func (a *App) Version() error {
	payload := map[string]string{
		"cli":        "ces-k3d",
		"repo_root":  a.config.Paths.RepoRoot,
		"k3d_dir":    a.config.Paths.K3DDir,
		"go_version": runtime.Version(),
	}

	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(payload)
}

func (a *App) Install(name string) error {
	return a.installer.Install(name)
}
