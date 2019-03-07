package downloadstemcell

import (
	"fmt"
	pivnetClient "github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"log"
	"os"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/logshim"
)

type Config struct {
	OS           string `short:"o" long:"os" description:"Stemcell OS name"`
	Version      string `short:"v" long:"version" description:"Stemcell version"`
	Floating     bool
	PivnetClient pivnetClient.Client
	PivnetToken  string `long:"pivnet-token" description:"Authentication token for PivNet" env:"PIVNET_TOKEN"`
}

func stemcellOSToSlug(os string) string {
	switch os {
	case "ubuntu-trusty":
		return "stemcells-ubuntu"
	case "ubuntu-xenial":
		return "stemcells-ubuntu-xenial"
	}
	return ""
}

func (cmd *Config) DownloadStemcell() error {
	// get releases for a given slug
	// If floating,
	//    Pick latest version
	//    set version
	// else set version
	// For slug and release id, get files
	// Find the file to download
	// output file to stdout

	slug := stemcellOSToSlug(cmd.OS)

	releases, err := cmd.PivnetClient.ListReleases(slug)
	if err != nil {
		fmt.Print(err.Error())
		return err
	}
	fmt.Printf("found %d releases\n", len(releases))

	return nil
}

func (cmd *Config) Execute(args []string) error {
	stdoutLogger := log.New(os.Stdout, "", log.LstdFlags)
	stderrLogger := log.New(os.Stderr, "", log.LstdFlags)

	logger := logshim.NewLogShim(stdoutLogger, stderrLogger, true)

	cmd.PivnetClient = &pivnetClient.PivNetClient{
		PivnetClient: pivnet.NewClient(pivnet.ClientConfig{
			Host:  pivnet.DefaultHost,
			Token: cmd.PivnetToken,
		}, logger),
	}
	return cmd.DownloadStemcell()
}
