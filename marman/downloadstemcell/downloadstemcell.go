package downloadstemcell

import (
	"fmt"
	"log"
	"os"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/logshim"
)

type Config struct {
	OS          string `short:"o" long:"os" description:"Stemcell OS name"`
	Version     string `short:"v" long:"version" description:"Stemcell version"`
	Floating    bool
	
	// TODO: Can this go into the top level config structure?
	PivnetToken string `long:"pivnet-token" description:"Authentication token for PivNet" env:"PIVNET_TOKEN"`
}

func StemcellOSToSlug(os string) string {
	switch os {
	case "ubuntu-trusty":
		return "stemcells-ubuntu"
	case "ubuntu-xenial":
		return "stemcells-ubuntu-xenial"
	}
	return ""
}

func (cmd *Config) Execute(args []string) error {
	// TODO: logger can't be nil

	stdoutLogger := log.New(os.Stdout, "", log.LstdFlags)
	stderrLogger := log.New(os.Stderr, "", log.LstdFlags)

	logger := logshim.NewLogShim(stdoutLogger, stderrLogger, true)

	client := pivnet.NewClient(pivnet.ClientConfig{
		Host: pivnet.DefaultHost,
		Token: cmd.PivnetToken,
	}, logger)

	releases, err := client.Releases.List(StemcellOSToSlug(cmd.OS))
	if err != nil {
		fmt.Print(err.Error())
		return err
	}
	fmt.Printf("found %d releases", len(releases))

	return nil
}
