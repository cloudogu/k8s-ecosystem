package app

import (
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

func commandOutput(runner system.Runner, name string, args ...string) (string, error) {
	out, err := runner.Output(name, args...)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func urlFor(fqdn string) string {
	if fqdn == "" {
		return ""
	}
	u := url.URL{Scheme: "https", Host: fqdn}
	return u.String()
}

func requireFile(path string) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	if info.IsDir() {
		return fmt.Errorf("%s is a directory", filepath.Base(path))
	}
	return nil
}

func requireDir(path string) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("%s is not a directory", filepath.Base(path))
	}
	return nil
}

func validateName(name string) error {
	if name == "" {
		return fmt.Errorf("ecosystem name must not be empty")
	}
	for i, r := range name {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			continue
		}
		return fmt.Errorf("invalid ecosystem name %q at position %d", name, i+1)
	}
	if name[0] == '-' {
		return fmt.Errorf("invalid ecosystem name %q: must start with a letter or digit", name)
	}
	return nil
}

func nextFreeHostIP(clusters []clusterListEntry) (string, error) {
	used := map[string]struct{}{}
	for _, cluster := range clusters {
		for _, node := range cluster.Nodes {
			if node.Role != "server" {
				continue
			}
			if node.ServerOpts.KubeAPI.Binding.HostIP != "" {
				used[node.ServerOpts.KubeAPI.Binding.HostIP] = struct{}{}
			}
		}
	}

	for octet := 2; octet <= 254; octet++ {
		candidate := fmt.Sprintf("127.0.0.%d", octet)
		if _, exists := used[candidate]; !exists {
			return candidate, nil
		}
	}
	return "", fmt.Errorf("no free loopback IP found in 127.0.0.0/24")
}

func nextFreeAPIPort(clusters []clusterListEntry, start int) (int, error) {
	used := map[string]struct{}{}
	for _, cluster := range clusters {
		for _, node := range cluster.Nodes {
			if node.Role != "server" {
				continue
			}
			if node.ServerOpts.KubeAPI.Binding.HostPort != "" {
				used[node.ServerOpts.KubeAPI.Binding.HostPort] = struct{}{}
			}
		}
	}

	for port := start; port <= 6999; port++ {
		candidate := fmt.Sprintf("%d", port)
		if _, exists := used[candidate]; !exists {
			return port, nil
		}
	}
	return 0, fmt.Errorf("no free API port found starting at %d", start)
}

func lineContainsHost(line, fqdn string) bool {
	fields := strings.Fields(line)
	for i, field := range fields {
		if strings.HasPrefix(field, "#") {
			return false
		}
		if i == 0 {
			continue
		}
		if field == fqdn {
			return true
		}
	}
	return false
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}
