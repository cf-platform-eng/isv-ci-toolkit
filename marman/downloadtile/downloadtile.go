package downloadtile

import (
	"log"
	"os"

	"github.com/Masterminds/semver"

	pivnetClient "github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/logshim"
	"github.com/pkg/errors"
)

type Config struct {
	Name         string `short:"n" long:"name" description:"Tile name"`
	Slug         string `short:"s" long:"slug" description:"PivNet slug name override"`
	Version      string `short:"v" long:"version" description:"Tile version"`
	PivnetClient pivnetClient.Client
	PivnetToken  string `long:"pivnet-token" description:"Authentication token for PivNet" env:"PIVNET_TOKEN"`
}

func nameToSlug(name string) (string, error) {
	switch name {
	case "pas":
		return "cf", nil
	case "srt":
		return "cf", nil
	default:
		return "", errors.Errorf("unknown tile name %s", name)
	}
}

func (cmd *Config) DownloadTile() error {
	if cmd.Slug == "" {
		slug, err := nameToSlug(cmd.Name)
		if err != nil {
			return errors.Wrapf(err, "could not find slug for tile name %s", cmd.Name)
		}
		cmd.Slug = slug
	}

	versionConstraint, err := semver.NewConstraint(cmd.Version)
	if err != nil {
		return errors.Wrapf(err, "tile version is not valid semver")
	}

	release, err := cmd.PivnetClient.FindReleaseByVersionConstraint(cmd.Slug, versionConstraint)
	if err != nil {
		return errors.Wrapf(err, "could not list releases for slug %s", cmd.Slug)
	}

	_, err = cmd.PivnetClient.ListFilesForRelease(cmd.Slug, release.ID)
	if err != nil {
		return errors.Wrapf(err, "could not list files for release %d on slug %s", release.ID, cmd.Slug)
	}

	return nil
}

func (cmd *Config) Execute(args []string) error {
	stdoutLogger := log.New(os.Stdout, "", log.LstdFlags)
	stderrLogger := log.New(os.Stderr, "", log.LstdFlags)

	logger := logshim.NewLogShim(stdoutLogger, stderrLogger, true)
	cmd.PivnetClient = &pivnetClient.PivNetClient{
		Wrapper: &pivnetClient.ClientWrapper{
			PivnetClient: pivnet.NewClient(pivnet.ClientConfig{
				Host:  pivnet.DefaultHost,
				Token: cmd.PivnetToken,
			}, logger),
		},
	}
	return cmd.DownloadTile()
}
