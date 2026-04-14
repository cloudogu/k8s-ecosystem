package app

import (
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type installerService struct {
	config config.Config
	runner system.Runner
	envs   EnvironmentStore
}

func newInstaller(cfg config.Config, runner system.Runner, envs EnvironmentStore) Installer {
	return &installerService{
		config: cfg,
		runner: runner,
		envs:   envs,
	}
}

func (s *installerService) Install(name string) error {
	instance, err := s.envs.Find(name)
	if err != nil {
		return err
	}

	return s.runner.RunInDir(s.config.Paths.K3DDir, s.config.Paths.InstallScript, instance.EnvFile)
}
