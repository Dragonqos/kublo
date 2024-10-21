package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
)

//go:embed build.sh
var build string

func main() {
	command := exec.Command("/bin/sh", "-c", build)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	command.Stdin = os.Stdin

	// Run the command
	if err := command.Run(); err != nil {
		fmt.Printf("Error executing script: %v", err)
		return
	}
}
