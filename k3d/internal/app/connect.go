package app

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type connectOps struct {
	runner runner
	envs   *environmentStore
}

func (c *connectOps) Connect(name string) error {
	if name == "" {
		return c.showCurrentConnection()
	}
	return c.connectTo(name)
}

func (c *connectOps) connectTo(name string) error {
	instance, err := c.envs.Find(name)
	if err != nil {
		return err
	}

	if _, err := os.Stat(instance.KubeconfigPath); os.IsNotExist(err) {
		return fmt.Errorf("instance %q has no kubeconfig — run 'ces-k3d start %s' first", name, name)
	}

	defaultKubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
	mergedEnv := "KUBECONFIG=" + defaultKubeconfig + ":" + instance.KubeconfigPath

	merged, err := c.runner.OutputWithEnv([]string{mergedEnv}, "kubectl", "config", "view", "--flatten")
	if err != nil {
		return fmt.Errorf("merge kubeconfig: %w", err)
	}

	if err := os.MkdirAll(filepath.Dir(defaultKubeconfig), 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(defaultKubeconfig, merged, 0o600); err != nil {
		return err
	}

	contextName := "k3d-" + name
	if err := c.runner.RunWithEnv([]string{"KUBECONFIG=" + defaultKubeconfig}, "kubectl", "config", "use-context", contextName); err != nil {
		return err
	}

	fmt.Fprintf(c.runner.stdout, "Connected to: %s (%s)\n", name, contextName)
	return nil
}

func (c *connectOps) Disconnect() error {
	defaultKubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
	kubeEnv := []string{"KUBECONFIG=" + defaultKubeconfig}

	currentContext, err := commandOutputWithEnv(c.runner, kubeEnv, "kubectl", "config", "current-context")
	if err != nil {
		return fmt.Errorf("not connected to any k3d instance")
	}
	currentContext = strings.TrimSpace(currentContext)

	instances, err := c.envs.LoadInstances()
	if err != nil {
		return err
	}

	var instanceName string
	for _, instance := range instances {
		if "k3d-"+instance.Name == currentContext {
			instanceName = instance.Name
			break
		}
	}
	if instanceName == "" {
		return fmt.Errorf("not connected to any k3d instance")
	}

	clusterName, err := commandOutputWithEnv(c.runner, kubeEnv, "kubectl", "config", "view",
		"-o", "jsonpath={.contexts[?(@.name==\""+currentContext+"\")].context.cluster}")
	if err != nil {
		return err
	}
	clusterName = strings.TrimSpace(clusterName)

	userName, err := commandOutputWithEnv(c.runner, kubeEnv, "kubectl", "config", "view",
		"-o", "jsonpath={.contexts[?(@.name==\""+currentContext+"\")].context.user}")
	if err != nil {
		return err
	}
	userName = strings.TrimSpace(userName)

	if err := c.runner.RunWithEnv(kubeEnv, "kubectl", "config", "delete-context", currentContext); err != nil {
		return err
	}
	if clusterName != "" {
		if err := c.runner.RunWithEnv(kubeEnv, "kubectl", "config", "delete-cluster", clusterName); err != nil {
			return err
		}
	}
	if userName != "" {
		if err := c.runner.RunWithEnv(kubeEnv, "kubectl", "config", "delete-user", userName); err != nil {
			return err
		}
	}
	if err := c.runner.RunWithEnv(kubeEnv, "kubectl", "config", "unset", "current-context"); err != nil {
		return err
	}

	fmt.Fprintf(c.runner.stdout, "Disconnected from: %s (%s)\n", instanceName, currentContext)
	return nil
}

func (c *connectOps) showCurrentConnection() error {
	currentContext, err := commandOutput(c.runner, "kubectl", "config", "current-context")
	if err != nil {
		fmt.Fprintln(c.runner.stdout, "Not connected to any k3d instance")
		return nil
	}
	currentContext = strings.TrimSpace(currentContext)

	instances, err := c.envs.LoadInstances()
	if err != nil {
		return err
	}

	for _, instance := range instances {
		if "k3d-"+instance.Name == currentContext {
			fmt.Fprintf(c.runner.stdout, "Connected to: %s (%s)\n", instance.Name, currentContext)
			return nil
		}
	}

	fmt.Fprintln(c.runner.stdout, "Not connected to any k3d instance")
	return nil
}
