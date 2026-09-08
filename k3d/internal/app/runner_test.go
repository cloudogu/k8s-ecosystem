package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRunnerRunVariants(t *testing.T) {
	binDir := t.TempDir()
	logPath := filepath.Join(t.TempDir(), "runner.log")
	prependPath(t, binDir)

	writeExecutable(t, binDir, "capture", `#!/bin/sh
{
  printf 'pwd=%s\n' "$PWD"
  printf 'args=%s\n' "$*"
  printf 'foo=%s\n' "$FOO"
} > "$RUNNER_LOG"
`)

	r := runner{stdout: os.Stdout, stderr: os.Stderr}

	t.Run("Run uses inherited environment", func(t *testing.T) {
		t.Setenv("RUNNER_LOG", logPath)
		t.Setenv("FOO", "from-parent")

		if err := r.Run("capture", "one", "two"); err != nil {
			t.Fatalf("Run() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "args=one two") || !strings.Contains(out, "foo=from-parent") {
			t.Fatalf("Run() log = %q", out)
		}
	})

	t.Run("RunWithEnv uses explicit environment", func(t *testing.T) {
		if err := r.RunWithEnv([]string{"RUNNER_LOG=" + logPath, "FOO=from-explicit"}, "capture", "three"); err != nil {
			t.Fatalf("RunWithEnv() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "args=three") || !strings.Contains(out, "foo=from-explicit") {
			t.Fatalf("RunWithEnv() log = %q", out)
		}
	})

	t.Run("RunInDir changes working directory", func(t *testing.T) {
		dir := t.TempDir()
		t.Setenv("RUNNER_LOG", logPath)
		t.Setenv("FOO", "cwd")

		if err := r.RunInDir(dir, "capture", "four"); err != nil {
			t.Fatalf("RunInDir() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "pwd="+dir) {
			t.Fatalf("RunInDir() log = %q", out)
		}
	})

	t.Run("RunInDirWithEnv changes working directory and environment", func(t *testing.T) {
		dir := t.TempDir()

		if err := r.RunInDirWithEnv(dir, []string{"RUNNER_LOG=" + logPath, "FOO=dir-env"}, "capture", "five"); err != nil {
			t.Fatalf("RunInDirWithEnv() error = %v", err)
		}

		out := readFile(t, logPath)
		if !strings.Contains(out, "pwd="+dir) || !strings.Contains(out, "foo=dir-env") {
			t.Fatalf("RunInDirWithEnv() log = %q", out)
		}
	})
}

func TestRunnerOutput(t *testing.T) {
	binDir := t.TempDir()
	prependPath(t, binDir)

	writeExecutable(t, binDir, "success-output", "#!/bin/sh\nprintf 'hello world'\n")
	writeExecutable(t, binDir, "fail-output", "#!/bin/sh\nexit 1\n")

	r := newRunner()

	t.Run("returns command output", func(t *testing.T) {
		out, err := r.Output("success-output")
		if err != nil {
			t.Fatalf("Output() error = %v", err)
		}
		if string(out) != "hello world" {
			t.Fatalf("Output() = %q", string(out))
		}
	})

	t.Run("wraps command failures", func(t *testing.T) {
		_, err := r.Output("fail-output", "arg1")
		if err == nil {
			t.Fatal("Output() expected error")
		}
		if !strings.Contains(err.Error(), "fail-output [arg1]") {
			t.Fatalf("unexpected error = %v", err)
		}
	})
}
