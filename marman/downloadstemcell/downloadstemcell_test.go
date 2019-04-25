package downloadstemcell_test

import (
	"errors"
	"os"

	"code.cloudfoundry.org/lager"
	"github.com/Masterminds/semver"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadstemcell"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet/pivnetfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	"github.com/pivotal-cf/go-pivnet"
)

var _ = Describe("FindStemcellRelease", func() {
	var (
		pivnetClient *pivnetfakes.FakeClient
		cmd          *downloadstemcell.Config
	)

	BeforeEach(func() {
		pivnetClient = &pivnetfakes.FakeClient{}
		logger := lager.NewLogger("marman")

		cmd = &downloadstemcell.Config{
			Slug:         "stemcells-ubuntu-xenial",
			PivnetClient: pivnetClient,
			Logger:       logger,
		}
	})

	Context("Fixed version finds a single release", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      100,
					Version: "1.0.0",
				}, {
					ID:      101,
					Version: "1.0.1",
				}, {
					ID:      200,
					Version: "2.0",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("1.0")
			Expect(err).ToNot(HaveOccurred())

			release, err := cmd.FindStemcellRelease(constraint)
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from pivnet", func() {
				slug := pivnetClient.ListReleasesArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
			})

			Expect(release.ID).To(Equal(100))
		})
	})

	Context("Floating version finds the latest release", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      100,
					Version: "1.0.0",
				}, {
					ID:      101,
					Version: "1.0.1",
				}, {
					ID:      200,
					Version: "2.0",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("~1.0")
			Expect(err).ToNot(HaveOccurred())

			release, err := cmd.FindStemcellRelease(constraint)
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from pivnet", func() {
				slug := pivnetClient.ListReleasesArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
			})

			Expect(release.ID).To(Equal(101))
		})
	})

	Context("Pivnet fails to list releases", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{}, errors.New("list releases error"))
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = cmd.FindStemcellRelease(constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("list releases error"))
		})
	})

	Context("Pivnet returns no releases", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = cmd.FindStemcellRelease(constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found for the required stemcell version"))
		})
	})

	Context("Invalid release version on pivnet", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					Version: "not-a-good-version",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = cmd.FindStemcellRelease(constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found for the required stemcell version"))
		})
	})

	Context("No releases found for version", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					Version: "1.0",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("2.0")
			Expect(err).ToNot(HaveOccurred())

			_, err = cmd.FindStemcellRelease(constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found for the required stemcell version"))
		})
	})
})

var _ = Describe("FindStemcellFile", func() {
	var (
		pivnetClient *pivnetfakes.FakeClient
		cmd          *downloadstemcell.Config
	)

	BeforeEach(func() {
		pivnetClient = &pivnetfakes.FakeClient{}
		logger := lager.NewLogger("marman")

		cmd = &downloadstemcell.Config{
			Slug:         "stemcells-ubuntu-xenial",
			PivnetClient: pivnetClient,
			Logger:       logger,
		}
	})

	Context("Pivnet fails to list files", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns(nil, errors.New("list-files-error"))
		})

		It("returns an error", func() {
			_, err := cmd.FindStemcellFile(12345)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to list release files for stemcells-ubuntu-xenial (release ID: 12345)"))
			Expect(err.Error()).To(ContainSubstring("list-files-error"))
		})
	})

	Context("Pivnet returns no files", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns(nil, errors.New("list-files-error"))
		})

		It("returns an error", func() {
			_, err := cmd.FindStemcellFile(12345)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to list release files for stemcells-ubuntu-xenial (release ID: 12345)"))
			Expect(err.Error()).To(ContainSubstring("list-files-error"))
		})
	})

	Context("Pivnet no files matching iaas filter", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           1,
					AWSObjectKey: "stemcell-file-for-rash",
				},
				{
					ID:           2,
					AWSObjectKey: "stemcell-file-for-todd",
				},
			}, nil)
		})

		It("returns an error", func() {
			cmd.IAAS = "pete"
			_, err := cmd.FindStemcellFile(12345)

			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no matching stemcell files found for IaaS pete"))
		})
	})

	Context("Pivnet returns too many files", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           1,
					AWSObjectKey: "stemcell-file-for-rash",
				},
				{
					ID:           2,
					AWSObjectKey: "stemcell-file-for-todd",
				},
			}, nil)
		})

		It("returns an error", func() {
			cmd.IAAS = "file"
			_, err := cmd.FindStemcellFile(12345)

			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("too many matching stemcell files found for IaaS file"))
		})
	})

	Context("Single stemcell file found", func() {
		BeforeEach(func() {
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           1,
					AWSObjectKey: "stemcell-file-for-rash",
				},
				{
					ID:           2,
					AWSObjectKey: "stemcell-file-for-todd",
				},
				{
					ID:           3,
					AWSObjectKey: "stemcell-file-for-ernie",
				},
			}, nil)
		})

		It("returns an error", func() {
			cmd.IAAS = "todd"
			file, err := cmd.FindStemcellFile(12345)
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of product files from pivnet", func() {
				slug, releaseId := pivnetClient.ListFilesForReleaseArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
				Expect(releaseId).To(Equal(12345))
			})

			Expect(file).ToNot(BeNil())
			Expect(file.AWSObjectKey).To(Equal("stemcell-file-for-todd"))
			Expect(file.ID).To(Equal(2))
		})

	})

})

