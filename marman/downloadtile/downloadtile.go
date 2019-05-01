package downloadtile

import (
	"strings"

	"github.com/Masterminds/semver"

	pivnetClient "github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"github.com/pivotal-cf/go-pivnet"
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

func (cmd *Config) FindFile(productFiles []pivnet.ProductFile, id int) (*pivnet.ProductFile, error) {
	var (
		pattern string
		err     error
	)

	switch cmd.Name {
	case "pas":
		pattern = "Pivotal Application Service"
	case "srt":
		pattern = "Small Footprint PAS"
	default:
		return nil, errors.Errorf("unable to find tile with name %s", cmd.Name)
	}

	var productFile *pivnet.ProductFile
	for _, fileUnderConsideration := range productFiles {
		if strings.Contains(fileUnderConsideration.Name, pattern) {
			productFile = &fileUnderConsideration
			break
		}
	}

	if productFile == nil {
		err = errors.Errorf("unable to find the tile with name %s", cmd.Name)
	}

	return productFile, err
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

	productFiles, err := cmd.PivnetClient.ListFilesForRelease(cmd.Slug, release.ID)
	if err != nil {
		return errors.Wrapf(err, "could not list files for release %d on slug %s", release.ID, cmd.Slug)
	}

	productFile, err := cmd.FindFile(productFiles, release.ID)
	if err != nil {
		return err
	}

	err = cmd.PivnetClient.AcceptEULA(cmd.Slug, release.ID)
	if err != nil {
		return errors.Wrapf(err, "could not accept the eula for slug %s", cmd.Slug)
	}

	err = cmd.PivnetClient.DownloadFile(cmd.Slug, release.ID, productFile)

	return err
}

func (cmd *Config) Execute(args []string) error {
	cmd.PivnetClient = pivnetClient.NewPivNetClient(cmd.PivnetToken)
	return cmd.DownloadTile()
}
