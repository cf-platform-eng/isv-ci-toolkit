# TILE CI Design Guide

## Principals

Written from the perspective of the [ISV Integration developer][ISV integration developer].

### Tests can be run on workstations

There are three kinds of tests you may want to use:

1. [Pre-Canned test-case][Pre-Canned test-case]
2. [Example test-case][Example test-case]
3. [Bespoke test-case][Bespoke test-case]

These tests can be executed, and modified locally, on the [integration developer's][ISV integration developer] workstation.
This provides:

1. fast feedback loops
2. simpler integration with preferred tools (such as IDEs)
3. simpler insight into the content of the test

### Platforms can be created and destroyed from the workstation

Most tests have setup and teardown steps. The most common setup/teardown for a Pivotal ISV Product test is the [Platform Builder](./glossary.md#platform-builders).

When you work locally, we'll often provide you with on-demand environments you can test against. However these won't always be suitable for your test (eg, special configuration for software defined networking before standing up the Pivotal Platform).

(TODO wording) We implement the Platform Builder tasks as docker images, that you can run locally, and modify to help us produce better builders that support everyone.

### I can run tests and platform builders in my own Automation

Our design ensures you can run the platform builders and tests in your own CI. This has the following advantages:

1. Early feedback, you don't have to cut a new point release and publish it with us before finding out an integration has failed
1. Changes to your product, deployment and integration are tested as they're commited to your source control. No matter
where the changes originate from within your org, you have confidence that your next release is ready.
1. If you're already a shop that follows Contiuous integration and deployment practices, our framework should slide into
your processes easily.

### Tests and Prerequisites are open-source

TODO: Encouraging mimicking operator experiences

## Design

Each test image in the ISV-CI toolkit have these things in common:

* A `needs.json` that describes the inputs requirements using [Needs](https://github.com/cf-platform-eng/needs).

    This is used for blocking the test execution early if a required input is missing.

* A `steps.sh` script that exports a function for each step in the test.

    A shell file that exports the functions make it simple to debug the test and run each step sequentially.

* A `run.sh` script that will run the test. This is the default `CMD` for the Dockerfile.
* A Dockerfile that combines the above:
  * `COPY [ "needs.json", "run.sh", <any other files>..., "/test/" ]`
  * `WORKDIR /test`
  * `CMD ["/bin/bash", "-c", "/test/run.sh"]`

### Patterns

### Roadmap

What pieces are we developing

[ISV integration developer]: ./glossary.md#isv-integration-developer
[Pre-Canned test-case]: ./glossary.md#pre-canned-test-case
[Example Test-case]: ./glossary.md#example-test-case
[Bespoke Test-case]: ./glossary.md#bespoke-test-case
