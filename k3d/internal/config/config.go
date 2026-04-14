package config

import (
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/envfiles"
)

type Paths struct {
	K3DDir          string
	RepoRoot        string
	GlobalEnvFile   string
	ConfigTemplate  string
	EnvironmentDir  string
	EcosystemScript string
	ClusterScript   string
	RegistryScript  string
	InstallScript   string
}

type Global struct {
	BaseDomain                  string
	KubeconfigDirectory         string
	DefaultKubeconfigPath       string
	APIStartPort                int
	DefaultNamespace            string
	ManageHostsFile             bool
	MergeDefaultKubeconfig      bool
	SwitchDefaultKubeconfigCtx  bool
	LocalRegistryEnabled        bool
	LocalRegistryStoragePath    string
	LocalRegistryDevName        string
	LocalRegistryDevPort        string
	LocalRegistryProxyName      string
	LocalRegistryProxyPort      string
	LocalRegistryClusterPort    string
	LocalRegistryProxyRemoteURL string
	LocalRegistryProxyUsername  string
	LocalRegistryProxyPassword  string
}

type Config struct {
	Paths  Paths
	Global Global
}

func Load() (Config, error) {
	paths, err := discoverPaths()
	if err != nil {
		return Config{}, err
	}

	values, err := envfiles.ParseFileOptional(paths.GlobalEnvFile)
	if err != nil {
		return Config{}, fmt.Errorf("load global config: %w", err)
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return Config{}, fmt.Errorf("resolve home dir: %w", err)
	}

	cfg := Config{
		Paths: paths,
		Global: Global{
			BaseDomain:                  firstNonEmpty(values["BASE_DOMAIN"], "k3ces.localdomain"),
			KubeconfigDirectory:         firstNonEmpty(values["KUBECONFIG_DIRECTORY"], filepath.Join(home, ".kube")),
			DefaultKubeconfigPath:       firstNonEmpty(values["DEFAULT_KUBECONFIG_PATH"], filepath.Join(home, ".kube", "config")),
			APIStartPort:                parseIntDefault(firstNonEmpty(os.Getenv("K3D_API_PORT_START"), values["K3D_API_PORT_START"]), 6550),
			DefaultNamespace:            firstNonEmpty(values["CES_NAMESPACE"], "ecosystem"),
			ManageHostsFile:             parseBoolDefault(values["MANAGE_HOSTS_FILE"], true),
			MergeDefaultKubeconfig:      parseBoolDefault(values["MERGE_DEFAULT_KUBECONFIG"], true),
			SwitchDefaultKubeconfigCtx:  parseBoolDefault(values["SWITCH_DEFAULT_KUBECONFIG_CONTEXT"], false),
			LocalRegistryEnabled:        parseBoolDefault(values["LOCAL_REGISTRY_ENABLED"], true),
			LocalRegistryStoragePath:    firstNonEmpty(values["LOCAL_REGISTRY_STORAGE_PATH"], filepath.Join(home, ".local", "share", "k3d", "registries", "cloudogu")),
			LocalRegistryDevName:        firstNonEmpty(values["LOCAL_REGISTRY_DEV_NAME"], "registry-dev.localhost"),
			LocalRegistryDevPort:        firstNonEmpty(values["LOCAL_REGISTRY_DEV_PORT"], "5001"),
			LocalRegistryProxyName:      firstNonEmpty(values["LOCAL_REGISTRY_PROXY_NAME"], "registry-proxy.localhost"),
			LocalRegistryProxyPort:      firstNonEmpty(values["LOCAL_REGISTRY_PROXY_PORT"], "5002"),
			LocalRegistryClusterPort:    firstNonEmpty(values["LOCAL_REGISTRY_CLUSTER_PORT"], "5000"),
			LocalRegistryProxyRemoteURL: firstNonEmpty(values["LOCAL_REGISTRY_PROXY_REMOTE_URL"], "https://registry.cloudogu.com"),
			LocalRegistryProxyUsername:  firstNonEmpty(values["LOCAL_REGISTRY_PROXY_USERNAME"], values["HELM_REGISTRY_USERNAME"], values["IMAGE_REGISTRY_USERNAME"]),
			LocalRegistryProxyPassword:  decodeIfBase64(firstNonEmpty(values["LOCAL_REGISTRY_PROXY_PASSWORD"], values["HELM_REGISTRY_PASSWORD"], values["IMAGE_REGISTRY_PASSWORD"])),
		},
	}

	return cfg, nil
}

func discoverPaths() (Paths, error) {
	candidates := []string{}

	if wd, err := os.Getwd(); err == nil {
		candidates = append(candidates, wd)
	}

	if exePath, err := os.Executable(); err == nil {
		candidates = append(candidates, filepath.Dir(exePath))
	}

	_, currentFile, _, ok := runtime.Caller(0)
	if ok {
		candidates = append(candidates, filepath.Dir(currentFile))
	}

	for _, candidate := range candidates {
		if paths, ok := resolveFrom(candidate); ok {
			return paths, nil
		}
	}

	return Paths{}, errors.New("unable to locate k3d directory")
}

func resolveFrom(start string) (Paths, bool) {
	dir := start
	for {
		k3dDir := dir
		if filepath.Base(dir) != "k3d" {
			k3dDir = filepath.Join(dir, "k3d")
		}

		configTemplate := filepath.Join(k3dDir, "config.env.template")
		environmentDir := filepath.Join(k3dDir, "environments")
		if fileExists(configTemplate) && dirExists(environmentDir) {
			repoRoot := filepath.Dir(k3dDir)
			return Paths{
				K3DDir:          k3dDir,
				RepoRoot:        repoRoot,
				GlobalEnvFile:   filepath.Join(k3dDir, "config.env"),
				ConfigTemplate:  configTemplate,
				EnvironmentDir:  environmentDir,
				EcosystemScript: filepath.Join(k3dDir, "ecosystem.sh"),
				ClusterScript:   filepath.Join(k3dDir, "cluster.sh"),
				RegistryScript:  filepath.Join(k3dDir, "registry.sh"),
				InstallScript:   filepath.Join(k3dDir, "install.sh"),
			}, true
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return Paths{}, false
		}
		dir = parent
	}
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func parseBoolDefault(value string, fallback bool) bool {
	if value == "" {
		return fallback
	}
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "1", "true", "yes", "on":
		return true
	case "0", "false", "no", "off":
		return false
	default:
		return fallback
	}
}

func parseIntDefault(value string, fallback int) int {
	var parsed int
	if _, err := fmt.Sscanf(strings.TrimSpace(value), "%d", &parsed); err != nil || parsed == 0 {
		return fallback
	}
	return parsed
}

func decodeIfBase64(value string) string {
	if strings.TrimSpace(value) == "" {
		return ""
	}
	decoded, err := base64.StdEncoding.DecodeString(value)
	if err != nil {
		return value
	}
	return string(decoded)
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}
