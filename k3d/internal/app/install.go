package app

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
)

type installerOps struct {
	config config.Config
	runner runner
	envs   *environmentStore
}

func (i *installerOps) install(name string) error {
	instance, err := i.envs.Find(name)
	if err != nil {
		return err
	}

	globalValues, err := parseEnvFile(i.config.Paths.GlobalEnvFile)
	if err != nil {
		return fmt.Errorf("load global config: %w", err)
	}
	instanceValues, err := parseEnvFile(instance.EnvFile)
	if err != nil {
		return fmt.Errorf("load instance config: %w", err)
	}

	values := mergeEnvValues(globalValues, instanceValues)
	if err := validateInstallSettings(values); err != nil {
		return err
	}

	args, env := buildInstallCommand(values)

	return i.runner.RunInDirWithEnv(i.config.Paths.RepoRoot, env, filepath.Join("image", "scripts", "dev", "installEcosystem.sh"), args...)
}

func buildInstallCommand(values map[string]string) ([]string, []string) {
	remoteImageRegistryURL := "https://registry.cloudogu.com"
	remoteHelmRegistryHost := "registry.cloudogu.com"

	doguRegistryURL := firstNonEmpty(values["DOGU_REGISTRY_URL"], "https://dogu.cloudogu.com/api/v2/dogus")
	doguRegistryURLSchema := firstNonEmpty(values["DOGU_REGISTRY_URLSCHEMA"], "default")
	imageRegistryURL := firstNonEmpty(values["IMAGE_REGISTRY_URL"], remoteImageRegistryURL)
	helmRegistryHost := firstNonEmpty(values["HELM_REGISTRY_HOST"], remoteHelmRegistryHost)
	runtimeHelmRegistryHost := firstNonEmpty(values["RUNTIME_HELM_REGISTRY_HOST"], helmRegistryHost)
	helmRegistrySchema := firstNonEmpty(values["HELM_REGISTRY_SCHEMA"], "oci")
	helmRegistryPlainHTTP := firstNonEmpty(values["HELM_REGISTRY_PLAIN_HTTP"], "false")
	localRegistryEnabled := firstNonEmpty(values["LOCAL_REGISTRY_ENABLED"], "true")
	localRegistryProxyName := firstNonEmpty(values["LOCAL_REGISTRY_PROXY_NAME"], "registry-proxy.localhost")
	localRegistryProxyPort := firstNonEmpty(values["LOCAL_REGISTRY_PROXY_PORT"], "5002")
	localRegistryClusterPort := firstNonEmpty(values["LOCAL_REGISTRY_CLUSTER_PORT"], "5000")
	cesNamespace := firstNonEmpty(values["CES_NAMESPACE"], "ecosystem")
	helmRepositoryNamespace := firstNonEmpty(values["HELM_REPOSITORY_NAMESPACE"], "k8s")
	fqdn := firstNonEmpty(values["FQDN"], "k3ces.localdomain")
	kubeCtxName := firstNonEmpty(values["KUBE_CTX_NAME"], fqdn)
	kubeconfigPath := firstNonEmpty(values["KUBECONFIG_PATH"], filepath.Join(os.Getenv("HOME"), ".kube", kubeCtxName))
	forceUpgradeEcosystem := firstNonEmpty(values["FORCE_UPGRADE_ECOSYSTEM"], "false")

	if localRegistryEnabled == "true" {
		localProxyHost := "localhost:" + localRegistryProxyPort
		localProxyRuntimeHost := "k3d-" + localRegistryProxyName + ":" + localRegistryClusterPort

		if helmRegistryHost == remoteHelmRegistryHost {
			helmRegistryHost = localProxyHost
		}
		if runtimeHelmRegistryHost == remoteHelmRegistryHost {
			runtimeHelmRegistryHost = localProxyRuntimeHost
		}
		helmRegistryPlainHTTP = "true"
	}

	args := []string{
		cesNamespace,
		helmRepositoryNamespace,
		values["DOGU_REGISTRY_USERNAME"],
		values["DOGU_REGISTRY_PASSWORD"],
		doguRegistryURL,
		doguRegistryURLSchema,
		values["IMAGE_REGISTRY_USERNAME"],
		values["IMAGE_REGISTRY_PASSWORD"],
		imageRegistryURL,
		values["HELM_REGISTRY_USERNAME"],
		values["HELM_REGISTRY_PASSWORD"],
		helmRegistryHost,
		runtimeHelmRegistryHost,
		helmRegistrySchema,
		helmRegistryPlainHTTP,
		kubeCtxName,
		"1",
		fqdn,
		forceUpgradeEcosystem,
	}

	env := append(os.Environ(),
		"INSTALL_LONGHORN=false",
		"KUBECONFIG_PATH="+kubeconfigPath,
		"CERTIFICATE_CRT_FILE=",
		"CERTIFICATE_KEY_FILE=",
	)

	return args, env
}

func validateInstallSettings(values map[string]string) error {
	requiredVars := []string{
		"DOGU_REGISTRY_USERNAME",
		"DOGU_REGISTRY_PASSWORD",
	}

	if firstNonEmpty(values["LOCAL_REGISTRY_ENABLED"], "true") != "true" {
		requiredVars = append(requiredVars,
			"IMAGE_REGISTRY_USERNAME",
			"IMAGE_REGISTRY_PASSWORD",
			"HELM_REGISTRY_USERNAME",
			"HELM_REGISTRY_PASSWORD",
		)
	}

	for _, key := range requiredVars {
		if values[key] == "" {
			return fmt.Errorf("missing required setting: %s", key)
		}
	}

	kubeconfigPath := firstNonEmpty(values["KUBECONFIG_PATH"], filepath.Join(os.Getenv("HOME"), ".kube", firstNonEmpty(values["KUBE_CTX_NAME"], firstNonEmpty(values["FQDN"], "k3ces.localdomain"))))
	if _, err := os.Stat(kubeconfigPath); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("kubeconfig not found: %s", kubeconfigPath)
		}
		return err
	}

	return nil
}

func mergeEnvValues(maps ...map[string]string) map[string]string {
	merged := map[string]string{}
	for _, values := range maps {
		for key, value := range values {
			merged[key] = value
		}
	}
	return merged
}
