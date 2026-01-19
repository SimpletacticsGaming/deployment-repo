package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	err := deployDir(os.Args[1])
	if err != nil {
		fmt.Printf("Deployment failed: %s\n", err)
		os.Exit(1)
	}
}

func deployDir(stackName string) error {
	fmt.Printf("Deploying stack '%s'\n", stackName)

	cmd := exec.Command("docker", "stack", "deploy", "-d", "--compose-file", "docker-compose.yaml", stackName, "--with-registry-auth")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
