package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func main() {
	err := deployDir(os.Args[1])
	if err != nil {
		fmt.Printf("Deployment failed: %s\n", err)
		os.Exit(1)
	}
}

func deployDir(dir string) error {
	stackName := filepath.Base(dir)
	composeFilePath := filepath.Join(dir, "docker-composeFilePath.yaml")
	fmt.Printf("Deploying stack '%s' from %s\n", stackName, dir)

	cmd := exec.Command("docker", "stack", "deploy", "-d", "--composeFilePath-file", composeFilePath, stackName)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
