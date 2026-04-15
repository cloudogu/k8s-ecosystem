package app

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

type App struct {
	config    config.Config
	runner    runner
	envs      *environmentStore
	cluster   *clusterOps
	installer *installerOps
	registry  *registryOps
}

func New() (*App, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, err
	}

	baseRunner := newRunner()
	application := &App{
		config: cfg,
		runner: baseRunner,
		envs:   newEnvironmentStore(cfg),
	}
	application.registry = &registryOps{config: cfg, runner: baseRunner}
	application.cluster = &clusterOps{config: cfg, runner: baseRunner, registry: application.registry}
	application.installer = &installerOps{
		config: cfg,
		runner: baseRunner,
		envs:   application.envs,
	}
	return application, nil
}

func (a *App) List() error {
	instances, err := a.envs.LoadInstances()
	if err != nil {
		return err
	}

	rows := make([][4]string, 0, len(instances))
	for _, instance := range instances {
		status, err := a.cluster.status(instance.Name)
		if err != nil {
			status = "unknown"
		}

		rows = append(rows, [4]string{
			instance.Name,
			status,
			urlFor(instance.FQDN),
			instance.KubeconfigPath,
		})
	}

	printEcosystemTable(os.Stdout, rows)
	return nil
}

func (a *App) Create(name string) error {
	if err := validateName(name); err != nil {
		return err
	}

	envFile := a.envs.EnvFilePath(name)
	if _, err := os.Stat(envFile); err == nil {
		return fmt.Errorf("instance env already exists: %s", envFile)
	}

	exists, err := a.cluster.exists(name)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("k3d cluster %q already exists", name)
	}

	clusters, err := a.cluster.list()
	if err != nil {
		return err
	}

	hostIP, err := nextFreeHostIP(clusters)
	if err != nil {
		return err
	}
	apiPort, err := nextFreeAPIPort(clusters, a.config.Global.APIStartPort)
	if err != nil {
		return err
	}

	fqdn := fmt.Sprintf("%s.%s", name, a.config.Global.BaseDomain)
	kubeconfigPath := filepath.Join(a.config.Global.KubeconfigDirectory, fqdn)
	corednsManifestPath := a.envs.CoreDNSManifestPath(name)

	if err := a.envs.WriteCoreDNSManifest(corednsManifestPath, fqdn); err != nil {
		return err
	}
	if err := a.envs.WriteInstanceEnv(envFile, name, fqdn, hostIP, apiPort, kubeconfigPath, corednsManifestPath); err != nil {
		return err
	}
	if err := a.registry.ensure(); err != nil {
		return err
	}
	if err := a.cluster.createFromEnvFile(envFile); err != nil {
		return err
	}
	if err := a.installer.install(name); err != nil {
		return err
	}

	fmt.Fprintf(os.Stdout, "Ecosystem '%s' is ready.\n\n", name)
	fmt.Fprintf(os.Stdout, "URL:\n  https://%s\n\n", fqdn)
	fmt.Fprintf(os.Stdout, "Dedicated kubeconfig:\n  %s\n\n", kubeconfigPath)
	fmt.Fprintf(os.Stdout, "Apply kubeconfig:\n  export KUBECONFIG=%s\n  kubectl cluster-info\n\n", kubeconfigPath)
	fmt.Fprintf(os.Stdout, "Add to /etc/hosts if needed:\n  sudo sh -c 'echo \"%s %s\" >> /etc/hosts'\n", hostIP, fqdn)
	if a.config.Global.LocalRegistryEnabled {
		fmt.Fprintf(os.Stdout, "\nRegistry stack:\n  push:    localhost:%s\n  consume: k3d-%s:%s\n",
			a.config.Global.LocalRegistryDevPort,
			a.config.Global.LocalRegistryProxyName,
			a.config.Global.LocalRegistryClusterPort,
		)
	}

	return nil
}

func (a *App) Start(name string) error {
	if err := a.registry.ensure(); err != nil {
		return err
	}
	if err := a.runner.Run("k3d", "cluster", "start", name); err != nil {
		return err
	}

	instance, err := a.envs.Find(name)
	if err != nil {
		if os.IsNotExist(err) || strings.Contains(err.Error(), "not found") {
			return nil
		}
		return err
	}

	return a.cluster.writeKubeconfig(name, instance.KubeconfigPath)
}

func (a *App) Stop(name string) error {
	return a.runner.Run("k3d", "cluster", "stop", name)
}

func (a *App) Delete(name string) error {
	envFile := a.envs.EnvFilePath(name)

	instance, err := a.envs.Find(name)
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			return a.runner.Run("k3d", "cluster", "delete", name)
		}
		return err
	}

	clusterExists, err := a.cluster.exists(name)
	if err != nil {
		return err
	}
	if clusterExists {
		if err := a.runner.Run("k3d", "cluster", "delete", name); err != nil {
			return err
		}
	}

	if instance.KubeconfigPath != "" {
		if err := os.Remove(instance.KubeconfigPath); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("remove kubeconfig %s: %w", instance.KubeconfigPath, err)
		}
	}

	corednsManifestPath, err := a.envs.LookupValue(envFile, "K3D_COREDNS_CUSTOM_MANIFEST_PATH")
	if err != nil {
		return err
	}
	if corednsManifestPath != "" {
		if err := a.envs.Remove(corednsManifestPath); err != nil {
			return fmt.Errorf("remove coredns manifest %s: %w", corednsManifestPath, err)
		}
	}
	if err := a.envs.Remove(envFile); err != nil {
		return fmt.Errorf("remove env file %s: %w", envFile, err)
	}

	return nil
}
