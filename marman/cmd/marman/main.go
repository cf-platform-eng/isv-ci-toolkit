package main

import (
	"fmt"
	"os"

	"github.com/cf-platform-eng/isv-ci-toolkit/marman"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadstemcell"

	"github.com/jessevdk/go-flags"
)

var downloadStemcellOpts downloadstemcell.Config
var config marman.Config
var parser = flags.NewParser(&config, flags.Default)

func main() {
	_, err := parser.AddCommand(
		"download-stemcell",
		"Download stemcell",
		"Download stemcell from PivNet",
		&downloadStemcellOpts,
	)
	if err != nil {
		fmt.Println("Could not add download-stemcell command")
		os.Exit(1)
	}

	//_, err = parser.AddCommand(
	//	"stemcell",
	//	"Dump stemcell requirement",
	//	"Dump stemcell requirement to stdout",
	//	&stemcellOpts,
	//)
	//if err != nil {
	//	fmt.Println("Could not add stemcell command")
	//	os.Exit(1)
	//}

	_, err = parser.Parse()
	if err != nil {
		// TODO: look into printing a usage on bad commands
		os.Exit(1)
	}
}
