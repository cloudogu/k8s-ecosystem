package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestClusterExistsStatusAndList(t *testing.T) {
	cfg := makeTestConfig(t)
	binDir := t.TempDir()
	prependPath(t, binDir)

	writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "cluster" ] && [ "$2" = "list" ]; then
  if [ "$3" = "-o" ]; then
    printf '[{"name":"all","serversRunning":1}]'
    exit 0
  fi
  case "$3" in
    present)
      printf '[{"name":"present","serversRunning":1}]'
      exit 0
      ;;
    stopped)
      printf '[{"name":"stopped","serversRunning":0}]'
      exit 0
      ;;
    missing)
      exit 1
      ;;
    *)
      printf '[]'
      exit 0
      ;;
  esac
fi
`)

	cluster := &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}}

	t.Run("exists reports present and missing clusters", func(t *testing.T) {
		ok, err := cluster.exists("present")
		if err != nil || !ok {
			t.Fatalf("exists(present) = (%v, %v)", ok, err)
		}

		ok, err = cluster.exists("missing")
		if err != nil || ok {
			t.Fatalf("exists(missing) = (%v, %v)", ok, err)
		}
	})

	t.Run("status maps running stopped and missing clusters", func(t *testing.T) {
		tests := []struct {
			name   string
			input  string
			status string
		}{
			{name: "running", input: "present", status: "running"},
			{name: "stopped", input: "stopped", status: "stopped"},
			{name: "missing", input: "missing", status: "missing"},
		}

		for _, tt := range tests {
			t.Run(tt.name, func(t *testing.T) {
				status, err := cluster.status(tt.input)
				if err != nil {
					t.Fatalf("status(%q) error = %v", tt.input, err)
				}
				if status != tt.status {
					t.Fatalf("status(%q) = %q, want %q", tt.input, status, tt.status)
				}
			})
		}
	})

	t.Run("list returns decoded cluster rows", func(t *testing.T) {
		rows, err := cluster.list()
		if err != nil {
			t.Fatalf("list() error = %v", err)
		}
		if len(rows) != 1 || rows[0].Name != "all" {
			t.Fatalf("list() = %#v", rows)
		}
	})
}

func TestClusterWriteKubeconfig(t *testing.T) {
	cfg := makeTestConfig(t)
	binDir := t.TempDir()
	logPath := filepath.Join(t.TempDir(), "cluster.log")
	prependPath(t, binDir)

	writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "kubeconfig" ] && [ "$2" = "write" ]; then
  output=''
  prev=''
  for arg in "$@"; do
    if [ "$prev" = "--output" ]; then
      output="$arg"
    fi
    prev="$arg"
  done
  printf 'apiVersion: v1\n' > "$output"
  exit 0
fi
`)
	writeExecutable(t, binDir, "kubectl", `#!/bin/sh
if [ "$1" = "--kubeconfig" ] && [ "$3" = "config" ] && [ "$4" = "current-context" ]; then
  printf 'k3d-dev1'
  exit 0
fi
if [ "$1" = "config" ] && [ "$2" = "set-context" ]; then
  printf '%s\n' "$*" >> "`+logPath+`"
  exit 0
fi
exit 0
`)

	cluster := &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}}
	kubeconfigPath := filepath.Join(t.TempDir(), "kube", "dev1")

	t.Run("writes kubeconfig and sets default namespace", func(t *testing.T) {
		if err := cluster.writeKubeconfig("dev1", kubeconfigPath); err != nil {
			t.Fatalf("writeKubeconfig() error = %v", err)
		}

		info, err := os.Stat(kubeconfigPath)
		if err != nil {
			t.Fatalf("os.Stat() error = %v", err)
		}
		if info.Mode().Perm() != 0o600 {
			t.Fatalf("file mode = %#o", info.Mode().Perm())
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "config set-context k3d-dev1 --namespace ecosystem") {
			t.Fatalf("log = %q", out)
		}
	})

	t.Run("rejects empty arguments", func(t *testing.T) {
		err := cluster.writeKubeconfig("", "")
		if err == nil {
			t.Fatal("writeKubeconfig() expected error")
		}
	})
}

