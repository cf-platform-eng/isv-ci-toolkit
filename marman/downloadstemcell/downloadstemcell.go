package downloadstemcell

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	. "github.com/pkg/errors"

	"github.com/Masterminds/semver"
	pivnetClient "github.com/cf-platform-eng/isv-ci-toolkit/marman/pivnet"
	"github.com/pivotal-cf/go-pivnet"
	"github.com/pivotal-cf/go-pivnet/download"

	"code.cloudfoundry.org/lager"

	"github.com/pivotal-cf/go-pivnet/logshim"
)

type Config struct {
	OS      string `short:"o" long:"os" description:"Stemcell OS name"`
	Slug    string
	Version string `short:"v" long:"version" description:"Stemcell version"`
	IAAS    string `short:"i" long:"iaas" description:"Specific stemcell IaaS to download"`

	Logger       lager.Logger
	PivnetClient pivnetClient.Client
	PivnetToken  string `long:"pivnet-token" description:"Authentication token for PivNet" env:"PIVNET_TOKEN"`
}

func stemcellOSToSlug(os string) (string, error) {
	switch os {
	case "ubuntu-trusty":
		return "stemcells-ubuntu", nil
	case "ubuntu-xenial":
		return "stemcells-ubuntu-xenial", nil
	}
	return "", errors.New("invalid stemcell os")
}

func (cmd *Config) FindStemcellFile(releaseId int) (*pivnet.ProductFile, error) {
	var stemcellFile pivnet.ProductFile

	files, err := cmd.PivnetClient.ListFilesForRelease(cmd.Slug, releaseId)
	if err != nil {
		return nil, Wrapf(err, "failed to list release files for %s (release ID: %d)", cmd.Slug, releaseId)
	}

	cmd.Logger.Debug(fmt.Sprintf("Found %d files\n", len(files)))

	if len(files) == 0 {
		return nil, errors.New("no stemcells found")
	}

	for _, file := range files {
		filename := path.Base(file.AWSObjectKey)
		if strings.Contains(filename, cmd.IAAS) {
			if stemcellFile.ID == 0 {
				stemcellFile = file
			} else {
				err = fmt.Errorf("too many matching stemcell files found for IaaS %s", cmd.IAAS)
			}
		}
	}

	if stemcellFile.ID == 0 {
		err = fmt.Errorf("no matching stemcell files found for IaaS %s", cmd.IAAS)
	}

	return &stemcellFile, err
}

func (cmd *Config) DownloadStemcell() error {
	if cmd.OS == "" {
		return errors.New("missing stemcell os")
	}

	slug, err := stemcellOSToSlug(cmd.OS)
	if err != nil {
		return fmt.Errorf("cannot find slug for os %s", cmd.OS)
	}
	cmd.Slug = slug

	if cmd.Version == "" {
		return errors.New("missing stemcell version")
	}

	versionConstraint, err := semver.NewConstraint(cmd.Version)
	if err != nil {
		return Wrapf(err, "stemcell version is not valid semver")
	}

	release, err := cmd.PivnetClient.FindReleaseByVersionConstraint(cmd.Slug, versionConstraint)
	if err != nil {
		return Wrapf(err, "failed to find the stemcell release: %s", cmd.Version)
	}

	err = cmd.PivnetClient.AcceptEULA(cmd.Slug, release.ID)
	if err != nil {
		return Wrapf(err, "failed to accept the EULA from pivnet")
	}

	file, err := cmd.FindStemcellFile(release.ID)
	if err != nil {
		return Wrapf(err, "failed to find the stemcell file for release: %d", release.ID)
	}

	filename := path.Base(file.AWSObjectKey)
	stemcellFile, err := os.Create(filename)
	if err != nil {
		return Wrapf(err, "failed to create stemcell file: %s", filename)
	}

	fileInfo, err := download.NewFileInfo(stemcellFile)
	if err != nil {
		return Wrapf(err, "failed to load file info: %s", filename)
	}

	err = cmd.PivnetClient.DownloadProductFile(fileInfo, cmd.Slug, release.ID, file.ID, os.Stdout)
	if err != nil {
		return Wrapf(err, "failed to download stemcell to file: %s", filename)
	}

	return nil
}

func (cmd *Config) Execute(args []string) error {
	stdoutLogger := log.New(os.Stdout, "", log.LstdFlags)
	stderrLogger := log.New(os.Stderr, "", log.LstdFlags)

	logger := logshim.NewLogShim(stdoutLogger, stderrLogger, true)
	cmd.PivnetClient = &pivnetClient.PivNetClient{
		Wrapper: &pivnetClient.ClientWrapper{
			PivnetClient: pivnet.NewClient(pivnet.ClientConfig{
				Host:  pivnet.DefaultHost,
				Token: cmd.PivnetToken,
			}, logger),
		},
	}

	cmd.Logger = lager.NewLogger("marman")
	return cmd.DownloadStemcell()
}
