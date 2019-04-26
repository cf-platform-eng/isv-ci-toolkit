package pivnet

import (
	"errors"
	"io"

	"code.cloudfoundry.org/lager"
	"github.com/Masterminds/semver"
	. "github.com/pkg/errors"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/download"
)

//go:generate counterfeiter Client
type Client interface {
	AcceptEULA(product string, releaseID int) error
	ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error)
	DownloadProductFile(
		location *download.FileInfo,
		productSlug string,
		releaseID int,
		productFileID int,
		progressWriter io.Writer) error

	FindReleaseByVersionConstraint(slug string, constraint *semver.Constraints) (*pivnet.Release, error)
}

type PivNetClient struct {
	Logger  lager.Logger
	Wrapper Wrapper
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

func (c *PivNetClient) AcceptEULA(product string, releaseID int) error {
	return c.Wrapper.AcceptEULA(product, releaseID)
}

func (c *PivNetClient) ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error) {
	return c.Wrapper.ListFilesForRelease(product, releaseID)
}

func (c *PivNetClient) DownloadProductFile(
	location *download.FileInfo,
	productSlug string,
	releaseID int,
	productFileID int,
	progressWriter io.Writer) error {
	return c.Wrapper.DownloadProductFile(location, productSlug, releaseID, productFileID, progressWriter)
}
