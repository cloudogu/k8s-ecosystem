package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRegistryEnsureStarted(t *testing.T) {
	cfg := makeTestConfig(t)
	binDir := t.TempDir()
	logPath := filepath.Join(t.TempDir(), "registry.log")
	prependPath(t, binDir)

	writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "registry" ] && [ "$2" = "list" ]; then
  if [ "$3" = "existing" ]; then
    printf '[{"name":"existing"}]'
  else
    printf '[]'
  fi
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
`)
	writeExecutable(t, binDir, "docker", `#!/bin/sh
if [ "$1" = "inspect" ] && [ "$4" = "k3d-existing" ]; then
  printf 'exited'
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
`)

	registry := &registryOps{config: cfg, runner: newRunner()}

	t.Run("creates missing registry", func(t *testing.T) {
		if err := registry.ensureStarted("missing", "5001", "k3d-missing", nil); err != nil {
			t.Fatalf("ensureStarted() error = %v", err)
		}
		out := readFile(t, logPath)
		if !strings.Contains(out, "registry create missing --port 127.0.0.1:5001") {
			t.Fatalf("log = %q", out)
		}
	})

	t.Run("starts existing stopped registry container", func(t *testing.T) {
		if err := os.WriteFile(logPath, nil, 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}
		if err := registry.ensureStarted("existing", "5001", "k3d-existing", nil); err != nil {
			t.Fatalf("ensureStarted() error = %v", err)
		}
		out := readFile(t, logPath)
		if !strings.Contains(out, "start k3d-existing") {
			t.Fatalf("log = %q", out)
		}
	})
}

func TestRegistryEnsure(t *testing.T) {
	t.Run("returns early when local registry is disabled", func(t *testing.T) {
		cfg := makeTestConfig(t)
		cfg.Global.LocalRegistryEnabled = false
		registry := &registryOps{config: cfg, runner: newRunner()}

		if err := registry.ensure(); err != nil {
			t.Fatalf("ensure() error = %v", err)
		}
	})

	t.Run("creates both registries and passes proxy credentials", func(t *testing.T) {
		cfg := makeTestConfig(t)
		cfg.Global.LocalRegistryProxyUsername = "proxy-user"
		cfg.Global.LocalRegistryProxyPassword = "proxy-pass"
		binDir := t.TempDir()
		logPath := filepath.Join(t.TempDir(), "ensure.log")
		prependPath(t, binDir)

		writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "registry" ] && [ "$2" = "list" ]; then
  printf '[]'
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
`)
		writeExecutable(t, binDir, "docker", "#!/bin/sh\nexit 0\n")

		registry := &registryOps{config: cfg, runner: newRunner()}
		if err := registry.ensure(); err != nil {
			t.Fatalf("ensure() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "registry create registry-dev.localhost") {
			t.Fatalf("log missing dev registry create: %q", out)
		}
		if !strings.Contains(out, "--proxy-username proxy-user --proxy-password proxy-pass") {
			t.Fatalf("log missing proxy credentials: %q", out)
		}
	})
}

func TestRegistryHelpers(t *testing.T) {
	cfg := makeTestConfig(t)
	binDir := t.TempDir()
	prependPath(t, binDir)

	writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "registry" ] && [ "$2" = "list" ]; then
  if [ "$3" = "present" ]; then
    printf '[{"name":"present"}]'
    exit 0
  fi
  exit 1
fi
`)
	writeExecutable(t, binDir, "docker", `#!/bin/sh
if [ "$1" = "inspect" ] && [ "$4" = "running-container" ]; then
  printf 'running'
  exit 0
fi
exit 1
`)

	registry := &registryOps{config: cfg, runner: newRunner()}

	t.Run("exists reports presence and missing registries", func(t *testing.T) {
		ok, err := registry.exists("present")
		if err != nil || !ok {
			t.Fatalf("exists(present) = (%v, %v)", ok, err)
		}

		ok, err = registry.exists("missing")
		if err != nil || ok {
			t.Fatalf("exists(missing) = (%v, %v)", ok, err)
		}
	})

	t.Run("containerStatus returns running and tolerates missing containers", func(t *testing.T) {
		status, err := registry.containerStatus("running-container")
		if err != nil || status != "running" {
			t.Fatalf("containerStatus(running-container) = (%q, %v)", status, err)
		}

		status, err = registry.containerStatus("missing-container")
		if err != nil || status != "" {
			t.Fatalf("containerStatus(missing-container) = (%q, %v)", status, err)
		}
	})
}
