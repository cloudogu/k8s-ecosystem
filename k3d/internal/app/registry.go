package app

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type registryService struct {
	config config.Config
	runner system.Runner
	hosts  HostsManager
}

func newRegistryService(cfg config.Config, runner system.Runner, hosts HostsManager) RegistryManager {
	return &registryService{
		config: cfg,
		runner: runner,
		hosts:  hosts,
	}
}

func (s *registryService) Start() error {
	if !s.config.Global.LocalRegistryEnabled {
		return nil
	}
	if err := os.MkdirAll(s.config.Global.LocalRegistryStoragePath, 0o755); err != nil {
		return err
	}
	if err := s.ensureRegistryStarted(s.config.Global.LocalRegistryDevName, s.config.Global.LocalRegistryDevPort, "k3d-"+s.config.Global.LocalRegistryDevName, nil); err != nil {
		return err
	}

	proxyArgs := []string{"--proxy-remote-url", s.config.Global.LocalRegistryProxyRemoteURL}
	if s.config.Global.LocalRegistryProxyUsername != "" {
		proxyArgs = append(proxyArgs, "--proxy-username", s.config.Global.LocalRegistryProxyUsername)
	}
	if s.config.Global.LocalRegistryProxyPassword != "" {
		proxyArgs = append(proxyArgs, "--proxy-password", s.config.Global.LocalRegistryProxyPassword)
	}
	if err := s.ensureRegistryStarted(s.config.Global.LocalRegistryProxyName, s.config.Global.LocalRegistryProxyPort, "k3d-"+s.config.Global.LocalRegistryProxyName, proxyArgs); err != nil {
		return err
	}

	return s.hosts.EnsureRegistryEntries()
}

func (s *registryService) Stop() error {
	if !s.config.Global.LocalRegistryEnabled {
		return fmt.Errorf("local registries are disabled")
	}
	_ = s.stopRegistryIfRunning("k3d-" + s.config.Global.LocalRegistryProxyName)
	_ = s.stopRegistryIfRunning("k3d-" + s.config.Global.LocalRegistryDevName)
	return nil
}

func (s *registryService) Delete() error {
	if !s.config.Global.LocalRegistryEnabled {
		return fmt.Errorf("local registries are disabled")
	}
	_ = s.deleteRegistryIfPresent(s.config.Global.LocalRegistryProxyName)
	_ = s.deleteRegistryIfPresent(s.config.Global.LocalRegistryDevName)
	return s.hosts.RemoveRegistryEntries()
}

func (s *registryService) Status() error {
	fmt.Fprintf(os.Stdout, "Local registry stack\n\n")
	fmt.Fprintf(os.Stdout, "Shared storage:\n  %s\n\n", s.config.Global.LocalRegistryStoragePath)
	fmt.Fprintf(os.Stdout, "TYPE   NAME                            STATUS      HOST                    CLUSTER\n")
	if err := s.printRegistryRow("dev", s.config.Global.LocalRegistryDevName, "k3d-"+s.config.Global.LocalRegistryDevName, "localhost:"+s.config.Global.LocalRegistryDevPort, "k3d-"+s.config.Global.LocalRegistryDevName+":"+s.config.Global.LocalRegistryClusterPort); err != nil {
		return err
	}
	if err := s.printRegistryRow("proxy", s.config.Global.LocalRegistryProxyName, "k3d-"+s.config.Global.LocalRegistryProxyName, "localhost:"+s.config.Global.LocalRegistryProxyPort, "k3d-"+s.config.Global.LocalRegistryProxyName+":"+s.config.Global.LocalRegistryClusterPort); err != nil {
		return err
	}
	fmt.Fprintf(os.Stdout, "\nRecommended endpoints:\n  Push local images/charts: localhost:%s\n  Configure CES consumers:  k3d-%s:%s\n",
		s.config.Global.LocalRegistryDevPort,
		s.config.Global.LocalRegistryProxyName,
		s.config.Global.LocalRegistryClusterPort,
	)
	return nil
}

func (s *registryService) ensureRegistryStarted(name, port, containerName string, extraArgs []string) error {
	exists, err := s.Exists(name)
	if err != nil {
		return err
	}
	if exists {
		status, _ := s.registryContainerStatus(containerName)
		if status != "running" {
			return s.runner.Run("docker", "start", containerName)
		}
		return nil
	}

	args := []string{
		"registry", "create", name,
		"--port", "127.0.0.1:" + port,
		"--volume", s.config.Global.LocalRegistryStoragePath + ":/var/lib/registry",
		"--no-help",
	}
	args = append(args, extraArgs...)
	return s.runner.Run("k3d", args...)
}

func (s *registryService) Exists(name string) (bool, error) {
	out, err := s.runner.Output("k3d", "registry", "list", name, "-o", "json")
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

func (s *registryService) registryContainerStatus(containerName string) (string, error) {
	out, err := commandOutput(s.runner, "docker", "inspect", "--format", "{{.State.Status}}", containerName)
	if err != nil {
		if exitErr := new(exec.ExitError); errors.As(err, &exitErr) {
			return "", nil
		}
		return "", err
	}
	return strings.TrimSpace(out), nil
}

func (s *registryService) stopRegistryIfRunning(containerName string) error {
	status, err := s.registryContainerStatus(containerName)
	if err != nil {
		return err
	}
	if status == "running" {
		return s.runner.Run("docker", "stop", containerName)
	}
	return nil
}

func (s *registryService) deleteRegistryIfPresent(name string) error {
	exists, err := s.Exists(name)
	if err != nil {
		return err
	}
	if exists {
		return s.runner.Run("k3d", "registry", "delete", name)
	}
	return nil
}

func (s *registryService) printRegistryRow(kind, name, containerName, hostEndpoint, clusterEndpoint string) error {
	status := "absent"
	exists, err := s.Exists(name)
	if err != nil {
		return err
	}
	if exists {
		status, _ = s.registryContainerStatus(containerName)
		if status == "" {
			status = "created"
		}
	}
	fmt.Fprintf(os.Stdout, "%-6s %-31s %-11s %-23s %s\n", kind, name, status, hostEndpoint, clusterEndpoint)
	return nil
}

func (a *App) RegistryStart() error  { return a.registry.Start() }
func (a *App) RegistryStop() error   { return a.registry.Stop() }
func (a *App) RegistryDelete() error { return a.registry.Delete() }
func (a *App) RegistryStatus() error { return a.registry.Status() }
