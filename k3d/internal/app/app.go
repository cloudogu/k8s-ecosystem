package app

import (
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type App struct {
	config config.Config
	runner system.Runner
	envs   EnvironmentStore

	ecosystems EcosystemManager
	cluster    ClusterManager
	registry   RegistryManager
	hosts      HostsManager
	installer  Installer
}

type clusterListEntry struct {
	Name           string `json:"name"`
	ServersRunning int    `json:"serversRunning"`
	Nodes          []struct {
		Role       string `json:"role"`
		ServerOpts struct {
			KubeAPI struct {
				Binding struct {
					HostIP   string `json:"HostIp"`
					HostPort string `json:"HostPort"`
				} `json:"Binding"`
			} `json:"kubeAPI"`
		} `json:"serverOpts"`
	} `json:"nodes"`
}

func New() (*App, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, err
	}

	runner := system.NewRunner()
	envs := newEnvironmentStore(cfg)

	application := &App{
		config: cfg,
		runner: runner,
		envs:   envs,
	}
	application.hosts = newHostsService(cfg, runner)
	application.registry = newRegistryService(cfg, runner, application.hosts)
	application.cluster = newClusterService(cfg, runner, application.registry)
	application.installer = newInstaller(cfg, runner, envs)
	application.ecosystems = newEcosystemService(cfg, runner, envs, application.cluster, application.registry, application.hosts, application.installer)

	return application, nil
}
