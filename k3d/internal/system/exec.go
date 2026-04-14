package system

import (
	"fmt"
	"os"
	"os/exec"
)

type Runner struct {
	Stdout *os.File
	Stderr *os.File
}

func NewRunner() Runner {
	return Runner{Stdout: os.Stdout, Stderr: os.Stderr}
}

func (r Runner) LookPath(name string) error {
	_, err := exec.LookPath(name)
	return err
}

func (r Runner) Run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = r.Stdout
	cmd.Stderr = r.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func (r Runner) RunWithEnv(env []string, name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = r.Stdout
	cmd.Stderr = r.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = env
	return cmd.Run()
}

func (r Runner) RunInDir(dir, name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stdout = r.Stdout
	cmd.Stderr = r.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func (r Runner) RunInDirWithEnv(dir string, env []string, name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stdout = r.Stdout
	cmd.Stderr = r.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = env
	return cmd.Run()
}

func (r Runner) Output(name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("%s %v: %w", name, args, err)
	}
	return output, nil
}
