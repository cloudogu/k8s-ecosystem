package app

import "github.com/alecthomas/kong"

type CLI struct {
	List   ListCmd   `cmd:"" help:"List managed local k3d ecosystems."`
	Create CreateCmd `cmd:"" help:"Create a new ecosystem with registries, cluster and LOP installation."`
	Start  StartCmd  `cmd:"" help:"Start an existing ecosystem and refresh its dedicated kubeconfig."`
	Stop   StopCmd   `cmd:"" help:"Stop an existing ecosystem cluster."`
	Delete DeleteCmd `cmd:"" help:"Delete an ecosystem cluster and its generated local files."`
}

type ListCmd struct{}

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

func Parse(args []string) (*App, error) {
	application, err := New()
	if err != nil {
		return nil, err
	}

	model := &CLI{}
	parser, err := kong.New(
		model,
		kong.Name("ces-k3d"),
		kong.Description(`Manage local k3d-based CES development environments with a minimal workflow.

Examples:
  ces-k3d create dev1
  ces-k3d list
  ces-k3d start dev1
  ces-k3d stop dev1
  ces-k3d delete dev1`),
		kong.ConfigureHelp(kong.HelpOptions{
			Summary: true,
			Tree:    true,
		}),
	)
	if err != nil {
		return nil, err
	}

	ctx, err := parser.Parse(args)
	if err != nil {
		return nil, err
	}

	if err := ctx.Run(application); err != nil {
		return nil, err
	}

	return application, nil
}

func (c *ListCmd) Run(application *App) error   { return application.List() }
func (c *CreateCmd) Run(application *App) error { return application.Create(c.Name) }
func (c *StartCmd) Run(application *App) error  { return application.Start(c.Name) }
func (c *StopCmd) Run(application *App) error   { return application.Stop(c.Name) }
func (c *DeleteCmd) Run(application *App) error { return application.Delete(c.Name) }
