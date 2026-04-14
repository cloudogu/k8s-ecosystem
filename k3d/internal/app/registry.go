package app

import (
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

type registryOps struct {
	config config.Config
	runner runner
}

func (r *registryOps) ensure() error {
	if !r.config.Global.LocalRegistryEnabled {
		return nil
	}
	if err := os.MkdirAll(r.config.Global.LocalRegistryStoragePath, 0o755); err != nil {
		return err
	}
	if err := r.ensureStarted(r.config.Global.LocalRegistryDevName, r.config.Global.LocalRegistryDevPort, "k3d-"+r.config.Global.LocalRegistryDevName, nil); err != nil {
		return err
	}

	proxyArgs := []string{"--proxy-remote-url", r.config.Global.LocalRegistryProxyRemoteURL}
	if r.config.Global.LocalRegistryProxyUsername != "" {
		proxyArgs = append(proxyArgs, "--proxy-username", r.config.Global.LocalRegistryProxyUsername)
	}
	if r.config.Global.LocalRegistryProxyPassword != "" {
		proxyArgs = append(proxyArgs, "--proxy-password", r.config.Global.LocalRegistryProxyPassword)
	}
	return r.ensureStarted(r.config.Global.LocalRegistryProxyName, r.config.Global.LocalRegistryProxyPort, "k3d-"+r.config.Global.LocalRegistryProxyName, proxyArgs)
}

func (r *registryOps) ensureStarted(name, port, containerName string, extraArgs []string) error {
	exists, err := r.exists(name)
	if err != nil {
		return err
	}
	if exists {
		status, _ := r.containerStatus(containerName)
		if status != "running" {
			return r.runner.Run("docker", "start", containerName)
		}
		return nil
	}

	args := []string{
		"registry", "create", name,
		"--port", "127.0.0.1:" + port,
		"--volume", r.config.Global.LocalRegistryStoragePath + ":/var/lib/registry",
		"--no-help",
	}
	args = append(args, extraArgs...)
	return r.runner.Run("k3d", args...)
}

func (r *registryOps) exists(name string) (bool, error) {
	out, err := r.runner.Output("k3d", "registry", "list", name, "-o", "json")
	if err != nil {
		if strings.Contains(err.Error(), "exit status 1") {
			return false, nil
		}
		return false, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(out, &rows); err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

func (r *registryOps) containerStatus(containerName string) (string, error) {
	out, err := commandOutput(r.runner, "docker", "inspect", "--format", "{{.State.Status}}", containerName)
	if err != nil {
		if exitErr := new(exec.ExitError); errors.As(err, &exitErr) {
			return "", nil
		}
		return "", err
	}
	return strings.TrimSpace(out), nil
}
