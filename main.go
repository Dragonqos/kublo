package main

import (
	"embed"
	_ "embed"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	tmpFolderPrefix = "kublo-"
	tplFolder       = "tpl"
)

//go:embed build.sh
var build string

//go:embed tpl/**/*
var tplFiles embed.FS

func main() {
	tmpDirPath, clean := createTmp()
	defer clean()

	fmt.Println(tmpDirPath)

	err := writeEmbeddedFiles(tmpDirPath)
	if err != nil {
		fmt.Printf("Error writing embedded files: %v", err)
		return
	}

	build = strings.Replace(build, `TPL_DIR_PATH="./tpl"`, fmt.Sprintf(`TPL_DIR_PATH="%v"`, tmpDirPath), -1)

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

func createTmp() (string, func()) {
	// Create a temporary directory
	tempDir, err := os.MkdirTemp("", tmpFolderPrefix)
	if err != nil {
		fmt.Printf("Error creating temp directory: %v\n", err)
		return tempDir, func() {}
	}

	return tempDir, func() { _ = os.RemoveAll(tempDir) } // Clean up the temp directory when done
}

func writeEmbeddedFiles(dest string) error {
	return fs.WalkDir(tplFiles, tplFolder, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if !d.IsDir() {
			data, err := tplFiles.ReadFile(path)
			if err != nil {
				return err
			}

			destPath := filepath.Join(dest, strings.TrimPrefix(path, tplFolder+"/"))
			if err = writeFile(destPath, data); err != nil {
				return err
			}
		}

		return nil
	})
}

func writeFile(filename string, content []byte) error {
	if err := os.MkdirAll(filepath.Dir(filename), 0755); err != nil {
		return err
	}

	return os.WriteFile(filename, content, 0644)
}
