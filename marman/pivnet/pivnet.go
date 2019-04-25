package pivnet

import (
	"io"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/download"
)

//go:generate counterfeiter Client
type Client interface {
	AcceptEULA(product string, releaseID int) error
	ListReleases(product string) ([]pivnet.Release, error)
	ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error)
	DownloadProductFile(
		location *download.FileInfo,
		productSlug string,
		releaseID int,
		productFileID int,
		progressWriter io.Writer) error
}

type PivNetClient struct {
	PivnetClient pivnet.Client
}

func (c *PivNetClient) AcceptEULA(product string, releaseID int) error {
	return c.PivnetClient.EULA.Accept(product, releaseID)
}

func (c *PivNetClient) ListReleases(product string) ([]pivnet.Release, error) {
	return c.PivnetClient.Releases.List(product)
}

func (c *PivNetClient) ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error) {
	return c.PivnetClient.ProductFiles.ListForRelease(product, releaseID)
}

func (c *PivNetClient) DownloadProductFile(
	location *download.FileInfo,
	productSlug string,
	releaseID int,
	productFileID int,
	progressWriter io.Writer) error {
	return c.PivnetClient.ProductFiles.DownloadForRelease(location, productSlug, releaseID, productFileID, progressWriter)
}
