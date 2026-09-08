package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func captureOutput(t *testing.T) (*os.File, func() string) {
	t.Helper()
	f, err := os.CreateTemp(t.TempDir(), "stdout-*.txt")
	if err != nil {
		t.Fatalf("os.CreateTemp() error = %v", err)
	}
	return f, func() string {
		if _, err := f.Seek(0, 0); err != nil {
			t.Fatalf("Seek() error = %v", err)
		}
		data, err := os.ReadFile(f.Name())
		if err != nil {
			t.Fatalf("ReadFile() error = %v", err)
		}
		return string(data)
	}
}

func makeConnectOps(t *testing.T, r runner, store *environmentStore) *connectOps {
	t.Helper()
	return &connectOps{runner: r, envs: store}
}

func TestDisconnect(t *testing.T) {
	t.Run("fails when current context is not a managed k3d instance", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
if [ "$1" = "config" ] && [ "$2" = "current-context" ]; then
  printf 'some-other-context'
  exit 0
fi
`)
		ops := makeConnectOps(t, newRunner(), newEnvironmentStore(cfg))
		err := ops.Disconnect()
		if err == nil || !strings.Contains(err.Error(), "not connected to any k3d instance") {
			t.Fatalf("expected 'not connected' error, got: %v", err)
		}
	})

	t.Run("fails when kubectl has no current context", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)
		writeExecutable(t, binDir, "kubectl", "#!/bin/sh\nexit 1\n")
		ops := makeConnectOps(t, newRunner(), newEnvironmentStore(cfg))
		err := ops.Disconnect()
		if err == nil || !strings.Contains(err.Error(), "not connected to any k3d instance") {
			t.Fatalf("expected 'not connected' error, got: %v", err)
		}
	})

	t.Run("removes context entries and unsets current context", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)

		logPath := filepath.Join(t.TempDir(), "kubectl.log")
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
printf '%s\n' "$*" >> "`+logPath+`"
if [ "$1" = "config" ] && [ "$2" = "current-context" ]; then
  printf 'k3d-dev1'; exit 0
fi
if [ "$1" = "config" ] && [ "$2" = "view" ]; then
  if echo "$*" | grep -q "context.cluster"; then printf 'k3d-dev1'; exit 0; fi
  if echo "$*" | grep -q "context.user";    then printf 'admin@k3d-dev1'; exit 0; fi
fi
`)

		store := newEnvironmentStore(cfg)
		writeEnv(t, store.EnvFilePath("dev1"), `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="/tmp/dev1"
`)

		outFile, readOut := captureOutput(t)
		ops := makeConnectOps(t, runner{stdout: outFile, stderr: os.Stderr}, store)

		if err := ops.Disconnect(); err != nil {
			t.Fatalf("Disconnect() error = %v", err)
		}

		log := readFile(t, logPath)
		if !strings.Contains(log, "config delete-context k3d-dev1") {
			t.Errorf("expected 'delete-context k3d-dev1', got: %q", log)
		}
		if !strings.Contains(log, "config delete-cluster k3d-dev1") {
			t.Errorf("expected 'delete-cluster k3d-dev1', got: %q", log)
		}
		if !strings.Contains(log, "config delete-user admin@k3d-dev1") {
			t.Errorf("expected 'delete-user admin@k3d-dev1', got: %q", log)
		}
		if !strings.Contains(log, "config unset current-context") {
			t.Errorf("expected 'unset current-context', got: %q", log)
		}
		if out := readOut(); !strings.Contains(out, "Disconnected from: dev1 (k3d-dev1)") {
			t.Errorf("expected disconnect message, got: %q", out)
		}
	})
}

