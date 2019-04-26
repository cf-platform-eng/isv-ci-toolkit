package main

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	"os"

	"github.com/cf-platform-eng/isv-ci-toolkit/marman"

	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadstemcell"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadtile"

	"github.com/jessevdk/go-flags"
)

var config marman.Config
var parser = flags.NewParser(&config, flags.Default)

func main() {
	downloadStemcellOpts := downloadstemcell.Config{
		Logger: lager.NewLogger("download-stemcell"),
	}
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

	downloadTileOpts := downloadtile.Config{}
	_, err = parser.AddCommand(
		"download-tile",
		"Download tile",
		"Download tile from PivNet",
		&downloadTileOpts,
	)
	if err != nil {
		fmt.Println("Could not add download-tile command")
		os.Exit(1)
	}

	_, err = parser.Parse()
	if err != nil {
		// TODO: look into printing a usage on bad commands
		os.Exit(1)
	}
}
