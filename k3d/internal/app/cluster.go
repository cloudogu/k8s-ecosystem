package app

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/envfiles"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type clusterService struct {
	config   config.Config
	runner   system.Runner
	registry RegistryManager
}

func newClusterService(cfg config.Config, runner system.Runner, registry RegistryManager) ClusterManager {
	return &clusterService{
		config:   cfg,
		runner:   runner,
		registry: registry,
	}
}

func (s *clusterService) Exists(name string) (bool, error) {
	out, err := s.runner.Output("k3d", "cluster", "list", name, "-o", "json")
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

func (s *clusterService) List() ([]clusterListEntry, error) {
	out, err := s.runner.Output("k3d", "cluster", "list", "-o", "json")
	if err != nil {
		return nil, err
	}
	var rows []clusterListEntry
	if err := json.Unmarshal(out, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (s *clusterService) CreateFromEnvFile(instanceEnvFile string, printNextSteps bool) error {
	values, err := envfiles.ParseFile(instanceEnvFile)
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
	kubeconfigPath := firstNonEmpty(values["KUBECONFIG_PATH"], filepath.Join(s.config.Global.KubeconfigDirectory, fqdn))
	k3sImage := os.Getenv("K3D_K3S_IMAGE")
	corednsManifestPath := values["K3D_COREDNS_CUSTOM_MANIFEST_PATH"]

	if exists, err := s.Exists(clusterName); err != nil {
		return err
	} else if exists {
		return fmt.Errorf("cluster %q already exists", clusterName)
	}

	if s.config.Global.LocalRegistryEnabled {
		ok, err := s.registry.Exists(s.config.Global.LocalRegistryProxyName)
		if err != nil {
			return err
		}
		if !ok {
			return fmt.Errorf("local proxy registry %q is not running", s.config.Global.LocalRegistryProxyName)
		}
	}

	registryConfigFile := ""
	if s.config.Global.LocalRegistryEnabled {
		tempFile, err := os.CreateTemp("", "ces-k3d-registry-*.yaml")
		if err != nil {
			return err
		}
		registryConfigFile = tempFile.Name()
		content := fmt.Sprintf("mirrors:\n  \"registry.cloudogu.com\":\n    endpoint:\n      - \"http://k3d-%s:%s\"\n",
			s.config.Global.LocalRegistryProxyName,
			s.config.Global.LocalRegistryClusterPort,
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
	if s.config.Global.LocalRegistryEnabled {
		args = append(args,
			"--registry-use", "k3d-"+s.config.Global.LocalRegistryProxyName+":"+s.config.Global.LocalRegistryClusterPort,
			"--registry-config", registryConfigFile,
		)
	}
	if corednsManifestPath != "" {
		args = append(args, "--volume", corednsManifestPath+":/var/lib/rancher/k3s/server/manifests/coredns-custom.yaml@server:0")
	}

	if err := s.runner.Run("k3d", args...); err != nil {
		return err
	}
	if err := s.WriteKubeconfig(clusterName, kubeconfigPath); err != nil {
		return err
	}
	if err := s.runner.Run("kubectl", "--kubeconfig", kubeconfigPath, "get", "nodes"); err != nil {
		return err
	}

	if printNextSteps {
		fmt.Fprintf(os.Stdout, "Cluster '%s' is ready.\n\n", clusterName)
		fmt.Fprintf(os.Stdout, "Kubeconfig:\n  dedicated: %s\n  default:   %s (merged: %t)\n  namespace: %s\n\n",
			kubeconfigPath,
			s.config.Global.DefaultKubeconfigPath,
			s.config.Global.MergeDefaultKubeconfig,
			s.config.Global.DefaultNamespace,
		)
		fmt.Fprintf(os.Stdout, "Hosts entry:\n  sudo sh -c 'echo \"%s %s\" >> /etc/hosts'\n\n", hostIP, fqdn)
	}

	return nil
}

func (a *App) ClusterCreate(name string) error {
	return a.cluster.CreateFromEnvFile(a.envs.EnvFilePath(name), false)
}

func (a *App) ClusterDelete(name string) error {
	return a.cluster.DeleteFromEnvFile(a.envs.EnvFilePath(name))
}

func (a *App) ClusterKubeconfig(name string) error {
	return a.cluster.WriteKubeconfigFromEnvFile(a.envs.EnvFilePath(name))
}

func (s *clusterService) DeleteFromEnvFile(instanceEnvFile string) error {
	values, err := envfiles.ParseFile(instanceEnvFile)
	if err != nil {
		return err
	}

	clusterName := values["K3D_CLUSTER_NAME"]
	kubeconfigPath := values["KUBECONFIG_PATH"]
	if clusterName == "" {
		return fmt.Errorf("missing K3D_CLUSTER_NAME in %s", instanceEnvFile)
	}

	if kubeconfigPath != "" {
		if err := s.removeDefaultKubeconfigReferences(kubeconfigPath); err != nil {
			return err
		}
	}
	if err := s.runner.Run("k3d", "cluster", "delete", clusterName); err != nil {
		return err
	}
	if kubeconfigPath != "" {
		if err := os.Remove(kubeconfigPath); err != nil && !os.IsNotExist(err) {
			return err
		}
	}
	return nil
}

func (s *clusterService) WriteKubeconfigFromEnvFile(instanceEnvFile string) error {
	values, err := envfiles.ParseFile(instanceEnvFile)
	if err != nil {
		return err
	}
	return s.WriteKubeconfig(values["K3D_CLUSTER_NAME"], values["KUBECONFIG_PATH"])
}

func (s *clusterService) WriteKubeconfig(clusterName, kubeconfigPath string) error {
	if clusterName == "" || kubeconfigPath == "" {
		return fmt.Errorf("cluster name and kubeconfig path must not be empty")
	}
	if err := os.MkdirAll(filepath.Dir(kubeconfigPath), 0o755); err != nil {
		return err
	}
	if err := s.runner.Run("k3d", "kubeconfig", "write", clusterName, "--output", kubeconfigPath, "--overwrite"); err != nil {
		return err
	}
	if err := os.Chmod(kubeconfigPath, 0o600); err != nil {
		return err
	}

	contextName, err := commandOutput(s.runner, "kubectl", "--kubeconfig", kubeconfigPath, "config", "current-context")
	if err != nil {
		return err
	}
	contextName = strings.TrimSpace(contextName)

	if contextName != "" && s.config.Global.DefaultNamespace != "" {
		if err := s.runner.RunWithEnv([]string{"KUBECONFIG=" + kubeconfigPath}, "kubectl", "config", "set-context", contextName, "--namespace", s.config.Global.DefaultNamespace); err != nil {
			return err
		}
	}

	if s.config.Global.MergeDefaultKubeconfig {
		if err := os.MkdirAll(filepath.Dir(s.config.Global.DefaultKubeconfigPath), 0o755); err != nil {
			return err
		}
		if err := s.runner.Run("k3d", "kubeconfig", "merge", clusterName, "--output", s.config.Global.DefaultKubeconfigPath, "--kubeconfig-switch-context="+fmt.Sprintf("%t", s.config.Global.SwitchDefaultKubeconfigCtx)); err != nil {
			return err
		}
		if contextName != "" && s.config.Global.DefaultNamespace != "" {
			if err := s.runner.RunWithEnv([]string{"KUBECONFIG=" + s.config.Global.DefaultKubeconfigPath}, "kubectl", "config", "set-context", contextName, "--namespace", s.config.Global.DefaultNamespace); err != nil {
				return err
			}
		}
	}

	return nil
}

func (s *clusterService) removeDefaultKubeconfigReferences(kubeconfigPath string) error {
	if !s.config.Global.MergeDefaultKubeconfig {
		return nil
	}
	if _, err := os.Stat(s.config.Global.DefaultKubeconfigPath); err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if _, err := os.Stat(kubeconfigPath); err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	contextName, err := commandOutput(s.runner, "kubectl", "--kubeconfig", kubeconfigPath, "config", "current-context")
	if err != nil {
		return nil
	}
	contextName = strings.TrimSpace(contextName)
	if contextName == "" {
		return nil
	}

	clusterName, _ := commandOutput(s.runner, "kubectl", "--kubeconfig", kubeconfigPath, "config", "view", "--raw", "-o", fmt.Sprintf("jsonpath={.contexts[?(@.name==\"%s\")].context.cluster}", contextName))
	userName, _ := commandOutput(s.runner, "kubectl", "--kubeconfig", kubeconfigPath, "config", "view", "--raw", "-o", fmt.Sprintf("jsonpath={.contexts[?(@.name==\"%s\")].context.user}", contextName))
	currentContext, _ := commandOutput(s.runner, "kubectl", "--kubeconfig", s.config.Global.DefaultKubeconfigPath, "config", "current-context")

	if strings.TrimSpace(currentContext) == contextName {
		_ = s.runner.RunWithEnv([]string{"KUBECONFIG=" + s.config.Global.DefaultKubeconfigPath}, "kubectl", "config", "unset", "current-context")
	}
	_ = s.runner.RunWithEnv([]string{"KUBECONFIG=" + s.config.Global.DefaultKubeconfigPath}, "kubectl", "config", "delete-context", contextName)
	if trimmed := strings.TrimSpace(clusterName); trimmed != "" {
		_ = s.runner.RunWithEnv([]string{"KUBECONFIG=" + s.config.Global.DefaultKubeconfigPath}, "kubectl", "config", "delete-cluster", trimmed)
	}
	if trimmed := strings.TrimSpace(userName); trimmed != "" {
		_ = s.runner.RunWithEnv([]string{"KUBECONFIG=" + s.config.Global.DefaultKubeconfigPath}, "kubectl", "config", "unset", "users."+trimmed)
	}

	return nil
}
