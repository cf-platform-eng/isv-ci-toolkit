package pivnet

import (
	"errors"
	"github.com/pivotal-cf/go-pivnet/logshim"
	"log"
	"os"
	"path"

	"code.cloudfoundry.org/lager"
	"github.com/Masterminds/semver"
	. "github.com/pkg/errors"

	"github.com/pivotal-cf/go-pivnet"
)

//go:generate counterfeiter Client
type Client interface {
	AcceptEULA(product string, releaseID int) error
	ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error)
	FindReleaseByVersionConstraint(slug string, constraint *semver.Constraints) (*pivnet.Release, error)
	DownloadFile(slug string, releaseID int, productFile *pivnet.ProductFile) error
}

type PivNetClient struct {
	Logger  lager.Logger
	Wrapper Wrapper
}

func NewPivNetClient(token string) *PivNetClient {
	// Why can't I use lager.NewLogger here?
	stdoutLogger := log.New(os.Stdout, "", log.LstdFlags)
	stderrLogger := log.New(os.Stderr, "", log.LstdFlags)
	pivnetLogger := logshim.NewLogShim(stdoutLogger, stderrLogger, false)

	return &PivNetClient{
		Wrapper: &ClientWrapper{
			pivnet.NewClient(pivnet.ClientConfig{
				Host:  pivnet.DefaultHost,
				Token: token,
			}, pivnetLogger),
		},
		Logger: lager.NewLogger("pivnet"),
	}
}

func (c *PivNetClient) FindReleaseByVersionConstraint(slug string, constraint *semver.Constraints) (*pivnet.Release, error) {
	releases, err := c.Wrapper.ListReleases(slug)
	if err != nil {
		return nil, Wrapf(err, "failed to list releases for slug %s", slug)
	}

	var chosenRelease pivnet.Release
	chosenVersion, _ := semver.NewVersion("0")
	for _, release := range releases {
		releaseVersion, err := semver.NewVersion(release.Version)
		if err != nil {
			c.Logger.Debug("invalid release version found", lager.Data{
				"slug":    slug,
				"version": release.Version,
			})
		} else if constraint.Check(releaseVersion) {
			if releaseVersion.GreaterThan(chosenVersion) {
				chosenRelease = release
				chosenVersion = releaseVersion
			}
		}
	}

	if chosenRelease.ID == 0 {
		return nil, errors.New("no releases found")
	}

	return &chosenRelease, nil
}

func (c *PivNetClient) DownloadFile(slug string, releaseID int, productFile *pivnet.ProductFile) error {
	filename := path.Base(productFile.AWSObjectKey)
	file, err := os.Create(filename)
	if err != nil {
		return Wrapf(err, "failed to create file: %s", filename)
	}

	fileInfo, err := c.Wrapper.NewFileInfo(file)
	if err != nil {
		return Wrapf(err, "failed to load file info: %s", filename)
	}

	err = c.Wrapper.DownloadProductFile(fileInfo, slug, releaseID, productFile.ID, os.Stdout)
	if err != nil {
		return Wrapf(err, "failed to download file: %s", filename)
	}

	return nil
}

func (c *PivNetClient) AcceptEULA(product string, releaseID int) error {
	return c.Wrapper.AcceptEULA(product, releaseID)
}

func (c *PivNetClient) ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error) {
	return c.Wrapper.ListFilesForRelease(product, releaseID)
}
