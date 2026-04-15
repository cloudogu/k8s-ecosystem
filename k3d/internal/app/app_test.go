package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestNew(t *testing.T) {
	repoRoot := setupMinimalRepo(t)
	t.Chdir(repoRoot)

	app, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	if app.envs == nil || app.cluster == nil || app.registry == nil || app.installer == nil {
		t.Fatalf("New() returned incomplete app: %#v", app)
	}
	if app.config.Paths.RepoRoot != repoRoot {
		t.Fatalf("repo root = %q, want %q", app.config.Paths.RepoRoot, repoRoot)
	}
}

func TestAppMethods(t *testing.T) {
	t.Run("List succeeds for empty environment store", func(t *testing.T) {
		cfg := makeTestConfig(t)
		app := &App{
			config:  cfg,
			runner:  newRunner(),
			envs:    newEnvironmentStore(cfg),
			cluster: &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}},
		}

		if err := app.List(); err != nil {
			t.Fatalf("List() error = %v", err)
		}
	})

	t.Run("Create rejects invalid names and existing env files", func(t *testing.T) {
		cfg := makeTestConfig(t)
		app := &App{
			config: cfg,
			envs:   newEnvironmentStore(cfg),
		}

		if err := app.Create("Invalid_Name"); err == nil {
			t.Fatal("Create() expected validation error")
		}

		envFile := app.envs.EnvFilePath("dev1")
		writeEnv(t, envFile, `K3D_CLUSTER_NAME="dev1"`)
		err := app.Create("dev1")
		if err == nil || !strings.Contains(err.Error(), "instance env already exists") {
			t.Fatalf("unexpected error = %v", err)
		}
	})

	t.Run("Start returns nil when env file is missing", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		logPath := filepath.Join(t.TempDir(), "start.log")
		prependPath(t, binDir)

		writeExecutable(t, binDir, "k3d", `#!/bin/sh
printf '%s\n' "$*" >> "`+logPath+`"
if [ "$1" = "registry" ] && [ "$2" = "list" ]; then
  printf '[{"name":"x"}]'
fi
`)
		writeExecutable(t, binDir, "docker", `#!/bin/sh
if [ "$1" = "inspect" ]; then
  printf 'running'
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
`)

		r := newRunner()
		registry := &registryOps{config: cfg, runner: r}
		app := &App{
			config:   cfg,
			runner:   r,
			envs:     newEnvironmentStore(cfg),
			registry: registry,
			cluster:  &clusterOps{config: cfg, runner: r, registry: registry},
		}

		if err := app.Start("dev1"); err != nil {
			t.Fatalf("Start() error = %v", err)
		}

		if out := readFile(t, logPath); !strings.Contains(out, "cluster start dev1") {
			t.Fatalf("log = %q", out)
		}
	})

	t.Run("Stop delegates to k3d cluster stop", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		logPath := filepath.Join(t.TempDir(), "stop.log")
		prependPath(t, binDir)
		writeExecutable(t, binDir, "k3d", "#!/bin/sh\nprintf '%s\\n' \"$*\" >> \""+logPath+"\"\n")

		app := &App{runner: newRunner()}
		if err := app.Stop("dev1"); err != nil {
			t.Fatalf("Stop() error = %v", err)
		}
		if out := readFile(t, logPath); !strings.Contains(out, "cluster stop dev1") {
			t.Fatalf("log = %q", out)
		}
		_ = cfg
	})

	t.Run("Delete removes local files when instance exists", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)

		writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "cluster" ] && [ "$2" = "list" ]; then
  printf '[]'
  exit 0
fi
if [ "$1" = "cluster" ] && [ "$2" = "delete" ]; then
  exit 0
fi
`)

		store := newEnvironmentStore(cfg)
		envFile := store.EnvFilePath("dev1")
		manifestPath := store.CoreDNSManifestPath("dev1")
		kubeconfigPath := filepath.Join(t.TempDir(), "kubeconfig")
		writeEnv(t, envFile, `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="`+kubeconfigPath+`"
K3D_COREDNS_CUSTOM_MANIFEST_PATH="`+manifestPath+`"
`)
		writeEnv(t, manifestPath, "manifest")
		writeEnv(t, kubeconfigPath, "apiVersion: v1")

		app := &App{
			config:  cfg,
			runner:  newRunner(),
			envs:    store,
			cluster: &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}},
		}

		if err := app.Delete("dev1"); err != nil {
			t.Fatalf("Delete() error = %v", err)
		}
		for _, path := range []string{envFile, manifestPath, kubeconfigPath} {
			if _, err := os.Stat(path); !os.IsNotExist(err) {
				t.Fatalf("%s still exists, stat err = %v", path, err)
			}
		}
	})
}
