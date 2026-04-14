package cli

import (
	"github.com/alecthomas/kong"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/app"
)

type CLI struct {
	List     ListCmd        `cmd:"" help:"List managed local k3d ecosystems."`
	Open     OpenCmd        `cmd:"" help:"Open an ecosystem URL in the browser."`
	Doctor   DoctorCmd      `cmd:"" help:"Check local prerequisites and configuration files."`
	Version  VersionCmd     `cmd:"" help:"Print CLI and repo metadata."`
	Create   CreateCmd      `cmd:"" help:"Create a new ecosystem: registry, cluster, bootstrap, hosts entry."`
	Start    StartCmd       `cmd:"" help:"Start an existing ecosystem and refresh kubeconfig/hosts state."`
	Stop     StopCmd        `cmd:"" help:"Stop an existing ecosystem cluster."`
	Delete   DeleteCmd      `cmd:"" help:"Delete an ecosystem cluster and remove local generated files."`
	Install  InstallCmd     `cmd:"" help:"Run the CES bootstrap on an existing ecosystem environment."`
	Registry RegistryCmd    `cmd:"" help:"Manage the shared local registry stack used by k3d ecosystems."`
	Cluster  ClusterRootCmd `cmd:"" help:"Run low-level cluster operations for an existing ecosystem environment."`
}

type ListCmd struct{}
type DoctorCmd struct{}
type VersionCmd struct{}

type OpenCmd struct {
	Name string `arg:"" name:"name" help:"Ecosystem name, for example 'dev1'."`
}

type CreateCmd struct {
	Name string `arg:"" name:"name" help:"New ecosystem name, for example 'dev3'."`
}

type StartCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type StopCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type DeleteCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type InstallCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type RegistryCmd struct {
	Start  RegistryStartCmd  `cmd:"" help:"Create or start the local dev and proxy registries."`
	Stop   RegistryStopCmd   `cmd:"" help:"Stop both local registries but keep their data."`
	Delete RegistryDeleteCmd `cmd:"" help:"Delete both local registries and clean up registry hosts entries."`
	Status RegistryStatusCmd `cmd:"" help:"Show configured registry endpoints and current status."`
}

type ClusterRootCmd struct {
	Create     ClusterCreateCmd     `cmd:"" help:"Create the low-level k3d cluster from an existing environment file."`
	Delete     ClusterDeleteCmd     `cmd:"" help:"Delete the low-level k3d cluster for an existing environment file."`
	Kubeconfig ClusterKubeconfigCmd `cmd:"" name:"kubeconfig" help:"Write and merge kubeconfig for an existing environment."`
}

type RegistryStartCmd struct{}
type RegistryStopCmd struct{}
type RegistryDeleteCmd struct{}
type RegistryStatusCmd struct{}

type ClusterCreateCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type ClusterDeleteCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

type ClusterKubeconfigCmd struct {
	Name string `arg:"" name:"name" help:"Existing ecosystem name, for example 'dev1'."`
}

func Parse(application *app.App, args []string) error {
	model := &CLI{}
	parser, err := kong.New(
		model,
		kong.Name("ces-k3d"),
		kong.Description(`Manage local k3d-based CES development environments.

Examples:
  ces-k3d create dev1
  ces-k3d list
  ces-k3d open dev1
  ces-k3d registry status
  ces-k3d cluster kubeconfig dev1`),
		kong.ConfigureHelp(kong.HelpOptions{
			Summary: true,
			Tree:    true,
		}),
	)
	if err != nil {
		return err
	}

	ctx, err := parser.Parse(args)
	if err != nil {
		return err
	}

	if err := ctx.Run(application); err != nil {
		return err
	}

	return nil
}

func (c *ListCmd) Run(application *app.App) error    { return application.List() }
func (c *DoctorCmd) Run(application *app.App) error  { return application.Doctor() }
func (c *VersionCmd) Run(application *app.App) error { return application.Version() }
func (c *OpenCmd) Run(application *app.App) error    { return application.Open(c.Name) }
func (c *CreateCmd) Run(application *app.App) error  { return application.Create(c.Name) }
func (c *StartCmd) Run(application *app.App) error   { return application.Start(c.Name) }
func (c *StopCmd) Run(application *app.App) error    { return application.Stop(c.Name) }
func (c *DeleteCmd) Run(application *app.App) error  { return application.Delete(c.Name) }
func (c *InstallCmd) Run(application *app.App) error { return application.Install(c.Name) }

func (c *RegistryStartCmd) Run(application *app.App) error  { return application.RegistryStart() }
func (c *RegistryStopCmd) Run(application *app.App) error   { return application.RegistryStop() }
func (c *RegistryDeleteCmd) Run(application *app.App) error { return application.RegistryDelete() }
func (c *RegistryStatusCmd) Run(application *app.App) error { return application.RegistryStatus() }

func (c *ClusterCreateCmd) Run(application *app.App) error { return application.ClusterCreate(c.Name) }
func (c *ClusterDeleteCmd) Run(application *app.App) error { return application.ClusterDelete(c.Name) }
func (c *ClusterKubeconfigCmd) Run(application *app.App) error {
	return application.ClusterKubeconfig(c.Name)
}
