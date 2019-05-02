package downloadrelease_test

import (
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/downloadrelease"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/github/githubfakes"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman/marmanfakes"
	"github.com/google/go-github/v25/github"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/pkg/errors"
	"path"
)

func makeRelease(id int64, name string, assets ...github.ReleaseAsset) *github.RepositoryRelease {
	release := github.RepositoryRelease{
		ID:   new(int64),
		Name: new(string),
	}
	*release.ID = id
	*release.Name = name
	release.Assets = assets
	return &release
}

func makeAsset(id int64, name string) github.ReleaseAsset {
	asset := github.ReleaseAsset{
		ID:                 new(int64),
		Name:               new(string),
		BrowserDownloadURL: new(string),
	}
	*asset.ID = id
	*asset.Name = name
	*asset.BrowserDownloadURL = path.Join("download", "path", "to", name)
	return asset
}

var _ = Describe("DownloadRelease", func() {
	var (
		cmd          *downloadrelease.Config
		githubClient *githubfakes.FakeClient
		downloader   *marmanfakes.FakeDownloader
	)

	BeforeEach(func() {
		githubClient = &githubfakes.FakeClient{}
		downloader = &marmanfakes.FakeDownloader{}
		cmd = &downloadrelease.Config{
			Owner:        "petewall",
			Repo:         "myrepo",
			Filter:       "linux",
			GithubClient: githubClient,
			Downloader:   downloader,
		}
	})

	Context("everything works", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(1123, "asset.windows"),
					makeAsset(1456, "asset.linux"),
					makeAsset(1789, "asset.macosx"),
				),
				makeRelease(2, "0.9",
					makeAsset(2123, "asset.windows"),
					makeAsset(2456, "asset.linux"),
					makeAsset(2789, "asset.macosx"),
				),
				makeRelease(3, "0.8",
					makeAsset(3123, "asset.windows"),
					makeAsset(3456, "asset.linux"),
					makeAsset(3789, "asset.macosx"),
				),
			}, nil)
			githubClient.DownloadReleaseAssetReturns(nil, "download-url", nil)
			cmd.Version = "0.9"
		})

		It("downloads the file", func() {
			err := cmd.DownloadRelease()
			Expect(err).ToNot(HaveOccurred())

			By("getting the list of releases", func() {
				Expect(githubClient.ListReleasesCallCount()).To(Equal(1))
				owner, repo, opt := githubClient.ListReleasesArgsForCall(0)
				Expect(owner).To(Equal("petewall"))
				Expect(repo).To(Equal("myrepo"))
				Expect(opt).To(BeNil())
			})

			By("getting the download url for the release asset", func() {
				Expect(githubClient.DownloadReleaseAssetCallCount()).To(Equal(1))
				owner, repo, assetId := githubClient.DownloadReleaseAssetArgsForCall(0)
				Expect(owner).To(Equal("petewall"))
				Expect(repo).To(Equal("myrepo"))
				Expect(assetId).To(Equal(int64(2456)))
			})

			By("downloading the asset", func() {
				Expect(downloader.DownloadFromURLCallCount()).To(Equal(1))
				filename, url := downloader.DownloadFromURLArgsForCall(0)
				Expect(filename).To(Equal("asset.linux"))
				Expect(url).To(Equal("download-url"))
			})
		})
	})

	Context("could not find the list of releases", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{}, &github.ErrorResponse{
				Message: "Not Found",
			})
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("could not find petewall/myrepo. If this repository is private, try again with a GitHub token"))
		})
	})

	Context("failed to get the list of releases", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{}, errors.New("list releases error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("failed to get the list of releases for petewall/myrepo: list releases error"))
		})
	})

	Context("no releases found", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{}, nil)
		})
		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("no releases found for petewall/myrepo"))
		})
	})

	Context("no releases found for version", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0"),
				makeRelease(1, "2.0"),
			}, nil)
			cmd.Version = "3.0"
		})
		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("no releases found for petewall/myrepo with version 3.0"))
		})
	})

	Context("too many release assets found", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "linux-asset1"),
					makeAsset(456, "linux-asset2"),
				),
			}, nil)
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("multiple assets found. Please use a filter:\n    linux-asset1\n    linux-asset2"))
		})
	})

	Context("bad filter asset filter", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "linux-asset1"),
				),
			}, nil)
			cmd.Filter = `\p`
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to apply filter: \\p"))
		})
	})

	Context("no release assets found", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0"),
			}, nil)
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("no release assets found for petewall/myrepo"))
		})
	})

	Context("no release assets found after filter", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "windows-asset1"),
					makeAsset(456, "windows-asset2"),
				),
			}, nil)
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("no release assets found for petewall/myrepo with given filter: linux"))
		})
	})

	Context("failed to get download from github", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "windows-asset1"),
					makeAsset(456, "linux-asset2"),
				),
			}, nil)
			githubClient.DownloadReleaseAssetReturns(nil, "", errors.New("download release asset error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to download release asset linux-asset2 from petewall/myrepo"))
		})
	})

	Context("failed to download from url", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "windows-asset1"),
					makeAsset(456, "linux-asset2"),
				),
			}, nil)
			githubClient.DownloadReleaseAssetReturns(nil, "download-url", nil)
			downloader.DownloadFromURLReturns(errors.New("download-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to save release asset linux-asset2 from petewall/myrepo"))
			Expect(downloader.DownloadFromURLCallCount()).To(Equal(1))
		})
	})

	Context("failed to download from redirect url", func() {
		BeforeEach(func() {
			githubClient.ListReleasesReturns([]*github.RepositoryRelease{
				makeRelease(1, "1.0",
					makeAsset(123, "windows-asset1"),
					makeAsset(456, "linux-asset2"),
				),
			}, nil)

			fakeReadCloser := &marmanfakes.FakeReadCloser{}
			githubClient.DownloadReleaseAssetReturns(fakeReadCloser, "", nil)
			downloader.DownloadFromReaderReturns(errors.New("download-error"))
		})

		It("returns an error", func() {
			err := cmd.DownloadRelease()
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("failed to save release asset linux-asset2 from petewall/myrepo"))
			Expect(downloader.DownloadFromReaderCallCount()).To(Equal(1))
		})
	})
})
