package app

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type ecosystemService struct {
	config    config.Config
	runner    system.Runner
	envs      EnvironmentStore
	cluster   ClusterManager
	registry  RegistryManager
	hosts     HostsManager
	installer Installer
}

func newEcosystemService(
	cfg config.Config,
	runner system.Runner,
	envs EnvironmentStore,
	cluster ClusterManager,
	registry RegistryManager,
	hosts HostsManager,
	installer Installer,
) EcosystemManager {
	return &ecosystemService{
		config:    cfg,
		runner:    runner,
		envs:      envs,
		cluster:   cluster,
		registry:  registry,
		hosts:     hosts,
		installer: installer,
	}
}

func (s *ecosystemService) List() ([]EcosystemInfo, error) {
	instances, err := s.envs.LoadInstances()
	if err != nil {
		return nil, err
	}

	result := make([]EcosystemInfo, 0, len(instances))
	for _, instance := range instances {
		status := "missing"
		if clusterExists, err := s.cluster.Exists(instance.Name); err == nil {
			if clusterExists {
				status = "created"
			}
		} else {
			status = "unknown"
		}

		result = append(result, EcosystemInfo{
			Name:           instance.Name,
			FQDN:           instance.FQDN,
			KubeconfigPath: instance.KubeconfigPath,
			Status:         status,
		})
	}

	return result, nil
}

func (s *ecosystemService) Open(name string) (string, error) {
	instance, err := s.envs.Find(name)
	if err != nil {
		return "", err
	}
	return urlFor(instance.FQDN), nil
}

func (s *ecosystemService) Create(name string) error {
	if err := validateName(name); err != nil {
		return err
	}

	envFile := s.envs.EnvFilePath(name)
	if _, err := os.Stat(envFile); err == nil {
		return fmt.Errorf("instance env already exists: %s", envFile)
	}

	exists, err := s.cluster.Exists(name)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("k3d cluster %q already exists", name)
	}

	clusters, err := s.cluster.List()
	if err != nil {
		return err
	}

	hostIP, err := nextFreeHostIP(clusters)
	if err != nil {
		return err
	}
	apiPort, err := nextFreeAPIPort(clusters, s.config.Global.APIStartPort)
	if err != nil {
		return err
	}

	fqdn := fmt.Sprintf("%s.%s", name, s.config.Global.BaseDomain)
	kubeconfigPath := filepath.Join(s.config.Global.KubeconfigDirectory, fqdn)
	corednsManifestPath := s.envs.CoreDNSManifestPath(name)

	if err := s.envs.WriteCoreDNSManifest(corednsManifestPath, fqdn); err != nil {
		return err
	}
	if err := s.envs.WriteInstanceEnv(envFile, name, fqdn, hostIP, apiPort, kubeconfigPath, corednsManifestPath); err != nil {
		return err
	}
	if err := s.registry.Start(); err != nil {
		return err
	}
	if err := s.cluster.CreateFromEnvFile(envFile, true); err != nil {
		return err
	}
	if err := s.installer.Install(name); err != nil {
		return err
	}
	if err := s.hosts.EnsureHostEntry(name, fqdn, hostIP); err != nil {
		return err
	}

	fmt.Fprintf(os.Stdout, "Ecosystem '%s' is ready.\n\n", name)
	fmt.Fprintf(os.Stdout, "URL:\n  https://%s\n\n", fqdn)
	fmt.Fprintf(os.Stdout, "Dedicated kubeconfig:\n  %s\n\n", kubeconfigPath)
	fmt.Fprintf(os.Stdout, "Default kubeconfig:\n  %s (merged: %t)\n\n", s.config.Global.DefaultKubeconfigPath, s.config.Global.MergeDefaultKubeconfig)
	fmt.Fprintf(os.Stdout, "Hosts file:\n  managed automatically: %t\n\n", s.config.Global.ManageHostsFile)
	fmt.Fprintf(os.Stdout, "Registry stack:\n  enabled: %t\n  push:    localhost:%s\n  consume: k3d-%s:%s\n",
		s.config.Global.LocalRegistryEnabled,
		s.config.Global.LocalRegistryDevPort,
		s.config.Global.LocalRegistryProxyName,
		s.config.Global.LocalRegistryClusterPort,
	)

	return nil
}

func (s *ecosystemService) Start(name string) error {
	envFile := s.envs.EnvFilePath(name)

	if err := s.registry.Start(); err != nil {
		return err
	}
	if err := s.runner.Run("k3d", "cluster", "start", name); err != nil {
		return err
	}

	instance, err := s.envs.Find(name)
	if err != nil {
		if os.IsNotExist(err) || strings.Contains(err.Error(), "not found") {
			return nil
		}
		return err
	}

	if err := s.cluster.WriteKubeconfigFromEnvFile(envFile); err != nil {
		return err
	}

	return s.hosts.EnsureHostEntry(name, instance.FQDN, instance.HostIP)
}

func (s *ecosystemService) Stop(name string) error {
	return s.runner.Run("k3d", "cluster", "stop", name)
}

func (s *ecosystemService) Delete(name string) error {
	envFile := s.envs.EnvFilePath(name)

	instance, err := s.envs.Find(name)
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			return s.runner.Run("k3d", "cluster", "delete", name)
		}
		return err
	}

	clusterExists, err := s.cluster.Exists(name)
	if err != nil {
		return err
	}

	if clusterExists {
		if err := s.cluster.DeleteFromEnvFile(envFile); err != nil {
			return err
		}
	} else if instance.KubeconfigPath != "" {
		if err := os.Remove(instance.KubeconfigPath); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("remove kubeconfig %s: %w", instance.KubeconfigPath, err)
		}
	}

	if err := s.hosts.RemoveHostEntry(name, instance.FQDN); err != nil {
		return err
	}

	corednsManifestPath, err := s.envs.LookupValue(envFile, "K3D_COREDNS_CUSTOM_MANIFEST_PATH")
	if err != nil {
		return err
	}
	if corednsManifestPath != "" {
		if err := s.envs.Remove(corednsManifestPath); err != nil {
			return fmt.Errorf("remove coredns manifest %s: %w", corednsManifestPath, err)
		}
	}

	if err := s.envs.Remove(envFile); err != nil {
		return fmt.Errorf("remove env file %s: %w", envFile, err)
	}

	return nil
}

func (a *App) Create(name string) error { return a.ecosystems.Create(name) }
func (a *App) Start(name string) error  { return a.ecosystems.Start(name) }
func (a *App) Stop(name string) error   { return a.ecosystems.Stop(name) }
func (a *App) Delete(name string) error { return a.ecosystems.Delete(name) }
