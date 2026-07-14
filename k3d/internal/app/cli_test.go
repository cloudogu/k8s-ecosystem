package app

import (
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	repoRoot := setupMinimalRepo(t)
	t.Chdir(repoRoot)

	t.Run("parses and runs list command", func(t *testing.T) {
		application, err := Parse([]string{"list"})
		if err != nil {
			t.Fatalf("Parse() error = %v", err)
		}
		if application == nil {
			t.Fatal("Parse() returned nil app")
		}
	})

	t.Run("returns parse error for missing create argument", func(t *testing.T) {
		_, err := Parse([]string{"create"})
		if err == nil {
			t.Fatal("Parse() expected error")
		}
		if !strings.Contains(err.Error(), `expected "<name>"`) {
			t.Fatalf("unexpected error = %v", err)
		}
	})
}
