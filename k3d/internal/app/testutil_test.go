package app

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

func makeTestConfig(t *testing.T) config.Config {
	t.Helper()

	repoRoot := t.TempDir()
	k3dDir := filepath.Join(repoRoot, "k3d")
	environmentDir := filepath.Join(k3dDir, "environments")

	if err := os.MkdirAll(environmentDir, 0o755); err != nil {
		t.Fatalf("os.MkdirAll() error = %v", err)
	}
	if err := os.WriteFile(filepath.Join(k3dDir, "config.env.template"), []byte("# test\n"), 0o644); err != nil {
		t.Fatalf("os.WriteFile() error = %v", err)
	}

	return config.Config{
		Paths: config.Paths{
			K3DDir:         k3dDir,
			RepoRoot:       repoRoot,
			GlobalEnvFile:  filepath.Join(k3dDir, "config.env"),
			EnvironmentDir: environmentDir,
		},
		Global: config.Global{
			BaseDomain:                  "k3ces.localdomain",
			KubeconfigDirectory:         filepath.Join(repoRoot, ".kube"),
			APIStartPort:                6550,
			DefaultNamespace:            "ecosystem",
			LocalRegistryEnabled:        true,
			LocalRegistryStoragePath:    filepath.Join(repoRoot, "registry"),
			LocalRegistryDevName:        "registry-dev.localhost",
			LocalRegistryDevPort:        "5001",
			LocalRegistryProxyName:      "registry-proxy.localhost",
			LocalRegistryProxyPort:      "5002",
			LocalRegistryClusterPort:    "5000",
			LocalRegistryProxyRemoteURL: "https://registry.cloudogu.com",
		},
	}
}

func setupMinimalRepo(t *testing.T) string {
	t.Helper()

	cfg := makeTestConfig(t)
	return cfg.Paths.RepoRoot
}

func prependPath(t *testing.T, dir string) {
	t.Helper()
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
}

func writeExecutable(t *testing.T, dir, name, content string) string {
	t.Helper()

	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte(content), 0o755); err != nil {
		t.Fatalf("os.WriteFile(%q) error = %v", path, err)
	}
	return path
}

func readFile(t *testing.T, path string) string {
	t.Helper()

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("os.ReadFile(%q) error = %v", path, err)
	}
	return string(data)
}
