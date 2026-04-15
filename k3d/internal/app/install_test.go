package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestBuildInstallCommand(t *testing.T) {
	t.Run("uses local registry defaults for k3d style setup", func(t *testing.T) {
		home := t.TempDir()
		t.Setenv("HOME", home)

		args, env := buildInstallCommand(map[string]string{
			"DOGU_REGISTRY_USERNAME":      "dogu-user",
			"DOGU_REGISTRY_PASSWORD":      "dogu-pass",
			"HELM_REGISTRY_USERNAME":      "helm-user",
			"HELM_REGISTRY_PASSWORD":      "helm-pass",
			"LOCAL_REGISTRY_ENABLED":      "true",
			"LOCAL_REGISTRY_PROXY_NAME":   "registry-proxy.localhost",
			"LOCAL_REGISTRY_PROXY_PORT":   "5002",
			"LOCAL_REGISTRY_CLUSTER_PORT": "5000",
			"FQDN":                        "dev2.k3ces.localdomain",
		})

		if args[11] != "localhost:5002" {
			t.Fatalf("helm registry host = %q, want localhost:5002", args[11])
		}
		if args[12] != "k3d-registry-proxy.localhost:5000" {
			t.Fatalf("runtime helm registry host = %q", args[12])
		}
		if args[14] != "true" {
			t.Fatalf("helm plain http = %q", args[14])
		}
		assertEnvContains(t, env, "INSTALL_LONGHORN=false")
		assertEnvContains(t, env, "KUBECONFIG_PATH="+filepath.Join(home, ".kube", "dev2.k3ces.localdomain"))
		assertEnvContains(t, env, "CERTIFICATE_CRT_FILE=")
	})

	t.Run("keeps explicit remote registry values when local registry is disabled", func(t *testing.T) {
		args, _ := buildInstallCommand(map[string]string{
			"DOGU_REGISTRY_USERNAME":     "dogu-user",
			"DOGU_REGISTRY_PASSWORD":     "dogu-pass",
			"IMAGE_REGISTRY_USERNAME":    "image-user",
			"IMAGE_REGISTRY_PASSWORD":    "image-pass",
			"HELM_REGISTRY_USERNAME":     "helm-user",
			"HELM_REGISTRY_PASSWORD":     "helm-pass",
			"LOCAL_REGISTRY_ENABLED":     "false",
			"HELM_REGISTRY_HOST":         "registry.example.com",
			"RUNTIME_HELM_REGISTRY_HOST": "runtime.example.com",
			"HELM_REGISTRY_PLAIN_HTTP":   "false",
		})

		if args[11] != "registry.example.com" || args[12] != "runtime.example.com" || args[14] != "false" {
			t.Fatalf("unexpected registry args = %#v", args[11:15])
		}
	})
}

func TestValidateInstallSettings(t *testing.T) {
	t.Run("accepts minimal local registry configuration", func(t *testing.T) {
		home := t.TempDir()
		t.Setenv("HOME", home)
		kubeconfigPath := filepath.Join(home, ".kube", "dev2.k3ces.localdomain")
		if err := os.MkdirAll(filepath.Dir(kubeconfigPath), 0o755); err != nil {
			t.Fatalf("os.MkdirAll() error = %v", err)
		}
		if err := os.WriteFile(kubeconfigPath, []byte("apiVersion: v1"), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		err := validateInstallSettings(map[string]string{
			"DOGU_REGISTRY_USERNAME": "dogu-user",
			"DOGU_REGISTRY_PASSWORD": "dogu-pass",
			"KUBECONFIG_PATH":        kubeconfigPath,
			"LOCAL_REGISTRY_ENABLED": "true",
		})
		if err != nil {
			t.Fatalf("validateInstallSettings() error = %v", err)
		}
	})

	t.Run("requires remote registry credentials when local registry is disabled", func(t *testing.T) {
		home := t.TempDir()
		t.Setenv("HOME", home)
		kubeconfigPath := filepath.Join(home, ".kube", "ctx")
		if err := os.MkdirAll(filepath.Dir(kubeconfigPath), 0o755); err != nil {
			t.Fatalf("os.MkdirAll() error = %v", err)
		}
		if err := os.WriteFile(kubeconfigPath, []byte("apiVersion: v1"), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		err := validateInstallSettings(map[string]string{
			"DOGU_REGISTRY_USERNAME": "dogu-user",
			"DOGU_REGISTRY_PASSWORD": "dogu-pass",
			"KUBECONFIG_PATH":        kubeconfigPath,
			"LOCAL_REGISTRY_ENABLED": "false",
		})
		if err == nil {
			t.Fatal("validateInstallSettings() expected error")
		}
		if !strings.Contains(err.Error(), "IMAGE_REGISTRY_USERNAME") {
			t.Fatalf("unexpected error = %v", err)
		}
	})

	t.Run("returns error when kubeconfig file is missing", func(t *testing.T) {
		home := t.TempDir()
		t.Setenv("HOME", home)

		err := validateInstallSettings(map[string]string{
			"DOGU_REGISTRY_USERNAME": "dogu-user",
			"DOGU_REGISTRY_PASSWORD": "dogu-pass",
			"KUBECONFIG_PATH":        filepath.Join(home, ".kube", "missing"),
		})
		if err == nil {
			t.Fatal("validateInstallSettings() expected error")
		}
		if !strings.Contains(err.Error(), "kubeconfig not found") {
			t.Fatalf("unexpected error = %v", err)
		}
	})
}

func TestMergeEnvValues(t *testing.T) {
	t.Run("later maps override earlier values", func(t *testing.T) {
		merged := mergeEnvValues(
			map[string]string{"A": "1", "B": "1"},
			map[string]string{"B": "2", "C": "3"},
		)

		if merged["A"] != "1" || merged["B"] != "2" || merged["C"] != "3" {
			t.Fatalf("mergeEnvValues() = %#v", merged)
		}
	})
}

func assertEnvContains(t *testing.T, env []string, want string) {
	t.Helper()
	for _, entry := range env {
		if entry == want {
			return
		}
	}
	t.Fatalf("env does not contain %q: %#v", want, env)
}
