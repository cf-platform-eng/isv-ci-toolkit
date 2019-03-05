package metadata_test

import (
	"errors"
	"github.com/cf-platform-eng/isv-ci-toolkit/tileinspect/metadata"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"io"
	"io/ioutil"
	"os"
)

type BadWriter struct{}

func (w *BadWriter) Write(p []byte) (int, error) {
	return 0, errors.New("I am a bad writer")
}

var _ = Describe("WriteMetadata", func() {
	Context("Valid tile", func() {
		var config metadata.Config
		BeforeEach(func() {
			config = metadata.Config{
				Tile: "artifacts/test-pas-tile-0.2.4.pivotal",
			}
		})

		It("extracts the metadata file from the tile", func() {
			r, w := io.Pipe()
			go func() {
				err := config.WriteMetadata(w)
				Expect(err).ToNot(HaveOccurred())
				_ = w.Close()
			}()

			stdout, _ := ioutil.ReadAll(r)
			Expect(stdout).To(ContainSubstring("description: Smoke test tile for tile-dashboard to prove acceptance is in good shape"))
		})

		Context("JSON format", func() {
			BeforeEach(func() {
				config.Format = "json"
			})
			It("extracts the metadata file from the tile and outputs it in JSON", func() {
				r, w := io.Pipe()
				go func() {
					err := config.WriteMetadata(w)
					Expect(err).ToNot(HaveOccurred())
					_ = w.Close()
				}()

				stdout, _ := ioutil.ReadAll(r)
				Expect(stdout).To(ContainSubstring("\"description\":\"Smoke test tile for tile-dashboard to prove acceptance is in good shape\""))
			})
		})

		Context("Bad output", func() {
			It("returns an error", func() {
				out := &BadWriter{}
				err := config.WriteMetadata(out)
				Expect(err).To(HaveOccurred())
				Expect(err.Error()).To(Equal("could not read from metadata/test-pas-tile.yml (found inside artifacts/test-pas-tile-0.2.4.pivotal): I am a bad writer"))
			})
		})
	})

	Context("Missing tile", func() {
		It("returns an error", func() {
			config := metadata.Config{}
			err := config.WriteMetadata(nil)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("could not unzip : open : no such file or directory"))
		})
	})

	Context("Invalid tile path", func() {
		It("returns an error", func() {
			config := metadata.Config{
				Tile: "this/path/does/not/exist",
			}
			err := config.WriteMetadata(nil)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("could not unzip this/path/does/not/exist: open this/path/does/not/exist: no such file or directory"))
		})
	})

	Context("Invalid tile file", func() {
		It("returns an error", func() {
			config := metadata.Config{
				Tile: "artifacts/not-a-zip-file",
			}
			err := config.WriteMetadata(nil)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("could not unzip artifacts/not-a-zip-file: zip: not a valid zip file"))
		})
	})

	Context("No metadata file inside tile", func() {
		It("returns an error", func() {
			config := metadata.Config{
				Tile: "artifacts/missing-metadata.pivotal",
			}
			err := config.WriteMetadata(nil)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("metadata file not found"))
		})
	})

	Context("Invalid metadata file inside tile", func() {
		var config metadata.Config
		BeforeEach(func() {
			config = metadata.Config{
				Tile: "artifacts/invalid-metadata-yaml.pivotal",
			}
		})
		Context("Default format (yaml)", func() {
			It("returns the invalid yaml", func() {
				r, w := io.Pipe()
				go func() {
					err := config.WriteMetadata(w)
					Expect(err).ToNot(HaveOccurred())
					_ = w.Close()
				}()

				stdout, _ := ioutil.ReadAll(r)
				Expect(string(stdout)).To(Equal(": - this is not valid yaml\n"))
			})
		})

		Context("JSON format", func() {
			It("returns an error", func() {
				config.Format = "json"
				err := config.WriteMetadata(nil)
				Expect(err).To(HaveOccurred())
				Expect(err.Error()).To(Equal("could not read from metadata/invalid.yml (found inside artifacts/invalid-metadata-yaml.pivotal): yaml: did not find expected key"))
			})
		})
	})
})

var _ = Describe("Execute", func() {
	Context("Valid tile", func() {
		var config metadata.Config
		var tmpFile *os.File

		BeforeEach(func() {
			config = metadata.Config{
				Tile: "artifacts/test-pas-tile-0.2.4.pivotal",
			}

			var err error
			tmpFile, err = ioutil.TempFile(".", "metadata-*.yml")
			Expect(err).ToNot(HaveOccurred())
		})
		AfterEach(func() {
			err := os.Remove(tmpFile.Name())
			Expect(err).ToNot(HaveOccurred())
		})
		Context("No output file defined", func() {
			var savedStdout *os.File
			BeforeEach(func() {
				savedStdout = os.Stdout
				os.Stdout = tmpFile
			})
			AfterEach(func() {
				os.Stdout = savedStdout
			})
			It("prints the metadata to stdout", func() {
				err := config.Execute(nil)
				Expect(err).ToNot(HaveOccurred())

				metadataFile, err := ioutil.ReadFile(tmpFile.Name())
				Expect(err).ToNot(HaveOccurred())
				Expect(metadataFile).To(ContainSubstring("description: Smoke test tile for tile-dashboard to prove acceptance is in good shape"))
			})
		})

		Context("Output file defined", func() {
			It("writes the metadata to the file", func() {
				config.Out = tmpFile.Name()
				err := config.Execute(nil)
				Expect(err).ToNot(HaveOccurred())

				metadataFile, err := ioutil.ReadFile(tmpFile.Name())
				Expect(err).ToNot(HaveOccurred())
				Expect(metadataFile).To(ContainSubstring("description: Smoke test tile for tile-dashboard to prove acceptance is in good shape"))
			})
		})

		Context("Invalid output file", func() {
			It("returns an error", func() {
				config.Out = "."
				err := config.Execute(nil)
				Expect(err).To(HaveOccurred())
				Expect(err.Error()).To(Equal("could not open . for write: open .: is a directory"))
			})
		})
	})

	Context("WriteMetadata returns an error", func() {
		It("returns an error", func() {
			config := metadata.Config{}
			err := config.Execute(nil)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(Equal("failed to write metadata file: could not unzip : open : no such file or directory"))
		})
	})
})
