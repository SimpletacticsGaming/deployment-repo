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

func main() {
	before, err := gitOutput("rev-parse", "HEAD~1")
	if err != nil {
		exitErr(fmt.Sprintf("failed to resolve previous commit: %v", err))
	}

	after, err := gitOutput("rev-parse", "HEAD")
	if err != nil {
		exitErr(fmt.Sprintf("failed to resolve current commit: %v", err))
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
	return strings.TrimSpace(stdout.String()), nil
}

func uniqueComposeDirs(files []string) []string {
	seen := make(map[string]struct{})
	for _, file := range files {
		file = strings.TrimSpace(file)
		if file == "" {
			continue
		}
		_, stack := composeDirForFile(file)
		if stack != "" {
			seen[stack] = struct{}{}
		}
	}
	dirs := make([]string, 0, len(seen))
	for stack := range seen {
		dirs = append(dirs, stack)
	}
	return dirs
}

func composeDirForFile(path string) (string, string) {
	clean := filepath.ToSlash(strings.TrimPrefix(path, "./"))
	parts := strings.Split(clean, "/")
	if len(parts) < 2 || parts[0] == "" {
		return "", ""
	}

	if len(parts) >= 3 && parts[1] != "" {
		subdir := filepath.Join(parts[0], parts[1])
		if _, err := os.Stat(filepath.Join(subdir, "docker-compose.yaml")); err == nil {
			return subdir, parts[0] + "/" + parts[1]
		}
	}

	top := parts[0]
	if _, err := os.Stat(filepath.Join(top, "docker-compose.yaml")); err == nil {
		return top, top
	}
	return "", ""
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
