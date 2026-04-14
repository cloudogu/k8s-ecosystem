package app

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/envfiles"
)

type environmentStore struct {
	config config.Config
}

func newEnvironmentStore(cfg config.Config) EnvironmentStore {
	return &environmentStore{config: cfg}
}

func (s *environmentStore) LoadInstances() ([]EnvironmentInstance, error) {
	instances, err := envfiles.LoadInstances(s.config.Paths.EnvironmentDir)
	if err != nil {
		return nil, err
	}

	result := make([]EnvironmentInstance, 0, len(instances))
	for _, instance := range instances {
		result = append(result, EnvironmentInstance{
			Name:           instance.Name,
			EnvFile:        instance.EnvFile,
			FQDN:           instance.FQDN,
			KubeconfigPath: instance.KubeconfigPath,
			HostIP:         instance.HostIP,
		})
	}

	return result, nil
}

func (s *environmentStore) Find(name string) (EnvironmentInstance, error) {
	instance, err := envfiles.FindInstance(s.config.Paths.EnvironmentDir, name)
	if err != nil {
		return EnvironmentInstance{}, err
	}

	return EnvironmentInstance{
		Name:           instance.Name,
		EnvFile:        instance.EnvFile,
		FQDN:           instance.FQDN,
		KubeconfigPath: instance.KubeconfigPath,
		HostIP:         instance.HostIP,
	}, nil
}

func (s *environmentStore) EnvFilePath(name string) string {
	return filepath.Join(s.config.Paths.EnvironmentDir, name+".env")
}

func (s *environmentStore) CoreDNSManifestPath(name string) string {
	return filepath.Join(s.config.Paths.EnvironmentDir, name+".coredns-custom.yaml")
}

func (s *environmentStore) WriteCoreDNSManifest(path, fqdn string) error {
	if err := os.WriteFile(path, []byte(envfiles.FormatCoreDNSManifest(fqdn)), 0o644); err != nil {
		return fmt.Errorf("write coredns manifest: %w", err)
	}
	return nil
}

func (s *environmentStore) WriteInstanceEnv(path, name, fqdn, hostIP string, apiPort int, kubeconfigPath, corednsManifestPath string) error {
	if err := os.WriteFile(path, []byte(envfiles.FormatInstanceEnv(name, fqdn, hostIP, apiPort, kubeconfigPath, corednsManifestPath)), 0o644); err != nil {
		return fmt.Errorf("write instance env: %w", err)
	}
	return nil
}

func (s *environmentStore) LookupValue(instanceEnvFile, key string) (string, error) {
	values, err := envfiles.ParseFile(instanceEnvFile)
	if err != nil {
		return "", err
	}
	return values[key], nil
}

func (s *environmentStore) Remove(path string) error {
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}
