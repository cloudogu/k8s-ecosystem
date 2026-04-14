package app

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/cloudogu/k8s-ecosystem/k3d/internal/config"
	"github.com/cloudogu/k8s-ecosystem/k3d/internal/system"
)

type hostsService struct {
	config config.Config
	runner system.Runner
}

func newHostsService(cfg config.Config, runner system.Runner) HostsManager {
	return &hostsService{
		config: cfg,
		runner: runner,
	}
}

func (s *hostsService) EnsureRegistryEntries() error {
	if !s.config.Global.ManageHostsFile {
		return nil
	}
	content, err := os.ReadFile("/etc/hosts")
	if err != nil {
		return err
	}

	marker := "# k3d-registry-stack"
	lines := strings.Split(strings.ReplaceAll(string(content), "\r\n", "\n"), "\n")
	filtered := make([]string, 0, len(lines)+1)
	for _, line := range lines {
		if strings.Contains(line, marker) {
			continue
		}
		filtered = append(filtered, line)
	}
	filtered = append(filtered, fmt.Sprintf("127.0.0.1 %s k3d-%s %s k3d-%s %s",
		s.config.Global.LocalRegistryDevName,
		s.config.Global.LocalRegistryDevName,
		s.config.Global.LocalRegistryProxyName,
		s.config.Global.LocalRegistryProxyName,
		marker,
	))
	return s.writeHostsContent(filtered)
}

func (s *hostsService) RemoveRegistryEntries() error {
	if !s.config.Global.ManageHostsFile {
		return nil
	}
	content, err := os.ReadFile("/etc/hosts")
	if err != nil {
		return err
	}

	marker := "# k3d-registry-stack"
	lines := strings.Split(strings.ReplaceAll(string(content), "\r\n", "\n"), "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.Contains(line, marker) {
			continue
		}
		filtered = append(filtered, line)
	}
	return s.writeHostsContent(filtered)
}

func (s *hostsService) EnsureHostEntry(name, fqdn, hostIP string) error {
	if !s.config.Global.ManageHostsFile || fqdn == "" || hostIP == "" {
		return nil
	}
	content, err := os.ReadFile("/etc/hosts")
	if err != nil {
		return fmt.Errorf("read /etc/hosts: %w", err)
	}

	marker := "k3d-ecosystem:" + name
	lines := strings.Split(strings.ReplaceAll(string(content), "\r\n", "\n"), "\n")
	filtered := make([]string, 0, len(lines)+1)
	for _, line := range lines {
		if strings.Contains(line, marker) {
			continue
		}
		if lineContainsHost(line, fqdn) {
			continue
		}
		filtered = append(filtered, line)
	}
	filtered = append(filtered, fmt.Sprintf("%s %s # %s", hostIP, fqdn, marker))

	if err := s.writeHostsContent(filtered); err != nil {
		return fmt.Errorf("failed to update /etc/hosts for %s: %w", fqdn, err)
	}
	return nil
}

func (s *hostsService) RemoveHostEntry(name, fqdn string) error {
	if !s.config.Global.ManageHostsFile || fqdn == "" {
		return nil
	}
	content, err := os.ReadFile("/etc/hosts")
	if err != nil {
		return fmt.Errorf("read /etc/hosts: %w", err)
	}

	marker := "k3d-ecosystem:" + name
	lines := strings.Split(strings.ReplaceAll(string(content), "\r\n", "\n"), "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.Contains(line, marker) {
			continue
		}
		if lineContainsHost(line, fqdn) {
			continue
		}
		filtered = append(filtered, line)
	}

	if err := s.writeHostsContent(filtered); err != nil {
		return fmt.Errorf("failed to update /etc/hosts for %s: %w", fqdn, err)
	}
	return nil
}

func (s *hostsService) writeHostsContent(lines []string) error {
	newContent := strings.Join(lines, "\n")
	if !strings.HasSuffix(newContent, "\n") {
		newContent += "\n"
	}

	tempFile, err := os.CreateTemp("", "ces-k3d-hosts-*")
	if err != nil {
		return err
	}
	tempPath := tempFile.Name()
	defer os.Remove(tempPath)

	if _, err := tempFile.WriteString(newContent); err != nil {
		_ = tempFile.Close()
		return err
	}
	if err := tempFile.Close(); err != nil {
		return err
	}

	if os.Geteuid() == 0 {
		return s.runner.Run("install", "-m", "644", tempPath, "/etc/hosts")
	}
	if err := s.runner.LookPath("sudo"); err == nil {
		return s.runner.Run("sudo", "install", "-m", "644", tempPath, "/etc/hosts")
	}
	return errors.New("failed to update /etc/hosts; install sudo or run as root")
}