func TestClusterCreateFromEnvFile(t *testing.T) {
	t.Run("returns error when cluster name is missing", func(t *testing.T) {
		cfg := makeTestConfig(t)
		cluster := &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}}
		envFile := filepath.Join(t.TempDir(), "missing.env")
		writeEnv(t, envFile, `FQDN="dev1.k3ces.localdomain"`)

		err := cluster.createFromEnvFile(envFile)
		if err == nil || !strings.Contains(err.Error(), "missing K3D_CLUSTER_NAME") {
			t.Fatalf("unexpected error = %v", err)
		}
	})

	t.Run("creates a cluster when local registry is disabled", func(t *testing.T) {
		cfg := makeTestConfig(t)
		cfg.Global.LocalRegistryEnabled = false
		binDir := t.TempDir()
		logPath := filepath.Join(t.TempDir(), "create.log")
		prependPath(t, binDir)

		writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "cluster" ] && [ "$2" = "list" ]; then
  printf '[]'
  exit 0
fi
if [ "$1" = "kubeconfig" ] && [ "$2" = "write" ]; then
  output=''
  prev=''
  for arg in "$@"; do
    if [ "$prev" = "--output" ]; then
      output="$arg"
    fi
    prev="$arg"
  done
  printf 'apiVersion: v1\n' > "$output"
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
`)
		writeExecutable(t, binDir, "kubectl", `#!/bin/sh
if [ "$1" = "--kubeconfig" ] && [ "$3" = "config" ] && [ "$4" = "current-context" ]; then
  printf 'k3d-dev1'
  exit 0
fi
printf '%s\n' "$*" >> "`+logPath+`"
exit 0
`)

		cluster := &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}}
		envFile := filepath.Join(t.TempDir(), "dev1.env")
		kubeconfigPath := filepath.Join(t.TempDir(), "kubeconfig")
		writeEnv(t, envFile, `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
K3D_HOST_IP="127.0.0.2"
K3D_API_PORT="6550"
KUBECONFIG_PATH="`+kubeconfigPath+`"
`)

		if err := cluster.createFromEnvFile(envFile); err != nil {
			t.Fatalf("createFromEnvFile() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "cluster create dev1") || !strings.Contains(out, "--kubeconfig-update-default=false") {
			t.Fatalf("log = %q", out)
		}
		if _, err := os.Stat(kubeconfigPath); err != nil {
			t.Fatalf("os.Stat(%q) error = %v", kubeconfigPath, err)
		}
	})

	t.Run("fails when enabled local proxy registry is not present", func(t *testing.T) {
		cfg := makeTestConfig(t)
		binDir := t.TempDir()
		prependPath(t, binDir)

		writeExecutable(t, binDir, "k3d", `#!/bin/sh
if [ "$1" = "cluster" ] && [ "$2" = "list" ]; then
  printf '[]'
  exit 0
fi
if [ "$1" = "registry" ] && [ "$2" = "list" ]; then
  printf '[]'
  exit 0
fi
`)
		writeExecutable(t, binDir, "kubectl", "#!/bin/sh\nexit 0\n")

		cluster := &clusterOps{config: cfg, runner: newRunner(), registry: &registryOps{config: cfg, runner: newRunner()}}
		envFile := filepath.Join(t.TempDir(), "dev1.env")
		writeEnv(t, envFile, `K3D_CLUSTER_NAME="dev1"
FQDN="dev1.k3ces.localdomain"
`)

		err := cluster.createFromEnvFile(envFile)
		if err == nil || !strings.Contains(err.Error(), `local proxy registry "registry-proxy.localhost" is not running`) {
			t.Fatalf("unexpected error = %v", err)
		}
	})
}
