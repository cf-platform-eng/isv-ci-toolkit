package pivnet_test

import (
	"errors"
	"os"

	"code.cloudfoundry.org/lager"
	"github.com/Masterminds/semver"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet/pivnetfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	actualpivnet "github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/download"
)

var _ = Describe("FindReleaseByVersionConstraint", func() {
	var (
		pivnetWrapper *pivnetfakes.FakeWrapper
		client        *pivnet.PivNetClient
		logOutput     *Buffer
	)

	BeforeEach(func() {
		pivnetWrapper = &pivnetfakes.FakeWrapper{}

		logger := lager.NewLogger("pivnet-test")
		logOutput = NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(logOutput, lager.DEBUG))

		client = &pivnet.PivNetClient{
			Wrapper: pivnetWrapper,
			Logger:  logger,
		}
	})

	Context("Fixed version finds a single release", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{
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

			release, err := client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from pivnet", func() {
				slug := pivnetWrapper.ListReleasesArgsForCall(0)
				Expect(slug).To(Equal("my-slug"))
			})

			Expect(release.ID).To(Equal(100))
		})
	})

	Context("Floating version finds the latest release", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{
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

			release, err := client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from pivnet", func() {
				slug := pivnetWrapper.ListReleasesArgsForCall(0)
				Expect(slug).To(Equal("my-slug"))
			})

			Expect(release.ID).To(Equal(101))
		})
	})

	Context("Pivnet fails to list releases", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{}, errors.New("list releases error"))
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("list releases error"))
		})
	})

	Context("Pivnet returns no releases", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found"))
		})
	})

	Context("Invalid release version on pivnet", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{
				{
					Version: "not-a-good-version",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("*")
			Expect(err).ToNot(HaveOccurred())

			_, err = client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found"))

			Expect(logOutput).To(Say("invalid release version found"))
		})
	})

	Context("No releases found for version", func() {
		BeforeEach(func() {
			pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{
				{
					Version: "1.0",
				},
			}, nil)
		})

		It("returns an error", func() {
			constraint, err := semver.NewConstraint("2.0")
			Expect(err).ToNot(HaveOccurred())

			_, err = client.FindReleaseByVersionConstraint("my-slug", constraint)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("no releases found"))
		})
	})
})

var _ = Describe("DownloadFile", func() {
	var (
		pivnetWrapper *pivnetfakes.FakeWrapper
		client        *pivnet.PivNetClient
		logOutput     *Buffer
	)

	BeforeEach(func() {
		pivnetWrapper = &pivnetfakes.FakeWrapper{}

		logger := lager.NewLogger("pivnet-test")
		logOutput = NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(logOutput, lager.DEBUG))

		client = &pivnet.PivNetClient{
			Wrapper: pivnetWrapper,
			Logger:  logger,
		}

		pivnetWrapper.ListReleasesReturns([]actualpivnet.Release{
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

	Context("can't create file", func() {
		It("throws an error", func() {
			fakefile := actualpivnet.ProductFile{
				ID:           1,
				AWSObjectKey: "tile-for-rash/.",
			}
			err := client.DownloadFile("pivnet-test", 100, &fakefile)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to create file: ."))
		})
	})

	Context("can't get info for file", func() {
		BeforeEach(func() {
			pivnetWrapper.NewFileInfoReturns(nil, errors.New("new-file-info-error"))
		})

		It("throws an error", func() {
			fakefile := actualpivnet.ProductFile{
				ID:           1,
				AWSObjectKey: "tile-for-todd/example.pivotal",
			}
			err := client.DownloadFile("pivnet-test", 100, &fakefile)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to load file info: example.pivotal"))
		})
	})

	Context("can't download file", func() {
		BeforeEach(func() {
			pivnetWrapper.DownloadProductFileReturns(errors.New("unable to download"))
		})

		It("throws an error", func() {
			fakefile := actualpivnet.ProductFile{
				ID:           1,
				AWSObjectKey: "tile-for-todd/example.pivotal",
			}
			err := client.DownloadFile("pivnet-test", 100, &fakefile)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to download file: example.pivotal"))
		})
	})

	Context("no errors", func() {
		var (
			fakeFileInfo *download.FileInfo
			fakeFile     actualpivnet.ProductFile
		)

		BeforeEach(func() {
			fakeFile = actualpivnet.ProductFile{
				ID:           1,
				AWSObjectKey: "tile-for-todd/example.pivotal",
			}
			fakeFileInfo = &download.FileInfo{}

			pivnetWrapper.NewFileInfoReturns(fakeFileInfo, nil)
		})

		AfterEach(func() {
			err := os.Remove("example.pivotal")
			Expect(err).NotTo(HaveOccurred())
		})

		It("downloads the file", func() {
			err := client.DownloadFile("pivnet-test", 100, &fakeFile)
			Expect(err).NotTo(HaveOccurred())

			Expect(pivnetWrapper.NewFileInfoCallCount()).To(Equal(1))
			file := pivnetWrapper.NewFileInfoArgsForCall(0)
			Expect(file.Name()).To(Equal("example.pivotal"))

			Expect(pivnetWrapper.DownloadProductFileCallCount()).To(Equal(1))

			fileInfo, slug, releaseID, fileID, _ := pivnetWrapper.DownloadProductFileArgsForCall(0)
			Expect(fileInfo).To(Equal(fakeFileInfo))
			Expect(slug).To(Equal("pivnet-test"))
			Expect(releaseID).To(Equal(100))
			Expect(fileID).To(Equal(fakeFile.ID))
		})
	})
})
