package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

const zeroSHA = "0000000000000000000000000000000000000000"

func main() {
	before := strings.TrimSpace(os.Getenv("BEFORE_SHA"))
	if before == "" {
		exitErr("BEFORE_SHA is required")
	}

	after := strings.TrimSpace(os.Getenv("GITHUB_SHA"))
	if after == "" {
		exitErr("GITHUB_SHA is required")
	}

	if before == zeroSHA {
		root, err := gitOutput("rev-list", "--max-parents=0", "HEAD")
		if err != nil {
			exitErr(fmt.Sprintf("failed to resolve root commit: %v", err))
		}
		before = strings.TrimSpace(root)
	}

	changed, err := gitOutput("diff", "--name-only", before, after)
	if err != nil {
		exitErr(fmt.Sprintf("failed to diff commits: %v", err))
	}

	dirs := uniqueComposeDirs(strings.FieldsFunc(changed, func(r rune) bool { return r == '\n' || r == '\r' }))
	sort.Strings(dirs)

	payload, err := json.Marshal(dirs)
	if err != nil {
		exitErr(fmt.Sprintf("failed to marshal matrix: %v", err))
	}

	outputPath := os.Getenv("GITHUB_OUTPUT")
	if outputPath == "" {
		exitErr("GITHUB_OUTPUT is required")
	}

	if err := appendOutput(outputPath, "matrix", string(payload)); err != nil {
		exitErr(fmt.Sprintf("failed to write output: %v", err))
	}
}

func gitOutput(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("%v: %s", err, strings.TrimSpace(stderr.String()))
	}
	return stdout.String(), nil
}

func uniqueComposeDirs(files []string) []string {
	seen := make(map[string]struct{})
	for _, file := range files {
		file = strings.TrimSpace(file)
		if file == "" {
			continue
		}
		dir, _ := splitTopDir(file)
		if dir == "" {
			continue
		}
		if _, err := os.Stat(filepath.Join(dir, "docker-compose.yaml")); err == nil {
			seen[dir] = struct{}{}
		}
	}
	dirs := make([]string, 0, len(seen))
	for dir := range seen {
		dirs = append(dirs, dir)
	}
	return dirs
}

func splitTopDir(path string) (string, bool) {
	clean := filepath.ToSlash(strings.TrimPrefix(path, "./"))
	parts := strings.SplitN(clean, "/", 2)
	if len(parts) < 2 || parts[0] == "" {
		return "", false
	}
	return parts[0], true
}

func appendOutput(path, key, value string) error {
	f, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = fmt.Fprintf(f, "%s=%s\n", key, value)
	return err
}

func exitErr(message string) {
	fmt.Fprintln(os.Stderr, message)
	os.Exit(1)
}
