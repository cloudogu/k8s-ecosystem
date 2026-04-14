package app

type EcosystemInfo struct {
	Name           string
	FQDN           string
	KubeconfigPath string
	Status         string
}

type EcosystemManager interface {
	List() ([]EcosystemInfo, error)
	Open(name string) (string, error)
	Create(name string) error
	Start(name string) error
	Stop(name string) error
	Delete(name string) error
}

type ClusterManager interface {
	Exists(name string) (bool, error)
	List() ([]clusterListEntry, error)
	CreateFromEnvFile(instanceEnvFile string, printNextSteps bool) error
	DeleteFromEnvFile(instanceEnvFile string) error
	WriteKubeconfigFromEnvFile(instanceEnvFile string) error
	WriteKubeconfig(clusterName, kubeconfigPath string) error
}

type RegistryManager interface {
	Start() error
	Stop() error
	Delete() error
	Status() error
	Exists(name string) (bool, error)
}

type HostsManager interface {
	EnsureRegistryEntries() error
	RemoveRegistryEntries() error
	EnsureHostEntry(name, fqdn, hostIP string) error
	RemoveHostEntry(name, fqdn string) error
}

type Installer interface {
	Install(name string) error
}

type EnvironmentInstance struct {
	Name           string
	EnvFile        string
	FQDN           string
	KubeconfigPath string
	HostIP         string
}

type EnvironmentStore interface {
	LoadInstances() ([]EnvironmentInstance, error)
	Find(name string) (EnvironmentInstance, error)
	EnvFilePath(name string) string
	CoreDNSManifestPath(name string) string
	WriteCoreDNSManifest(path, fqdn string) error
	WriteInstanceEnv(path, name, fqdn, hostIP string, apiPort int, kubeconfigPath, corednsManifestPath string) error
	LookupValue(instanceEnvFile, key string) (string, error)
	Remove(path string) error
}
