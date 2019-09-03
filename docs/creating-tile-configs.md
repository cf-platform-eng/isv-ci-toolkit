# Creating Tile Config files

When testing tiles, it's often necessary to have a config file that sets property values before deployment. Creating this config file can be challenging without knowing the format.

## Config file basics

A valid config file:

* Must be in either JSON or YAML
* Must have a top-level `product-properties` object
* For every property in the `property-blueprints` section,
  * Must not have a value if the property is `configurable: false`
  * Must have a value if the property is `required: true` and does not have a default value
  * May have a value if the property has a default
  * May have a value if the property is `optional: true`
  * May not have a value if the property is in a non-selected option of a selector

## Checking your config

The [`tileinspect`](https://github.com/cf-platform-eng/tileinspect) tool can be used to validate that a config file defines the necessary values:

```bash
$ tileinspect check-config --tile my-tile.pivotal --config config.json
The config file appears to be valid
```

## Examples

### JSON

```json
{
  "product-properties": {
    ".properties.example_boolean": {
      "type": "boolean",
      "value": false
    },
    ".properties.example_integer": {
      "type": "integer",
      "value": 123
    },
    ".properties.example_string": {
      "type": "string",
      "value": "this is my string"
    },
    ".properties.example_selector": {
      "type": "selector",
      "value": "Option One"
    },
    ".properties.example_selector.option_one.example_secret": {
      "type": "secret",
      "value": {
        "secret": "my-password123!"
      }
    }
  }
}
```

### YAML

```yaml
product-properties:
  ".properties.example_boolean":
    type: boolean
    value: false
  ".properties.example_integer":
    type: integer
    value: 123
  ".properties.example_string":
    type: string
    value: this is my string
  ".properties.example_selector":
    type: selector
    value: Option One
  ".properties.example_selector.option_one.example_secret":
    type: secret
    value:
      secret: my-password123!
```
