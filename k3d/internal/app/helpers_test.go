package app

import (
	"bytes"
	"strconv"
	"strings"
	"testing"
)

func TestValidateName(t *testing.T) {
	t.Run("accepts valid names", func(t *testing.T) {
		validNames := []string{"dev1", "my-ces", "a1", "test-123"}

		for _, name := range validNames {
			t.Run(name, func(t *testing.T) {
				if err := validateName(name); err != nil {
					t.Fatalf("validateName(%q) returned error: %v", name, err)
				}
			})
		}
	})

	t.Run("rejects invalid names", func(t *testing.T) {
		tests := []struct {
			name        string
			input       string
			errContains string
		}{
			{name: "empty", input: "", errContains: "must not be empty"},
			{name: "leading dash", input: "-dev1", errContains: "must start with a letter or digit"},
			{name: "uppercase", input: "Dev1", errContains: "invalid ecosystem name"},
			{name: "underscore", input: "dev_1", errContains: "invalid ecosystem name"},
		}

		for _, tt := range tests {
			t.Run(tt.name, func(t *testing.T) {
				err := validateName(tt.input)
				if err == nil {
					t.Fatalf("validateName(%q) expected error", tt.input)
				}
				if !strings.Contains(err.Error(), tt.errContains) {
					t.Fatalf("validateName(%q) error %q does not contain %q", tt.input, err.Error(), tt.errContains)
				}
			})
		}
	})
}

func TestNextFreeHostIP(t *testing.T) {
	t.Run("returns first free loopback host ip", func(t *testing.T) {
		clusters := []clusterListEntry{
			makeClusterEntry("127.0.0.2", "6550"),
			makeClusterEntry("127.0.0.3", "6551"),
		}

		got, err := nextFreeHostIP(clusters)
		if err != nil {
			t.Fatalf("nextFreeHostIP() returned error: %v", err)
		}
		if got != "127.0.0.4" {
			t.Fatalf("nextFreeHostIP() = %q, want %q", got, "127.0.0.4")
		}
	})

	t.Run("ignores non server nodes", func(t *testing.T) {
		cluster := clusterListEntry{}
		cluster.Nodes = []struct {
			Role       string `json:"role"`
			ServerOpts struct {
				KubeAPI struct {
					Binding struct {
						HostIP   string `json:"HostIp"`
						HostPort string `json:"HostPort"`
					} `json:"Binding"`
				} `json:"kubeAPI"`
			} `json:"serverOpts"`
		}{
			{Role: "agent"},
		}

		got, err := nextFreeHostIP([]clusterListEntry{cluster})
		if err != nil {
			t.Fatalf("nextFreeHostIP() returned error: %v", err)
		}
		if got != "127.0.0.2" {
			t.Fatalf("nextFreeHostIP() = %q, want %q", got, "127.0.0.2")
		}
	})

	t.Run("returns error when no free host ip exists", func(t *testing.T) {
		clusters := make([]clusterListEntry, 0, 253)
		for octet := 2; octet <= 254; octet++ {
			clusters = append(clusters, makeClusterEntry("127.0.0."+strconv.Itoa(octet), ""))
		}

		_, err := nextFreeHostIP(clusters)
		if err == nil {
			t.Fatal("nextFreeHostIP() expected error")
		}
	})
}

func TestNextFreeAPIPort(t *testing.T) {
	t.Run("returns first free api port", func(t *testing.T) {
		clusters := []clusterListEntry{
			makeClusterEntry("127.0.0.2", "6550"),
			makeClusterEntry("127.0.0.3", "6551"),
		}

		got, err := nextFreeAPIPort(clusters, 6550)
		if err != nil {
			t.Fatalf("nextFreeAPIPort() returned error: %v", err)
		}
		if got != 6552 {
			t.Fatalf("nextFreeAPIPort() = %d, want %d", got, 6552)
		}
	})

	t.Run("returns error when no free api port exists", func(t *testing.T) {
		clusters := make([]clusterListEntry, 0, 450)
		for port := 6550; port <= 6999; port++ {
			clusters = append(clusters, makeClusterEntry("", strconv.Itoa(port)))
		}

		_, err := nextFreeAPIPort(clusters, 6550)
		if err == nil {
			t.Fatal("nextFreeAPIPort() expected error")
		}
	})
}

func TestFirstNonEmpty(t *testing.T) {
	t.Run("returns first non empty trimmed value", func(t *testing.T) {
		got := firstNonEmpty("", "   ", "value", "other")
		if got != "value" {
			t.Fatalf("firstNonEmpty() = %q, want %q", got, "value")
		}
	})

	t.Run("returns empty string when all values are empty", func(t *testing.T) {
		got := firstNonEmpty("", " ", "\t")
		if got != "" {
			t.Fatalf("firstNonEmpty() = %q, want empty string", got)
		}
	})
}

func TestPrintEcosystemTable(t *testing.T) {
	t.Run("prints header and rows", func(t *testing.T) {
		var buf bytes.Buffer

		printEcosystemTable(&buf, [][4]string{
			{"dev1", "running", "https://dev1.example", "/tmp/kubeconfig"},
		})

		out := buf.String()
		for _, fragment := range []string{"NAME", "STATUS", "URL", "KUBECONFIG", "dev1", "running", "https://dev1.example", "/tmp/kubeconfig"} {
			if !strings.Contains(out, fragment) {
				t.Fatalf("printEcosystemTable() output missing %q in %q", fragment, out)
			}
		}
	})
}

func makeClusterEntry(hostIP, hostPort string) clusterListEntry {
	entry := clusterListEntry{}
	node := struct {
		Role       string `json:"role"`
		ServerOpts struct {
			KubeAPI struct {
				Binding struct {
					HostIP   string `json:"HostIp"`
					HostPort string `json:"HostPort"`
				} `json:"Binding"`
			} `json:"kubeAPI"`
		} `json:"serverOpts"`
	}{Role: "server"}
	node.ServerOpts.KubeAPI.Binding.HostIP = hostIP
	node.ServerOpts.KubeAPI.Binding.HostPort = hostPort
	entry.Nodes = append(entry.Nodes, node)
	return entry
}
