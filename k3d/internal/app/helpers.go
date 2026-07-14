package app

import (
	"errors"
	"fmt"
	"io"
	"os/exec"
	"text/tabwriter"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

var firstNonEmpty = config.FirstNonEmpty

// isExitCode reports whether err is an *exec.ExitError with the given exit code.
func isExitCode(err error, code int) bool {
	var exitErr *exec.ExitError
	return errors.As(err, &exitErr) && exitErr.ExitCode() == code
}

func commandOutput(runner runner, name string, args ...string) (string, error) {
	out, err := runner.Output(name, args...)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func commandOutputWithEnv(runner runner, env []string, name string, args ...string) (string, error) {
	out, err := runner.OutputWithEnv(env, name, args...)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func urlFor(fqdn string) string {
	if fqdn == "" {
		return ""
	}
	return "https://" + fqdn
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

// ecosystemListing is a single row of the `list` command output.
type ecosystemListing struct {
	Name           string
	Status         clusterStatus
	URL            string
	KubeconfigPath string
}

func printEcosystemTable(w io.Writer, listings []ecosystemListing) {
	tw := tabwriter.NewWriter(w, 0, 8, 2, ' ', 0)
	fmt.Fprintln(tw, "NAME\tSTATUS\tURL\tKUBECONFIG")
	for _, listing := range listings {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\n", listing.Name, listing.Status, listing.URL, listing.KubeconfigPath)
	}
	_ = tw.Flush()
}
