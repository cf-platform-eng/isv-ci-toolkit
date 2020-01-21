package features_test

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	. "github.com/MakeNowJust/heredoc/v2/dot"
	. "github.com/bunniesandbeatings/goerkin"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Scenario first", func() {
	var (
		session          *Session
		commandInputPipe io.WriteCloser
		volumePath       string
		rootPath         string
		tempPath         string
	)

	steps := NewSteps()

	BeforeSuite(func() {

		path, err := os.Getwd()
		Expect(err).NotTo(HaveOccurred())

		rootPath = filepath.Join(path, "..")

		tempPath = filepath.Join(rootPath, "temp")
		err = os.MkdirAll(tempPath, 0766)
		Expect(err).NotTo(HaveOccurred())

		command := exec.Command("make", "clean", "build")
		command.Dir = rootPath

		session, err := Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, time.Minute*3).Should(Exit(0))
		Eventually(session).Should(Say("Successfully tagged cfplatformeng/base-image:local"))

	})

	BeforeEach(func() {
		SetDefaultEventuallyTimeout(time.Second * 3)

		var err error
		volumePath, err = ioutil.TempDir(tempPath, "base-image-test-volume-")
		Expect(err).NotTo(HaveOccurred())

	})

	AfterEach(func() {
		err := os.RemoveAll(volumePath)
		Expect(err).NotTo(HaveOccurred())
	})

	Scenario("executing the image with `help` shows the help", func() {
		steps.When("the image is run with `help`")
		steps.Then("I see the help text")
		steps.And("the image exits with zero")
	})

	Scenario("executing the image with `shell` launches the shell", func() {
		steps.When("the image is run with `shell`")
		steps.And("I run `uname` in the shell")
		steps.Then("I see that it is running Linux")
	})

	Context("Commands exit with zero", func() {
		Scenario("executing the image with `run` executes run.sh", func() {
			steps.Given("and a run.sh to volume mount")
			steps.When("the image is run with `run` and the volume mount")
			steps.Then("I see that run.sh is executed")
			steps.And("the image exits with zero")
		})

		Scenario("executing the image with `needs` shows the needs", func() {
			steps.Given("a needs.json file to volume mount")
			steps.When("the image is run with `needs` and the volume mount")
			steps.Then("I see the needs.json content")
			steps.And("the image exits with zero")
		})
	})

	Context("Commands exit with non-zero", func() {
		Scenario("executing the image with `run` executes run.sh", func() {
			steps.Given("and a failing run.sh to volume mount")
			steps.When("the image is run with `run` and the volume mount")
			steps.And("the image exits with non-zero")
		})

		Scenario("executing the image with `needs` shows the needs", func() {
			steps.When("the image is run with `needs` and the volume mount")
			steps.Then("I see needs.json is missing")
			steps.And("the image exits with non-zero")
		})
	})


	steps.Define(func(define Definitions) {
		define.Given(`^and a run.sh to volume mount$`, func() {
			filename := filepath.Join(volumePath, "run.sh")

			file, err := os.OpenFile(filename, os.O_RDWR|os.O_CREATE, 0755)
			Expect(err).NotTo(HaveOccurred())

			_, err = file.WriteString(`echo "hello from run.sh"`)
			Expect(err).NotTo(HaveOccurred())

			err = file.Close()
			Expect(err).NotTo(HaveOccurred())
		})

		define.Given("^and a failing run.sh to volume mount$", func() {
			filename := filepath.Join(volumePath, "run.sh")

			file, err := os.OpenFile(filename, os.O_RDWR|os.O_CREATE, 0755)
			Expect(err).NotTo(HaveOccurred())

			_, err = file.WriteString(`exit 1`)
			Expect(err).NotTo(HaveOccurred())

			err = file.Close()
			Expect(err).NotTo(HaveOccurred())
		})

		define.Given(`^a needs.json file to volume mount$`, func() {
			filename := filepath.Join(volumePath, "needs.json")

			file, err := os.OpenFile(filename, os.O_RDWR|os.O_CREATE, 0655)
			Expect(err).NotTo(HaveOccurred())

			_, err = file.WriteString(D(`
				[{
				    "type": "environment_variable",
    				"name": "PRODUCT_NAME"
				}]
			`))

			Expect(err).NotTo(HaveOccurred())

			err = file.Close()
			Expect(err).NotTo(HaveOccurred())

		})

		define.When("^the image is run with `help`$", func() {
			command := exec.Command(
				"docker",
				"run",
				"-t",
				"cfplatformeng/base-image:local",
				"help",
			)

			var err error
			session, err = Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
			Eventually(session).Should(Exit(0))
		})

		define.When("^the image is run with `shell`$", func() {
			var err error

			command := exec.Command(
				"docker",
				"run",
				"-i",
				"cfplatformeng/base-image:local",
				"shell",
			)

			commandInputPipe, err = command.StdinPipe()
			Expect(err).NotTo(HaveOccurred())

			session, err = Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
		})

		define.When("^the image is run with `run` and the volume mount$", func() {
			volumeMount := fmt.Sprintf("%s:/job", volumePath)
			command := exec.Command(
				"docker",
				"run",
				"-t",
				"-v",
				volumeMount,
				"cfplatformeng/base-image:local",
				"run",
			)

			command.Dir = tempPath

			var err error
			session, err = Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
		})

		define.When("^the image is run with `needs` and the volume mount$", func() {
			volumeMount := fmt.Sprintf("%s:/job", volumePath)
			command := exec.Command(
				"docker",
				"run",
				"-t",
				"-v",
				volumeMount,
				"cfplatformeng/base-image:local",
				"needs",
			)

			command.Dir = tempPath

			var err error
			session, err = Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
		})

		define.Then(`^I see the help text$`, func() {
			Eventually(session).Should(Say("CN-JEB entrypoint standard"))
			Eventually(session).Should(Say("Commands are:"))
			Eventually(session).Should(Say("help"))
			Eventually(session).Should(Say("run"))
			Eventually(session).Should(Say("shell"))
			Eventually(session).Should(Say("needs"))
			Eventually(session).Should(Say("list-needs"))
		})

		define.Then(`^I see the shell prompt$`, func() {
			Eventually(session).Should(Say("/job#"))
		})

		define.When("^I run `uname` in the shell$", func() {
			_, err := io.WriteString(commandInputPipe, "uname\n")
			Expect(err).NotTo(HaveOccurred())
		})

		define.Then(`^I see that it is running Linux$`, func() {
			Eventually(session).Should(Say("Linux"))
		})

		define.Then(`^I see that run.sh is executed$`, func() {
			Eventually(session).Should(Say("hello from run.sh"))
		})

		define.Then("^I see the needs.json content$", func() {
			Eventually(session).Should(Say("PRODUCT_NAME"))
		})

		define.Then("^I see needs.json is missing$", func() {
			Eventually(session).Should(Say("Needs file not found"))
		})

		define.Then(`^the image exits with zero$`, func() {
			Eventually(session).Should(Exit(0))
		})
		define.Then(`^the image exits with non-zero$`, func() {
			Eventually(session).Should(Exit())
			Expect(session).NotTo(Exit(0))
		})
	})
})