var _ = Describe("Download Stemcell", func() {
	var (
		pivnetClient *pivnetfakes.FakeClient
		cmd          *downloadstemcell.Config
		buffer       *Buffer
	)

	BeforeEach(func() {
		pivnetClient = &pivnetfakes.FakeClient{}
		logger := lager.NewLogger("marman")

		buffer = NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(buffer, lager.INFO))

		cmd = &downloadstemcell.Config{
			IAAS:         "azure",
			OS:           "ubuntu-xenial",
			Version:      "1.2.3",
			Floating:     false,
			PivnetClient: pivnetClient,
			Logger:       logger,
		}
	})

	AfterEach(func() {
		err := buffer.Close()
		Expect(err).ToNot(HaveOccurred())
	})

	Context("Missing stemcell OS argument", func() {
		BeforeEach(func() {
			cmd.OS = ""
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("missing stemcell os"))
		})
	})

	Context("Missing stemcell version argument", func() {
		BeforeEach(func() {
			cmd.Version = ""
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("missing stemcell version"))
		})
	})

	Context("Invalid stemcell version", func() {
		BeforeEach(func() {
			cmd.Version = "this-is-not-a-good-version"
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("invalid stemcell version"))
		})
	})

	Context("Failed to find stemcell release", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{}, errors.New("list-releases-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to find the stemcell release"))
		})
	})

	Context("Failed to find stemcell file", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      123,
					Version: "1.2.3",
				},
			}, nil)
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{}, errors.New("list-product-files-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to find the stemcell file"))
		})
	})

	Context("Failed to accept EULA", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      123,
					Version: "1.2.3",
				},
			}, nil)
			pivnetClient.AcceptEULAReturns(errors.New("accept-eula-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to accept the EULA from pivnet"))
		})
	})

	Context("Failed to create stemcell file", func() {
		BeforeEach(func() {
			cmd.IAAS = ""
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      123,
					Version: "1.2.3",
				},
			}, nil)
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           456,
					AWSObjectKey: "product-files/.",
					Links: &pivnet.Links{
						Download: map[string]string{
							"href": "http://my-download-link/.",
						},
					},
				},
			}, nil)
			pivnetClient.DownloadProductFileReturns(errors.New("download-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to create stemcell file: ."))
		})
	})

	Context("Failed to download stemcell", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      123,
					Version: "1.2.3",
				},
			}, nil)
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           456,
					AWSObjectKey: "product-files/ubuntu-xenial-azure.txt",
					Links: &pivnet.Links{
						Download: map[string]string{
							"href": "http://my-download-link/ubuntu-xenial-azure.txt",
						},
					},
				},
			}, nil)
			pivnetClient.DownloadProductFileReturns(errors.New("download-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadStemcell()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to download stemcell to file: ubuntu-xenial-azure.txt"))
		})
	})

	Context("Found the stemcell file", func() {
		BeforeEach(func() {
			pivnetClient.ListReleasesReturns([]pivnet.Release{
				{
					ID:      123,
					Version: "1.2.3",
				},
			}, nil)
			pivnetClient.ListFilesForReleaseReturns([]pivnet.ProductFile{
				{
					ID:           456,
					AWSObjectKey: "product-files/ubuntu-xenial-azure.txt",
					Links: &pivnet.Links{
						Download: map[string]string{
							"href": "http://my-download-link/ubuntu-xenial-azure.txt",
						},
					},
				},
				{
					AWSObjectKey: "ubuntu-xenial-gcp",
				},
			}, nil)
		})

		It("downloads the file", func() {
			err := cmd.DownloadStemcell()
			Expect(err).ToNot(HaveOccurred())

			By("getting the release from pivnet", func() {
				Expect(pivnetClient.ListReleasesCallCount()).To(Equal(1))
			})

			By("getting the file from pivnet", func() {
				Expect(pivnetClient.ListFilesForReleaseCallCount()).To(Equal(1))
			})

			By("accepting the eula on pivnet", func() {
				Expect(pivnetClient.AcceptEULACallCount()).To(Equal(1))
				slug, releaseId := pivnetClient.AcceptEULAArgsForCall(0)
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
				Expect(releaseId).To(Equal(123))
			})

			By("downloading the file", func() {
				Expect(pivnetClient.DownloadProductFileCallCount()).To(Equal(1))
				fileInfo, slug, releaseId, fileId, _ := pivnetClient.DownloadProductFileArgsForCall(0)
				Expect(fileInfo.Name).To(Equal("ubuntu-xenial-azure.txt"))
				Expect(fileInfo.Mode).To(Equal(os.FileMode(0644)))
				Expect(slug).To(Equal("stemcells-ubuntu-xenial"))
				Expect(releaseId).To(Equal(123))
				Expect(fileId).To(Equal(456))
			})
		})
	})
})
