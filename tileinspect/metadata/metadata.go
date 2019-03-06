package metadata

import (
	"archive/zip"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"regexp"

	"github.com/ghodss/yaml"
	. "github.com/pkg/errors"
)

type Config struct {
	Tile   string `long:"tile" short:"t" description:"path to product file" required:"true"`
	Out    string `long:"output" short:"o" description:"output file for metadata, defaults to stdout"`
	Format string `long:"format" short:"f" description:"output file type" choice:"yaml" choice:"json" default:"yaml"`
}

func findInZip(term string, zip *zip.ReadCloser) *zip.File {
	re := regexp.MustCompile(term)
	for _, f := range zip.File {
		if re.Match([]byte(f.Name)) {
			return f
		}
	}
	return nil
}

func (cmd *Config) dumpFile(zipFile *zip.File, out io.Writer) error {
	inFile, err := zipFile.Open()
	if err != nil {
		return err
	}
	defer inFile.Close()

	if cmd.Format == "json" {
		buf, err := ioutil.ReadAll(inFile)
		if err != nil {
			return err
		}

		j, err := yaml.YAMLToJSON(buf)
		if err != nil {
			return err
		}

		_, err = out.Write(j)
		return err
	} else {
		_, err = io.Copy(out, inFile)
		return err
	}
}

func (cmd *Config) WriteMetadata(out io.Writer) error {
	tile, err := zip.OpenReader(cmd.Tile)
	if err != nil {
		return Wrap(err, fmt.Sprintf("could not unzip %s", cmd.Tile))
	}
	defer tile.Close()

	metadataFile := findInZip(`metadata/.*\.yml`, tile)
	if metadataFile == nil {
		return errors.New("metadata file not found")
	}

	err = cmd.dumpFile(metadataFile, out)
	if err != nil {
		return Wrapf(err, "could not read from %s (found inside %s)", metadataFile.Name, cmd.Tile)
	}

	return nil
}

func (cmd *Config) Execute(args []string) error {
	var err error
	out := os.Stdout

	if cmd.Out != "" {
		out, err = os.OpenFile(cmd.Out, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return Wrapf(err, "could not open %s for write", cmd.Out)
		}
	}

	err = cmd.WriteMetadata(out)
	if err != nil {
		return Wrapf(err, "failed to write metadata file")
	}

	return nil
}
