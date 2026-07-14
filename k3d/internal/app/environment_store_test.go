package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestEnvironmentStorePaths(t *testing.T) {
	cfg := makeTestConfig(t)
	store := newEnvironmentStore(cfg)

	t.Run("returns derived file paths", func(t *testing.T) {
		if got := store.EnvFilePath("dev1"); got != filepath.Join(cfg.Paths.EnvironmentDir, "dev1.env") {
			t.Fatalf("EnvFilePath() = %q", got)
		}
		if got := store.CoreDNSManifestPath("dev1"); got != filepath.Join(cfg.Paths.EnvironmentDir, "dev1.coredns-custom.yaml") {
			t.Fatalf("CoreDNSManifestPath() = %q", got)
		}
	})
}

func TestEnvironmentStoreWriteAndLoad(t *testing.T) {
	cfg := makeTestConfig(t)
	store := newEnvironmentStore(cfg)
	envPath := store.EnvFilePath("dev1")
	manifestPath := store.CoreDNSManifestPath("dev1")

	t.Run("writes instance env and coredns manifest", func(t *testing.T) {
		if err := store.WriteCoreDNSManifest(manifestPath, "dev1.k3ces.localdomain"); err != nil {
			t.Fatalf("WriteCoreDNSManifest() error = %v", err)
		}
		if err := store.WriteInstanceEnv(envPath, "dev1", "dev1.k3ces.localdomain", "127.0.0.2", 6550, "/tmp/dev1", manifestPath); err != nil {
			t.Fatalf("WriteInstanceEnv() error = %v", err)
		}

		if out := readFile(t, manifestPath); !strings.Contains(out, "dev1.k3ces.localdomain") {
			t.Fatalf("manifest content = %q", out)
		}
		if out := readFile(t, envPath); !strings.Contains(out, `K3D_CLUSTER_NAME="dev1"`) {
			t.Fatalf("env content = %q", out)
		}
	})

	t.Run("loads instances and finds one by name", func(t *testing.T) {
		instances, err := store.LoadInstances()
		if err != nil {
			t.Fatalf("LoadInstances() error = %v", err)
		}
		if len(instances) != 1 || instances[0].Name != "dev1" {
			t.Fatalf("LoadInstances() = %#v", instances)
		}

		instance, err := store.Find("dev1")
		if err != nil {
			t.Fatalf("Find() error = %v", err)
		}
		if instance.FQDN != "dev1.k3ces.localdomain" || instance.HostIP != "127.0.0.2" {
			t.Fatalf("Find() = %#v", instance)
		}
	})

	t.Run("looks up individual values", func(t *testing.T) {
		value, err := store.LookupValue(envPath, "K3D_COREDNS_CUSTOM_MANIFEST_PATH")
		if err != nil {
			t.Fatalf("LookupValue() error = %v", err)
		}
		if value != manifestPath {
			t.Fatalf("LookupValue() = %q", value)
		}
	})
}

func TestEnvironmentStoreRemove(t *testing.T) {
	cfg := makeTestConfig(t)
	store := newEnvironmentStore(cfg)
	path := filepath.Join(cfg.Paths.EnvironmentDir, "remove-me")

	t.Run("removes existing file", func(t *testing.T) {
		if err := os.WriteFile(path, []byte("x"), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}
		if err := store.Remove(path); err != nil {
			t.Fatalf("Remove() error = %v", err)
		}
		if _, err := os.Stat(path); !os.IsNotExist(err) {
			t.Fatalf("file still exists, stat err = %v", err)
		}
	})

	t.Run("ignores missing file", func(t *testing.T) {
		if err := store.Remove(path); err != nil {
			t.Fatalf("Remove() error = %v", err)
		}
	})
}
