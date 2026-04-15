package config

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestResolveFrom(t *testing.T) {
	t.Run("resolves repo and k3d paths from repo root", func(t *testing.T) {
		root := t.TempDir()
		k3dDir := filepath.Join(root, "k3d")
		if err := os.MkdirAll(filepath.Join(k3dDir, "environments"), 0o755); err != nil {
			t.Fatalf("os.MkdirAll() error = %v", err)
		}
		if err := os.WriteFile(filepath.Join(k3dDir, "config.env.template"), []byte(""), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		paths, ok := resolveFrom(root)
		if !ok {
			t.Fatal("resolveFrom() = not ok, want ok")
		}
		if paths.K3DDir != k3dDir || paths.RepoRoot != root {
			t.Fatalf("resolveFrom() = %#v", paths)
		}
	})

	t.Run("returns false when no k3d directory exists", func(t *testing.T) {
		_, ok := resolveFrom(t.TempDir())
		if ok {
			t.Fatal("resolveFrom() = ok, want false")
		}
	})
}

func TestParseBoolDefault(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		fallback bool
		want     bool
	}{
		{name: "true literal", input: "true", fallback: false, want: true},
		{name: "yes literal", input: "yes", fallback: false, want: true},
		{name: "false literal", input: "false", fallback: true, want: false},
		{name: "empty uses fallback", input: "", fallback: true, want: true},
		{name: "invalid uses fallback", input: "maybe", fallback: false, want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseBoolDefault(tt.input, tt.fallback)
			if got != tt.want {
				t.Fatalf("parseBoolDefault(%q, %t) = %t, want %t", tt.input, tt.fallback, got, tt.want)
			}
		})
	}
}

func TestParseIntDefault(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		fallback int
		want     int
	}{
		{name: "valid integer", input: "6550", fallback: 1, want: 6550},
		{name: "empty uses fallback", input: "", fallback: 10, want: 10},
		{name: "zero uses fallback", input: "0", fallback: 11, want: 11},
		{name: "invalid uses fallback", input: "abc", fallback: 12, want: 12},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseIntDefault(tt.input, tt.fallback)
			if got != tt.want {
				t.Fatalf("parseIntDefault(%q, %d) = %d, want %d", tt.input, tt.fallback, got, tt.want)
			}
		})
	}
}

func TestDecodeIfBase64(t *testing.T) {
	t.Run("decodes valid base64 strings", func(t *testing.T) {
		encoded := base64.StdEncoding.EncodeToString([]byte("secret"))
		got := decodeIfBase64(encoded)
		if got != "secret" {
			t.Fatalf("decodeIfBase64() = %q, want %q", got, "secret")
		}
	})

	t.Run("returns original value for invalid base64", func(t *testing.T) {
		got := decodeIfBase64("not-base64")
		if got != "not-base64" {
			t.Fatalf("decodeIfBase64() = %q, want original", got)
		}
	})
}

func TestParseOptionalEnvFile(t *testing.T) {
	t.Run("returns empty map for missing file", func(t *testing.T) {
		values, err := parseOptionalEnvFile(filepath.Join(t.TempDir(), "missing.env"))
		if err != nil {
			t.Fatalf("parseOptionalEnvFile() error = %v", err)
		}
		if len(values) != 0 {
			t.Fatalf("parseOptionalEnvFile() = %#v, want empty map", values)
		}
	})
}

func TestParseEnvFile(t *testing.T) {
	t.Run("parses values and expands env vars", func(t *testing.T) {
		tempDir := t.TempDir()
		t.Setenv("HOME", tempDir)
		t.Setenv("CUSTOM_VALUE", "custom")
		path := filepath.Join(tempDir, "config.env")
		content := strings.Join([]string{
			`BASE_DOMAIN="k3ces.localdomain"`,
			`KUBECONFIG_DIRECTORY="$HOME/.kube"`,
			`OTHER="$CUSTOM_VALUE"`,
		}, "\n")
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		values, err := parseEnvFile(path)
		if err != nil {
			t.Fatalf("parseEnvFile() error = %v", err)
		}
		if values["KUBECONFIG_DIRECTORY"] != filepath.Join(tempDir, ".kube") {
			t.Fatalf("KUBECONFIG_DIRECTORY = %q", values["KUBECONFIG_DIRECTORY"])
		}
		if values["OTHER"] != "custom" {
			t.Fatalf("OTHER = %q", values["OTHER"])
		}
	})
}
