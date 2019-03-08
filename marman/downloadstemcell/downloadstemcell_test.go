package downloadstemcell_test

import (
	"errors"

	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadstemcell"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet/pivnetfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/pivotal-cf/go-pivnet"
)

var _ = Describe("Download Stemcell", func() {
	var (
		pivnetClient *pivnetfakes.FakeClient
		cmd          *downloadstemcell.Config
	)

	BeforeEach(func() {
		pivnetClient = &pivnetfakes.FakeClient{}
		cmd = &downloadstemcell.Config{
			OS:           "ubuntu-xenial",
			PivnetClient: pivnetClient,
		}
	})

	Context("Fixed stemcell version", func() {
		BeforeEach(func() {
			cmd.Version = "170.12345"
			cmd.Floating = false
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      11111,
					Version: "170.11111",
				},
				{
					ID:      123456,
					Version: "170.12345",
				},
			}, nil)

			pivnetClient.ListFilesForReleaseReturns([]pivnet.FileGroup{
				{
					ProductFiles: []pivnet.ProductFile{
						{
							Links: &pivnet.Links{
								Download: map[string]string{
									"href": "my-download-link",
								},
							},
						},
					},
				},
			}, nil)
		})

		It("downloads the stemcell", func() {
			err := cmd.DownloadStemcell()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from PivNet", func() {
				Expect(pivnetClient.ListReleasesCallCount()).To(Equal(1))
				slug := pivnetClient.ListReleasesArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
			})

			By("getting the list of product files from PivNet", func() {
				Expect(pivnetClient.ListFilesForReleaseCallCount()).To(Equal(1))
				slug, releaseID := pivnetClient.ListFilesForReleaseArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
				Expect(releaseID).To(Equal(123456))
			})
		})

		Context("PivNet fails to list releases", func() {
			BeforeEach(func() {
				pivnetClient.ListReleasesReturns([]pivnet.Release{}, errors.New("list releases error"))
			})

			It("returns an error", func() {
				err := cmd.DownloadStemcell()
				Expect(err).To(HaveOccurred())

				Expect(err.Error()).To(ContainSubstring("list releases error"))
			})
		})

		Context("PivNet returns no releases", func() {
			BeforeEach(func() {
				pivnetClient.ListReleasesReturns([]pivnet.Release{}, nil)
			})

			It("returns an error", func() {
				err := cmd.DownloadStemcell()
				Expect(err).To(HaveOccurred())
			})
		})

		Context("PivNet returns no releases with matching versions", func() {
			BeforeEach(func() {
				pivnetClient.ListReleasesReturns([]pivnet.Release{
					{
						ID:      11111,
						Version: "170.11111",
					},
				}, nil)
			})

			It("returns an error", func() {
				err := cmd.DownloadStemcell()
				Expect(err).To(HaveOccurred())
			})
		})

		Context("PivNet fails to list product files", func() {
			BeforeEach(func() {
				pivnetClient.ListFilesForReleaseReturns([]pivnet.FileGroup{}, errors.New("list files error"))
			})

			It("returns an error", func() {
				err := cmd.DownloadStemcell()
				Expect(err).To(HaveOccurred())
				Expect(err.Error()).To(ContainSubstring("list files error"))
			})
		})
	})

	Context("Floating stemcell version", func() {
		BeforeEach(func() {
			cmd.Version = "170"
			cmd.Floating = true
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      1,
					Version: "170.1",
				},
				{
					ID:      3,
					Version: "170.3",
				},
				{
					ID:      2,
					Version: "170.2",
				},
			}, nil)
		})

		It("downloads the latest stemcell", func() {
			err := cmd.DownloadStemcell()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from PivNet", func() {
				Expect(pivnetClient.ListReleasesCallCount()).To(Equal(1))
			})

			By("getting the list of product files from PivNet", func() {
				Expect(pivnetClient.ListFilesForReleaseCallCount()).To(Equal(1))
				slug, releaseID := pivnetClient.ListFilesForReleaseArgsForCall(0)

				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
				Expect(releaseID).To(Equal(3))
			})
		})
	})
})

var _ = Describe("Is Newer Release", func() {
	releaseVersionOne := pivnet.Release{Version: "1"}
	releaseVersionOneDotOne := pivnet.Release{Version: "1.1"}
	releaseVersionTwo := pivnet.Release{Version: "2"}
	//releaseVersionTwoDotOne := &pivnet.Release{Version: "2.1"}

	It("returns the correct value", func() {
		Expect(downloadstemcell.IsNewerRelease(releaseVersionOne, releaseVersionOne)).To(BeFalse())
		Expect(downloadstemcell.IsNewerRelease(releaseVersionOneDotOne, releaseVersionOne)).To(BeTrue())
		Expect(downloadstemcell.IsNewerRelease(releaseVersionTwo, releaseVersionOne)).To(BeTrue())

	})
})
