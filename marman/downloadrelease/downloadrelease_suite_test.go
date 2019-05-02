package downloadrelease_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestDownloadrelease(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "DownloadRelease Suite")
}
