# Creating Tile Config files

When testing tiles, it's often necessary to have a config file that sets property values for deployment. Creating this config file can be challenging without knowing the format.

## Config file basics

A valid config file for testing:

* Must be in either JSON or YAML
* Must have a top-level `product-properties` object
* For every property in the `property-blueprints` section,
  * Must not have a value if the property is `configurable: false`
  * Must have a value if the property is `required: true` and does not have a default value
  * May have a value if the property has a default
  * May have a value if the property is `optional: true`
  * Must not have a value if the property is in a non-selected option of a selector

The tests inside of the [ISV-CI Toolkit](https://github.com/cf-platform-eng/isv-ci-toolkit) will automatically fill in the `network-properties` and `product-name` sections.

## Checking your config

The [`tileinspect`](https://github.com/cf-platform-eng/tileinspect) tool can be used to check if a config file can be used for a tile:

```bash
$ tileinspect check-config --tile my-tile.pivotal --config config.json
The config file appears to be valid
```

## Examples

Given this tile with these properties:

```yaml
---
name: my-sample-tile
description: My Sample Tile
icon_image: ...
...
property_blueprints:
  - name: example_boolean
    configurable: true
    type: boolean
  - name: example_integer
    configurable: true
    type: string
  - name: example_string
    configurable: true
    type: string
  - name: optional_string
    configurable: true
    optional: true
    type: string
  - name: example_selector
    configurable: true
    default: Disabled
    type: selector
    option_templates:
      - name: disabled
        select_value: Disabled
      - name: option_one
        select_value: Option One
        property_blueprints:
          - name: example_secret
            configurable: true
            type: secret
          - name: hostname
            configurable: true
            default: example.com
            type: string
          - name: port
            default: 1234
            type: integer
...
```

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

## External Links

* [Documentation for `om configure-product`](https://github.com/pivotal-cf/om/blob/master/docs/configure-product/README.md)
* [Property Reference on the PCF Tile Dev Guide](https://docs.pivotal.io/tiledev/2-6/property-template-references.html#all-property-types)
