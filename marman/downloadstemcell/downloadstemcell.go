package downloadstemcell

import (
	"errors"
	"log"
	"os"
	"strings"

	pivnetClient "github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	. "github.com/pkg/errors"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/logshim"
)

type Config struct {
	OS           string `short:"o" long:"os" description:"Stemcell OS name"`
	Version      string `short:"v" long:"version" description:"Stemcell version"`
	Floating     bool   `short:"f" long:"floating" description:"Pick the latest stemcell version for this version"`
	PivnetClient pivnetClient.Client
	PivnetToken  string `long:"pivnet-token" description:"Authentication token for PivNet" env:"PIVNET_TOKEN"`
}

func stemcellOSToSlug(os string) (string, error) {
	switch os {
	case "ubuntu-trusty":
		return "stemcells-ubuntu", nil
	case "ubuntu-xenial":
		return "stemcells-ubuntu-xenial", nil
	}
	return "", errors.New("invalid stemcell os")
}

func IsNewerRelease(releaseA, releaseB pivnet.Release) bool {
	return strings.Compare(releaseA.Version, releaseB.Version) > 0
}

func (cmd *Config) DownloadStemcell() error {
	if cmd.OS == "" {
		return errors.New("missing stemcell os")
	}

	slug, err := stemcellOSToSlug(cmd.OS)
	if err != nil {
		return err
	}

	if cmd.Version == "" {
		return errors.New("missing stemcell version")
	}

	releases, err := cmd.PivnetClient.ListReleases(slug)
	if err != nil {
		return Wrapf(err, "failed to list releases for slug %s", slug)
	}

	var stemcellRelease pivnet.Release
	for _, release := range releases {
		if cmd.Floating {
			if strings.HasPrefix(release.Version, cmd.Version + ".") && IsNewerRelease(release, stemcellRelease) {
				stemcellRelease = release
			}
		} else if cmd.Version == release.Version {
			stemcellRelease = release
		}
	}

	if stemcellRelease.ID == 0 {
		return errors.New("no releases found for the required stemcell version")
	}

	_, err = cmd.PivnetClient.ListFilesForRelease(slug, stemcellRelease.ID)
	if err != nil {
		return Wrapf(err, "failed to list release files for %s:%s (%d)", slug, stemcellRelease.Version, stemcellRelease.ID)
	}

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
