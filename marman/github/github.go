package github

import (
	"context"
	"github.com/google/go-github/v25/github"
	"golang.org/x/oauth2"
	"io"
	"net/http"
)

//go:generate counterfeiter Client
type Client interface {
	ListReleases(owner, repo string, opt *github.ListOptions) ([]*github.RepositoryRelease, error)
	DownloadReleaseAsset(owner, repo string, id int64) (io.ReadCloser, string, error)
}

type GitHubClient struct {
	Client *github.Client
	context context.Context
}

func NewGitHubClient(token string) *GitHubClient {
	ctx := context.Background()

	var httpClient *http.Client
	if token != "" {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: token},
		)
		httpClient = oauth2.NewClient(ctx, ts)
	}

	return &GitHubClient{
		Client: github.NewClient(httpClient),
		context: ctx,
	}
}

func (c *GitHubClient) ListReleases(owner, repo string, opt *github.ListOptions) ([]*github.RepositoryRelease, error) {
	releases, _, err := c.Client.Repositories.ListReleases(c.context, owner, repo, opt)
	return releases, err
}

func (c *GitHubClient) DownloadReleaseAsset(owner, repo string, id int64) (io.ReadCloser, string, error) {
	return c.Client.Repositories.DownloadReleaseAsset(c.context, owner, repo, id)
}
