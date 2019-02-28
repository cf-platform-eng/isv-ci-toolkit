package main

import (
	"fmt"
	"os"

	"github.com/cf-platform-eng/isv-ci-toolkit/tileinspect"
	"github.com/cf-platform-eng/isv-ci-toolkit/tileinspect/metadata"
	"github.com/jessevdk/go-flags"
)

var metadataOpts metadata.Config
var config tileinspect.Config
var parser = flags.NewParser(&config, flags.Default)

func main() {
	_, err := parser.AddCommand(
		"metadata",
		"Dump metadata",
		"Dump tile metadata to stdout",
		&metadataOpts,
	)

	if err != nil {
		fmt.Println("Could not add metadata command")
		os.Exit(1)
	}

	//cmds := parser.Commands()
	//for _, command := range cmds {
	//	fmt.Println(command.Name)
	//}
	
	_, err = parser.Parse()
	if err != nil {
		//fmt.Print(err)
		os.Exit(1)
	}
}


