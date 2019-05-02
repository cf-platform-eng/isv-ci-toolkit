package marman

import (
	"github.com/pkg/errors"
	"io"
	"net/http"
	"os"
)

//go:generate counterfeiter ReadCloser
type ReadCloser interface {
	io.Reader
	io.Closer
}

//go:generate counterfeiter Downloader
type Downloader interface {
	DownloadFromReader(filename string, closer io.ReadCloser) error
	DownloadFromURL(filename string, url string) error
}

type MarmanDownloader struct {}

func (d *MarmanDownloader) DownloadFromReader(filename string, closer io.ReadCloser) error {
	defer closer.Close()

	// Create the file
	out, err := os.Create(filename)
	if err != nil {
		return errors.Wrapf(err, "failed to create file for release asset")
	}
	defer out.Close()

	// Write the body to file
	_, err = io.Copy(out, closer)
	if err != nil {
		return errors.Wrapf(err, "failed to save release asset data")
	}

	return nil
}

func (d *MarmanDownloader) DownloadFromURL(filename string, url string) error {
	response, err := http.Get(url)
	if err != nil {
		return errors.Wrapf(err, "failed to download release asset from url")
	}

	return d.DownloadFromReader(filename, response.Body)
}
