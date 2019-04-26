package pivnet

import (
	"io"
	"os"

	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/download"
)

//go:generate counterfeiter Wrapper
type Wrapper interface {
	AcceptEULA(product string, releaseID int) error
	ListReleases(product string) ([]pivnet.Release, error)
	ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error)
	DownloadProductFile(
		location *download.FileInfo,
		productSlug string,
		releaseID int,
		productFileID int,
		progressWriter io.Writer) error
	NewFileInfo(file *os.File) (*download.FileInfo, error)
}

type ClientWrapper struct {
	PivnetClient pivnet.Client
}

func (c *ClientWrapper) AcceptEULA(product string, releaseID int) error {
	return c.PivnetClient.EULA.Accept(product, releaseID)
}

func (c *ClientWrapper) ListReleases(product string) ([]pivnet.Release, error) {
	return c.PivnetClient.Releases.List(product)
}

func (c *ClientWrapper) ListFilesForRelease(product string, releaseID int) ([]pivnet.ProductFile, error) {
	return c.PivnetClient.ProductFiles.ListForRelease(product, releaseID)
}

func (c *ClientWrapper) DownloadProductFile(
	location *download.FileInfo,
	productSlug string,
	releaseID int,
	productFileID int,
	progressWriter io.Writer) error {
	return c.PivnetClient.ProductFiles.DownloadForRelease(location, productSlug, releaseID, productFileID, progressWriter)
}

func (c *ClientWrapper) NewFileInfo(file *os.File) (*download.FileInfo, error) {
	return download.NewFileInfo(file)
}
