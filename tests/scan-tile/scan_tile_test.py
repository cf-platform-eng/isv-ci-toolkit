#!/usr/bin/env python

import os
import unittest
import scan_tile
import yaml
import zipfile


trusty_only_metadata = '''---
runtime_configs:
- name: trusty-only
  runtime_config: |
    addons:
    - name: trusty-only
      jobs:
      - name: trusty-only
        release: trusty-only
      include:
        stemcell:
        - os: ubuntu-trusty
'''

xenial_only_metadata = '''---
runtime_configs:
- name: xenial-only
  runtime_config: |
    addons:
    - name: xenial-only
      jobs:
      - name: xenial-only
        release: xenial-only
      include:
        stemcell:
        - os: ubuntu-xenial
'''

xenial_and_trusty_metadata = '''---
runtime_configs:
- name: xenial-and-trusty
  runtime_config: |
    addons:
    - name: xenial-and-trusty
      jobs:
      - name: xenial-and-trusty
        release: xenial-and-trusty
      include:
        stemcell:
        - os: ubuntu-xenial
        - os: ubuntu-trusty
'''

property_defined_stemcell_metadata = '''---
runtime_configs:
- name: property_defined
  runtime_config: |
    addons:
    - name: property_defined
      jobs:
      - name: property_defined
        release: property_defined
      include:
        stemcell: ((this.will.be.defined.from.ops_manager))
'''


class PropertyValueTest(unittest.TestCase):
    def test_valid_property_variable_string(self):
        self.assertTrue(scan_tile.is_property_variable_string("((property))"))

    def test_not_property_variable_string(self):
        self.assertFalse(scan_tile.is_property_variable_string("property"))

    def test_property_variable_string_with_missing_ending(self):
        self.assertFalse(scan_tile.is_property_variable_string("((property"))

    def test_property_variable_string_with_missing_beginning(self):
        self.assertFalse(scan_tile.is_property_variable_string("property))"))


class ScanTileTest(unittest.TestCase):
    def test_runtime_config_trusty_only(self):
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml', trusty_only_metadata)
        self.assertEqual(1, len(matches))

    def test_runtime_config_xenial_only(self):
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml', xenial_only_metadata)
        self.assertEqual(1, len(matches))

    def test_runtime_config_xenial_and_trusty(self):
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml', xenial_and_trusty_metadata)
        self.assertEqual(0, len(matches))

    def test_runtime_config_property_defined(self):
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml', property_defined_stemcell_metadata)
        self.assertEqual(0, len(matches))


class CfCliBoshPackage(unittest.TestCase):
    def test_finds_match_when_cf_cli_bosh_package_present(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with open(os.path.join(this_dir, 'scan-rules.yml')) as f:
            rules = yaml.safe_load(f)['rules']
        rules = [r for r in rules if r['id'] == 'cf-cli-bosh-package']
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'cf-cli-bosh-package.pivotal')) as tile:
            matches = scan_tile.scan_tile(tile, rules)
        self.assertEqual(1, len(matches))

    def test_does_not_match_when_cf_cli_bosh_package_not_present(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with open(os.path.join(this_dir, 'scan-rules.yml')) as f:
            rules = yaml.safe_load(f)['rules']
        rules = [r for r in rules if r['id'] == 'cf-cli-bosh-package']
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'empty.pivotal')) as tile:
            matches = scan_tile.scan_tile(tile, rules)
        self.assertEqual(0, len(matches))


if __name__ == '__main__':
    unittest.main()
