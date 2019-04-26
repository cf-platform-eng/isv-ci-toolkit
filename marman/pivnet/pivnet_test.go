package pivnet_test

import (
	"errors"

	"code.cloudfoundry.org/lager"
	"github.com/Masterminds/semver"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet/pivnetfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	actualpivnet "github.com/pivotal-cf/go-pivnet"
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
