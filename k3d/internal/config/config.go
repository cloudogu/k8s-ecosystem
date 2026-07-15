package config

import (
	"bufio"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

type Paths struct {
	K3DDir         string
	RepoRoot       string
	GlobalEnvFile  string
	EnvironmentDir string
}

type Global struct {
	BaseDomain                  string
	KubeconfigDirectory         string
	APIStartPort                int
	DefaultNamespace            string
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

	values, err := parseOptionalEnvFile(paths.GlobalEnvFile)
	if err != nil {
		return Config{}, fmt.Errorf("load global config: %w", err)
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return Config{}, fmt.Errorf("resolve home dir: %w", err)
	}

	proxyPassword, err := decodeBase64(FirstNonEmpty(values["LOCAL_REGISTRY_PROXY_PASSWORD"], values["HELM_REGISTRY_PASSWORD"], values["IMAGE_REGISTRY_PASSWORD"]))
	if err != nil {
		return Config{}, fmt.Errorf("decode registry proxy password (must be base64-encoded, see config.env.template): %w", err)
	}

	localRegistryEnabled, err := strconv.ParseBool(FirstNonEmpty(values["LOCAL_REGISTRY_ENABLED"], "true"))
	if err != nil {
		return Config{}, fmt.Errorf("failed to parse LOCAL_REGISTRY_ENABLED: %w", err)
	}

	cfg := Config{
		Paths: paths,
		Global: Global{
			BaseDomain:                  FirstNonEmpty(values["BASE_DOMAIN"], "k3ces.localdomain"),
			KubeconfigDirectory:         FirstNonEmpty(values["KUBECONFIG_DIRECTORY"], filepath.Join(home, ".kube")),
			APIStartPort:                parseIntDefault(FirstNonEmpty(os.Getenv("K3D_API_PORT_START"), values["K3D_API_PORT_START"]), 6550),
			DefaultNamespace:            FirstNonEmpty(values["CES_NAMESPACE"], "ecosystem"),
			LocalRegistryEnabled:        localRegistryEnabled,
			LocalRegistryStoragePath:    FirstNonEmpty(values["LOCAL_REGISTRY_STORAGE_PATH"], filepath.Join(home, ".local", "share", "k3d", "registries", "cloudogu")),
			LocalRegistryDevName:        FirstNonEmpty(values["LOCAL_REGISTRY_DEV_NAME"], "registry-dev.localhost"),
			LocalRegistryDevPort:        FirstNonEmpty(values["LOCAL_REGISTRY_DEV_PORT"], "5001"),
			LocalRegistryProxyName:      FirstNonEmpty(values["LOCAL_REGISTRY_PROXY_NAME"], "registry-proxy.localhost"),
			LocalRegistryProxyPort:      FirstNonEmpty(values["LOCAL_REGISTRY_PROXY_PORT"], "5002"),
			LocalRegistryClusterPort:    FirstNonEmpty(values["LOCAL_REGISTRY_CLUSTER_PORT"], "5000"),
			LocalRegistryProxyRemoteURL: FirstNonEmpty(values["LOCAL_REGISTRY_PROXY_REMOTE_URL"], "https://registry.cloudogu.com"),
			LocalRegistryProxyUsername:  FirstNonEmpty(values["LOCAL_REGISTRY_PROXY_USERNAME"], values["HELM_REGISTRY_USERNAME"], values["IMAGE_REGISTRY_USERNAME"]),
			LocalRegistryProxyPassword:  proxyPassword,
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
				K3DDir:         k3dDir,
				RepoRoot:       repoRoot,
				GlobalEnvFile:  filepath.Join(k3dDir, "config.env"),
				EnvironmentDir: environmentDir,
			}, true
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return Paths{}, false
		}
		dir = parent
	}
}

func FirstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func parseIntDefault(value string, fallback int) int {
	var parsed int
	if _, err := fmt.Sscanf(strings.TrimSpace(value), "%d", &parsed); err != nil || parsed == 0 {
		return fallback
	}
	return parsed
}

// decodeBase64 decodes value, which must be base64-encoded per config.env.template's convention.
// An empty value decodes to empty; any other value that fails to decode is a configuration error.
func decodeBase64(value string) (string, error) {
	if strings.TrimSpace(value) == "" {
		return "", nil
	}
	decoded, err := base64.StdEncoding.DecodeString(value)
	if err != nil {
		return "", fmt.Errorf("value is not valid base64: %w", err)
	}
	return string(decoded), nil
}

func parseOptionalEnvFile(path string) (map[string]string, error) {
	if _, err := os.Stat(path); err != nil {
		if os.IsNotExist(err) {
			return map[string]string{}, nil
		}
		return nil, err
	}
	return ParseEnvFile(path)
}

func ParseEnvFile(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	values := map[string]string{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		line = strings.TrimPrefix(line, "export ")
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}

		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		value = strings.Trim(value, `"'`)
		value = expandEnvValue(value)
		values[key] = value
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return values, nil
}

func expandEnvValue(value string) string {
	home, _ := os.UserHomeDir()
	return os.Expand(value, func(key string) string {
		if key == "HOME" && home != "" {
			return home
		}
		return os.Getenv(key)
	})
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}
