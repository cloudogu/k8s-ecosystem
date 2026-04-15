package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseEnvFile(t *testing.T) {
	t.Run("parses values comments exports and home expansion", func(t *testing.T) {
		tempDir := t.TempDir()
		t.Setenv("HOME", tempDir)
		t.Setenv("CUSTOM_VALUE", "from-env")

		path := filepath.Join(tempDir, "test.env")
		content := strings.Join([]string{
			"# comment",
			`export FQDN="dev1.k3ces.localdomain"`,
			`KUBECONFIG_PATH="$HOME/.kube/dev1"`,
			`CUSTOM="$CUSTOM_VALUE"`,
			"INVALID_LINE",
			"",
		}, "\n")
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		values, err := parseEnvFile(path)
		if err != nil {
			t.Fatalf("parseEnvFile() error = %v", err)
		}

		if values["FQDN"] != "dev1.k3ces.localdomain" {
			t.Fatalf("FQDN = %q", values["FQDN"])
		}
		if values["KUBECONFIG_PATH"] != filepath.Join(tempDir, ".kube", "dev1") {
			t.Fatalf("KUBECONFIG_PATH = %q", values["KUBECONFIG_PATH"])
		}
		if values["CUSTOM"] != "from-env" {
			t.Fatalf("CUSTOM = %q", values["CUSTOM"])
		}
	})
}

func TestLoadInstanceFiles(t *testing.T) {
	t.Run("loads and sorts instance env files", func(t *testing.T) {
		tempDir := t.TempDir()

		writeEnv(t, filepath.Join(tempDir, "b.env"), `FQDN="b.k3ces.localdomain"
KUBECONFIG_PATH="/tmp/b"
K3D_HOST_IP="127.0.0.3"
`)
		writeEnv(t, filepath.Join(tempDir, "a.env"), `FQDN="a.k3ces.localdomain"
KUBECONFIG_PATH="/tmp/a"
K3D_HOST_IP="127.0.0.2"
`)

		instances, err := loadInstanceFiles(tempDir)
		if err != nil {
			t.Fatalf("loadInstanceFiles() error = %v", err)
		}
		if len(instances) != 2 {
			t.Fatalf("len(instances) = %d, want 2", len(instances))
		}
		if instances[0].Name != "a" || instances[1].Name != "b" {
			t.Fatalf("instance order = %#v", instances)
		}
	})
}

func TestFindInstanceFile(t *testing.T) {
	t.Run("returns parsed instance file", func(t *testing.T) {
		tempDir := t.TempDir()
		writeEnv(t, filepath.Join(tempDir, "dev1.env"), `FQDN="dev1.k3ces.localdomain"
KUBECONFIG_PATH="/tmp/dev1"
K3D_HOST_IP="127.0.0.2"
`)

		instance, err := findInstanceFile(tempDir, "dev1")
		if err != nil {
			t.Fatalf("findInstanceFile() error = %v", err)
		}
		if instance.Name != "dev1" || instance.FQDN != "dev1.k3ces.localdomain" {
			t.Fatalf("instance = %#v", instance)
		}
	})

	t.Run("returns not found error for missing instance", func(t *testing.T) {
		_, err := findInstanceFile(t.TempDir(), "missing")
		if err == nil {
			t.Fatal("findInstanceFile() expected error")
		}
		if !strings.Contains(err.Error(), `ecosystem "missing" not found`) {
			t.Fatalf("unexpected error = %v", err)
		}
	})
}

func TestFormatInstanceEnv(t *testing.T) {
	t.Run("renders expected fields", func(t *testing.T) {
		out := formatInstanceEnv("dev1", "dev1.k3ces.localdomain", "127.0.0.2", 6550, "/tmp/kubeconfig", "/tmp/coredns.yaml")
		for _, fragment := range []string{
			`K3D_CLUSTER_NAME="dev1"`,
			`K3D_HOST_IP="127.0.0.2"`,
			`K3D_API_PORT="6550"`,
			`FQDN="dev1.k3ces.localdomain"`,
			`KUBECONFIG_PATH="/tmp/kubeconfig"`,
		} {
			if !strings.Contains(out, fragment) {
				t.Fatalf("formatInstanceEnv() output missing %q", fragment)
			}
		}
	})
}

func TestFormatCoreDNSManifest(t *testing.T) {
	t.Run("renders fqdn rewrite", func(t *testing.T) {
		out := formatCoreDNSManifest("dev1.k3ces.localdomain")
		if !strings.Contains(out, "rewrite name exact dev1.k3ces.localdomain") {
			t.Fatalf("formatCoreDNSManifest() output = %q", out)
		}
	})
}

func writeEnv(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("os.WriteFile(%q) error = %v", path, err)
	}
}
