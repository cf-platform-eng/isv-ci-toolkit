package downloadtile

import "testing"

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestDownloadtile(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Downloadtile Suite")
}
