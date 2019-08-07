
## ISV integration developer
This is the person who takes an ISV product and ensures it can be deployed onto a 
customer's Pivotal Cloud Foundry Platform.

---
## Test-Case
A test case is a scenario that an ISV Integration developer wants to assert regarding their product.
Unlike traditional test-cases (eg JUnit), ISV-CI test-case's tend to encompass one or more feature flows.

**Example test case for 'greeter-service' product functional test**

The greeter-service product responds to a HTTP GET with "hello <configured-name>"

1. Configure my product. 
    
    Eg:
    `<configured-name> = superman`
    
1. Install my product

1. Assert that the product is functioning correctly on it's own.

    Eg:
    `call the product vm with HTTP get and receive "hello superman"`
    
1. Assert that a PCF user can consume the product as a service
    
    Eg:
    ```
    $ cf create-service greeter -c { "name": "Jolene" }
    $ cf push some-app
    $ cf bind some-app create-service
    
    visit the app and see "Hello Jolene"
    ```
    
1. Uninstall my product

**Example test case for 'greeter-service' product upgrade**

1. Configure my product. 
1. Install my product
1. Assert that the product is functioning correctly on it's own.
1. Upgrade PCF
1. Assert that the product is functioning correctly on it's own.
1. Uninstall my product


### Pre-Canned test-case
A [Test-Case](#test-case) that Pivotal provides. These test-cases tend to be a generic solution for
a particular functional test, such as:

1. Security Scan
2. Tile Metadata validation
3. Install-Uninstall Tile
4. Install-Uninstall PKS service
etc...

Pre-Canned Test cases can be the basis for a [Bespoke test-case](#bespoke-test-case)

### Bespoke test-case
A [Test-Case](#test-case) that the [ISV integration developer](#ISV-integration-developer) develops to validate product-specific
functionality (as seen in the example [Test-Case](#test-case)).

These test cases are typically developed by copying and extending the [Pre-Canned][#pre-canned-test-case] and
[Example](#example-test-case) test-cases.

### Example test-case
A [Bespoke Test-Case](#bespoke-test-case) that the [Platform Engineering team](#platform-engineering-team)  has developed
as an example to guide you (the [ISV Integration Developer](#isv-integration-developer)) can copy-and-modify for
your own purposes.
---

### Platform builders

TODO: explain why we seperate these out:
1. Too slow to include in the test every time
2. We can pool a bunch of instances so tests can start immediately
3. Must be vetted before running on ISV-CI teams infrastructure.