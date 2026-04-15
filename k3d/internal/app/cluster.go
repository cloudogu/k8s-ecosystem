package app

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

type clusterOps struct {
	config   config.Config
	runner   runner
	registry *registryOps
}

type clusterListEntry struct {
	Name           string `json:"name"`
	ServersRunning int    `json:"serversRunning"`
	Nodes          []struct {
		Role       string `json:"role"`
		ServerOpts struct {
			KubeAPI struct {
				Binding struct {
					HostIP   string `json:"HostIp"`
					HostPort string `json:"HostPort"`
				} `json:"Binding"`
			} `json:"kubeAPI"`
		} `json:"serverOpts"`
	} `json:"nodes"`
}

func (c *clusterOps) exists(name string) (bool, error) {
	out, err := c.runner.Output("k3d", "cluster", "list", name, "-o", "json")
	if err != nil {
		if strings.Contains(err.Error(), "exit status 1") {
			return false, nil
		}
		return false, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(out, &rows); err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

func (c *clusterOps) status(name string) (string, error) {
	out, err := c.runner.Output("k3d", "cluster", "list", name, "-o", "json")
	if err != nil {
		if strings.Contains(err.Error(), "exit status 1") {
			return "missing", nil
		}
		return "", err
	}

	var rows []clusterListEntry
	if err := json.Unmarshal(out, &rows); err != nil {
		return "", err
	}
	if len(rows) == 0 {
		return "missing", nil
	}
	if rows[0].ServersRunning > 0 {
		return "running", nil
	}
	return "stopped", nil
}

func (c *clusterOps) list() ([]clusterListEntry, error) {
	out, err := c.runner.Output("k3d", "cluster", "list", "-o", "json")
	if err != nil {
		return nil, err
	}

	var rows []clusterListEntry
	if err := json.Unmarshal(out, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *clusterOps) createFromEnvFile(instanceEnvFile string) error {
	values, err := parseEnvFile(instanceEnvFile)
	if err != nil {
		return err
	}

	clusterName := values["K3D_CLUSTER_NAME"]
	if clusterName == "" {
		return fmt.Errorf("missing K3D_CLUSTER_NAME in %s", instanceEnvFile)
	}

	fqdn := values["FQDN"]
	hostIP := firstNonEmpty(values["K3D_HOST_IP"], "127.0.0.2")
	apiPort := firstNonEmpty(values["K3D_API_PORT"], "6550")
	httpPort := firstNonEmpty(values["K3D_HTTP_PORT"], "80")
	httpsPort := firstNonEmpty(values["K3D_HTTPS_PORT"], "443")
	kubeconfigPath := firstNonEmpty(values["KUBECONFIG_PATH"], filepath.Join(c.config.Global.KubeconfigDirectory, fqdn))
	k3sImage := os.Getenv("K3D_K3S_IMAGE")
	corednsManifestPath := values["K3D_COREDNS_CUSTOM_MANIFEST_PATH"]

	if exists, err := c.exists(clusterName); err != nil {
		return err
	} else if exists {
		return fmt.Errorf("cluster %q already exists", clusterName)
	}

	registryConfigFile := ""
	if c.config.Global.LocalRegistryEnabled {
		ok, err := c.registry.exists(c.config.Global.LocalRegistryProxyName)
		if err != nil {
			return err
		}
		if !ok {
			return fmt.Errorf("local proxy registry %q is not running", c.config.Global.LocalRegistryProxyName)
		}

		tempFile, err := os.CreateTemp("", "ces-k3d-registry-*.yaml")
		if err != nil {
			return err
		}
		registryConfigFile = tempFile.Name()
		content := fmt.Sprintf("mirrors:\n  \"registry.cloudogu.com\":\n    endpoint:\n      - \"http://k3d-%s:%s\"\n",
			c.config.Global.LocalRegistryProxyName,
			c.config.Global.LocalRegistryClusterPort,
		)
		if _, err := tempFile.WriteString(content); err != nil {
			_ = tempFile.Close()
			return err
		}
		if err := tempFile.Close(); err != nil {
			return err
		}
		defer os.Remove(registryConfigFile)
	}

	args := []string{
		"cluster", "create", clusterName,
		"--servers", "1",
		"--agents", "0",
		"--api-port", hostIP + ":" + apiPort,
		"-p", hostIP + ":" + httpPort + ":80@loadbalancer",
		"-p", hostIP + ":" + httpsPort + ":443@loadbalancer",
		"--k3s-arg", "--disable=traefik@server:0",
		"--kubeconfig-update-default=false",
		"--kubeconfig-switch-context=false",
		"--wait",
	}
	if k3sImage != "" {
		args = append(args, "--image", k3sImage)
	}
	if c.config.Global.LocalRegistryEnabled {
		args = append(args,
			"--registry-use", "k3d-"+c.config.Global.LocalRegistryProxyName+":"+c.config.Global.LocalRegistryClusterPort,
			"--registry-config", registryConfigFile,
		)
	}
	if corednsManifestPath != "" {
		args = append(args, "--volume", corednsManifestPath+":/var/lib/rancher/k3s/server/manifests/coredns-custom.yaml@server:0")
	}

	if err := c.runner.Run("k3d", args...); err != nil {
		return err
	}
	if err := c.writeKubeconfig(clusterName, kubeconfigPath); err != nil {
		return err
	}
	return c.runner.Run("kubectl", "--kubeconfig", kubeconfigPath, "get", "nodes")
}

func (c *clusterOps) writeKubeconfig(clusterName, kubeconfigPath string) error {
	if clusterName == "" || kubeconfigPath == "" {
		return fmt.Errorf("cluster name and kubeconfig path must not be empty")
	}
	if err := os.MkdirAll(filepath.Dir(kubeconfigPath), 0o755); err != nil {
		return err
	}
	if err := c.runner.Run("k3d", "kubeconfig", "write", clusterName, "--output", kubeconfigPath, "--overwrite"); err != nil {
		return err
	}
	if err := os.Chmod(kubeconfigPath, 0o600); err != nil {
		return err
	}

	contextName, err := commandOutput(c.runner, "kubectl", "--kubeconfig", kubeconfigPath, "config", "current-context")
	if err != nil {
		return err
	}
	contextName = strings.TrimSpace(contextName)
	if contextName != "" && c.config.Global.DefaultNamespace != "" {
		return c.runner.RunWithEnv([]string{"KUBECONFIG=" + kubeconfigPath}, "kubectl", "config", "set-context", contextName, "--namespace", c.config.Global.DefaultNamespace)
	}

	return nil
}
