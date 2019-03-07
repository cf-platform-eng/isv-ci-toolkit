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

	Context("Floating stemcell version", func() {
		BeforeEach(func() {
			cmd.Version = "170"
			cmd.Floating = true
		})

		It("downloads the stemcell", func() {
			err := cmd.DownloadStemcell()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases from PivNet", func() {
				Fail("Not implemented yet")
			})
		})

		Context("PivNet fails to list releases", func() {
			BeforeEach(func() {
				pivnetClient.ListReleasesReturns([]pivnet.Release{}, errors.New("list releases error"))
			})

			It("returns an error", func() {
				Fail("Not implemented yet")
			})
		})

		Context("PivNet returns no releases", func() {
			It("returns an error", func() {
				Fail("Not implemented yet")
			})
		})

		Context("PivNet fails to list product files", func() {
			It("returns an error", func() {
				Fail("Not implemented yet")
			})
		})
	})

	Context("Fixed stemcell version", func() {
		BeforeEach(func() {
			cmd.Version = "170.1234"
			cmd.Floating = false
		})

		It("downloads the stemcell", func() {
			Fail("Not implemented yet")
		})
	})
})
