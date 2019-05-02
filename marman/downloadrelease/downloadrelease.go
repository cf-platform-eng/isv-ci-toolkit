package downloadrelease

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	"github.com/cf-platform-eng/isv-ci-toolkit/marman"
	github2 "github.com/cf-platform-eng/isv-ci-toolkit/marman/github"
	"github.com/google/go-github/v25/github"
	"github.com/pkg/errors"
	"path"
	"regexp"
	"strings"
)

type Config struct {
	Owner   string `short:"o" long:"owner" description:"Repository owner" required:"true"`
	Repo    string `short:"r" long:"repo" description:"Repository name" required:"true"`
	Version string `short:"v" long:"version" description:"Release version"`
	Filter  string `short:"f" long:"filter" description:"Filter to specific asset"`

	GithubToken string `long:"github-token" description:"Authentication token for GitHub" env:"GITHUB_TOKEN"`

	Logger       lager.Logger
	GithubClient github2.Client
	Downloader   marman.Downloader
}

func assetsToString(assets []github.ReleaseAsset) string {
	builder := strings.Builder{}
	for _, asset := range assets {
		builder.WriteString(fmt.Sprintf("\n    %s", *asset.Name))
	}
	return builder.String()
}

func (cmd *Config) DownloadRelease() error {
	releases, err := cmd.GithubClient.ListReleases(cmd.Owner, cmd.Repo, nil)
	if err != nil {
		githubError, ok := err.(*github.ErrorResponse)
		if ok && cmd.GithubToken == "" && githubError.Message == "Not Found" {
			return fmt.Errorf("could not find %s/%s. If this repository is private, try again with a GitHub token", cmd.Owner, cmd.Repo)
		}
		return errors.Wrapf(err, "failed to get the list of releases for %s/%s", cmd.Owner, cmd.Repo)
	}

	if len(releases) == 0 {
		return fmt.Errorf("no releases found for %s/%s", cmd.Owner, cmd.Repo)
	}

	chosenRelease := releases[0]
	if cmd.Version != "" {
		chosenRelease = nil
		for _, release := range releases {
			if *release.Name == cmd.Version {
				chosenRelease = release
				break
			}
		}
	}

	if chosenRelease == nil {
		return fmt.Errorf("no releases found for %s/%s with version %s", cmd.Owner, cmd.Repo, cmd.Version)
	}

	if len(chosenRelease.Assets) == 0 {
		return fmt.Errorf("no release assets found for %s/%s", cmd.Owner, cmd.Repo)
	}

	chosenAsset := github.ReleaseAsset{}
	for _, asset := range chosenRelease.Assets {
		matched, err := regexp.MatchString(cmd.Filter, *asset.Name)
		if err != nil {
			return errors.Wrapf(err, "failed to apply filter: %s", cmd.Filter)
		}

		if matched {
			if chosenAsset.ID != nil {
				return fmt.Errorf("multiple assets found. Please use a filter:%s", assetsToString(chosenRelease.Assets))
			}
			chosenAsset = asset
		}
	}

	if chosenAsset.ID == nil {
		return fmt.Errorf("no release assets found for %s/%s with given filter: %s", cmd.Owner, cmd.Repo, cmd.Filter)
	}

	filename := path.Base(chosenAsset.GetBrowserDownloadURL())
	body, redirectURL, err := cmd.GithubClient.DownloadReleaseAsset(cmd.Owner, cmd.Repo, *chosenAsset.ID)
	if err != nil {
		return errors.Wrapf(err, "failed to download release asset %s from %s/%s", *chosenAsset.Name, cmd.Owner, cmd.Repo)
	}

	fmt.Printf("Downloading %s...\n", filename)

	if body == nil && redirectURL != "" {
		err = cmd.Downloader.DownloadFromURL(filename, redirectURL)
	} else {
		err = cmd.Downloader.DownloadFromReader(filename, body)
	}
	if err != nil {
		return errors.Wrapf(err, "failed to save release asset %s from %s/%s", *chosenAsset.Name, cmd.Owner, cmd.Repo)
	}
	return nil
}

func (cmd *Config) Execute(args []string) error {
	cmd.Downloader = &marman.MarmanDownloader{}
	cmd.GithubClient = github2.NewGitHubClient(cmd.GithubToken)
	return cmd.DownloadRelease()
}
