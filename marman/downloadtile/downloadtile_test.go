package downloadtile_test

import (
	"errors"

	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadtile"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet/pivnetfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/pivotal-cf/go-pivnet"
)

var _ = Describe("Download Tile", func() {
	var (
		pivnetClient *pivnetfakes.FakeClient
		cmd          *downloadtile.Config
	)

	BeforeEach(func() {
		pivnetClient = &pivnetfakes.FakeClient{}
		cmd = &downloadtile.Config{
			Name:         "srt",
			PivnetClient: pivnetClient,
		}

		cmd.Version = "2.4.1"

		pivnetClient.FindReleaseByVersionConstraintReturns(&pivnet.Release{
			ID:      100,
			Version: "2.4.2",
		}, nil)

		pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
			{
				ID:   123,
				Name: "Small Footprint PAS",
				Links: &pivnet.Links{
					Download: map[string]string{
						"href": "srt-download-link",
					},
				},
			},
			{
				ID:   456,
				Name: "Pivotal Application Service",
				Links: &pivnet.Links{
					Download: map[string]string{
						"href": "pas-download-link",
					},
				},
			},
		}, nil)

		pivnetClient.AcceptEULAReturns(nil)
	})

	Context("Fixed tile version", func() {
		It("attempts to download the tile", func() {
			err := cmd.DownloadTile()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of product files from PivNet", func() {
				Expect(pivnetClient.ListFilesForReleaseCallCount()).To(Equal(1))
				slug, releaseID := pivnetClient.ListFilesForReleaseArgsForCall(0)
				Expect(slug).To(Equal("cf"))
				Expect(releaseID).To(Equal(100))
			})

			By("accepting the EULA", func() {
				Expect(pivnetClient.AcceptEULACallCount()).To(Equal(1))
				slug, releaseID := pivnetClient.AcceptEULAArgsForCall(0)
				Expect(slug).To(Equal("cf"))
				Expect(releaseID).To(Equal(100))
			})

			By("downloading the file", func() {
				Expect(pivnetClient.DownloadFileCallCount()).To(Equal(1))
				slug, releaseID, file := pivnetClient.DownloadFileArgsForCall(0)
				Expect(slug).To(Equal("cf"))
				Expect(releaseID).To(Equal(100))
				Expect(file.ID).To(Equal(123))
			})
		})
	})

	Context("Allows slug to override name", func() {
		It("attempts to download the tile using the slug override", func() {
			cmd = &downloadtile.Config{
				Name:         "srt",
				Slug:         "alternate-cf",
				Version:      "2.4.1",
				PivnetClient: pivnetClient,
			}

			err := cmd.DownloadTile()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of product files from PivNet", func() {
				Expect(pivnetClient.ListFilesForReleaseCallCount()).To(Equal(1))
				slug, releaseID := pivnetClient.ListFilesForReleaseArgsForCall(0)
				Expect(slug).To(Equal("alternate-cf"))
				Expect(releaseID).To(Equal(100))
			})
		})
	})

	Context("Version is not valid semver", func() {
		BeforeEach(func() {
			cmd.Version = "not-a-valid-version"
		})

		It("returns an error", func() {
			err := cmd.DownloadTile()
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(ContainSubstring("tile version is not valid semver"))
		})
	})

	Context("PivNet fails to find a matching release", func() {
		BeforeEach(func() {
			pivnetClient.FindReleaseByVersionConstraintReturns(nil, errors.New("list releases error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadTile()
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(ContainSubstring("list releases error"))
		})
	})

	Context("PivNet fails to list product files", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{}, errors.New("list files error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadTile()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("list files error"))
		})
	})

	Context("Failed to accept EULA", func() {
		BeforeEach(func() {
			pivnetClient.AcceptEULAReturns(errors.New("accept-eula-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadTile()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("accept-eula-error"))
		})
	})

	Context("Failed to download file", func() {
		BeforeEach(func() {
			pivnetClient.DownloadFileReturns(errors.New("download-file-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadTile()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("download-file-error"))
		})
	})
})
