package pivnet

import "github.com/pivotal-cf/go-pivnet"

//go:generate counterfeiter Client
type Client interface {
	ListReleases(product string) ([]pivnet.Release, error)
	ListFilesForRelease(productSlug string, releaseID int) ([]pivnet.FileGroup, error)
}

type PivNetClient struct {
	PivnetClient pivnet.Client
}

func (c *PivNetClient) ListReleases(product string) ([]pivnet.Release, error) {
	return c.PivnetClient.Releases.List(product)
}

func (c *PivNetClient) ListFilesForRelease(productSlug string, releaseID int) ([]pivnet.FileGroup, error) {
	return c.PivnetClient.FileGroups.ListForRelease(productSlug, releaseID)
}