func TestConnect(t *testing.T) {
	t.Run("connectTo fails when kubeconfig does not exist", func(t *testing.T) {
		cfg := makeTestConfig(t)
		store := newEnvironmentStore(cfg)
		kubeconfigPath := filepath.Join(t.TempDir(), "missing-kubeconfig")
		writeEnv(t, store.EnvFilePath("dev1"), `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="`+kubeconfigPath+`"
`)

		ops := makeConnectOps(t, newRunner(), store)
		err := ops.Connect("dev1")
		if err == nil || !strings.Contains(err.Error(), "has no kubeconfig") {
			t.Fatalf("expected 'has no kubeconfig' error, got: %v", err)
		}
	})

	t.Run("connectTo fails when instance does not exist", func(t *testing.T) {
		cfg := makeTestConfig(t)
		ops := makeConnectOps(t, newRunner(), newEnvironmentStore(cfg))
		err := ops.Connect("nonexistent")
		if err == nil {
			t.Fatal("Connect() expected error for unknown instance")
		}
	})

	t.Run("connectTo merges kubeconfig and switches context", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)

		homeDir := t.TempDir()
		t.Setenv("HOME", homeDir)

		kubeconfigPath := filepath.Join(t.TempDir(), "dev1.k3ces.localdomain")
		writeEnv(t, kubeconfigPath, "apiVersion: v1\nclusters: []\ncontexts: []\ncurrent-context: k3d-dev1\nkind: Config\nusers: []\n")

		logPath := filepath.Join(t.TempDir(), "kubectl.log")
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
printf '%s\n' "$*" >> "`+logPath+`"
if [ "$1" = "config" ] && [ "$2" = "view" ]; then
  printf 'apiVersion: v1\nclusters: []\ncontexts: []\nkind: Config\nusers: []\n'
  exit 0
fi
`)

		store := newEnvironmentStore(cfg)
		writeEnv(t, store.EnvFilePath("dev1"), `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="`+kubeconfigPath+`"
`)

		outFile, readOut := captureOutput(t)
		ops := makeConnectOps(t, runner{stdout: outFile, stderr: os.Stderr}, store)

		if err := ops.Connect("dev1"); err != nil {
			t.Fatalf("Connect() error = %v", err)
		}

		log := readFile(t, logPath)
		if !strings.Contains(log, "config view --flatten") {
			t.Errorf("expected 'config view --flatten' in kubectl calls, got: %q", log)
		}
		if !strings.Contains(log, "config use-context k3d-dev1") {
			t.Errorf("expected 'config use-context k3d-dev1' in kubectl calls, got: %q", log)
		}
		if out := readOut(); !strings.Contains(out, "Connected to: dev1 (k3d-dev1)") {
			t.Errorf("expected success message, got: %q", out)
		}

		mergedPath := filepath.Join(homeDir, ".kube", "config")
		if _, err := os.Stat(mergedPath); os.IsNotExist(err) {
			t.Errorf("expected merged kubeconfig at %s", mergedPath)
		}
	})

	t.Run("showCurrentConnection reports k3d instance when context matches", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
if [ "$1" = "config" ] && [ "$2" = "current-context" ]; then
  printf 'k3d-dev1'
  exit 0
fi
`)

		store := newEnvironmentStore(cfg)
		writeEnv(t, store.EnvFilePath("dev1"), `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="/tmp/dev1"
`)

		outFile, readOut := captureOutput(t)
		ops := makeConnectOps(t, runner{stdout: outFile, stderr: os.Stderr}, store)

		if err := ops.Connect(""); err != nil {
			t.Fatalf("Connect() error = %v", err)
		}
		if out := readOut(); !strings.Contains(out, "Connected to: dev1 (k3d-dev1)") {
			t.Errorf("expected connection message, got: %q", out)
		}
	})

	t.Run("showCurrentConnection reports not connected when context is unmanaged", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
if [ "$1" = "config" ] && [ "$2" = "current-context" ]; then
  printf 'some-other-context'
  exit 0
fi
`)

		outFile, readOut := captureOutput(t)
		ops := makeConnectOps(t, runner{stdout: outFile, stderr: os.Stderr}, newEnvironmentStore(cfg))

		if err := ops.Connect(""); err != nil {
			t.Fatalf("Connect() error = %v", err)
		}
		if out := readOut(); !strings.Contains(out, "Not connected to any k3d instance") {
			t.Errorf("expected not-connected message, got: %q", out)
		}
	})

	t.Run("showCurrentConnection reports not connected when kubectl fails", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)
		writeExecutable(t, binDir, "kubectl", "#!/bin/sh\nexit 1\n")

		outFile, readOut := captureOutput(t)
		ops := makeConnectOps(t, runner{stdout: outFile, stderr: os.Stderr}, newEnvironmentStore(cfg))

		if err := ops.Connect(""); err != nil {
			t.Fatalf("Connect() error = %v", err)
		}
		if out := readOut(); !strings.Contains(out, "Not connected to any k3d instance") {
			t.Errorf("expected not-connected message, got: %q", out)
		}
	})
}
