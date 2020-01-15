#!/usr/bin/env python
import io
import os
import unittest
import zipfile

import yaml
from mock import MagicMock

import scan_tile

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
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml',
                                                                      xenial_and_trusty_metadata)
        self.assertEqual(0, len(matches))

    def test_runtime_config_property_defined(self):
        matches = scan_tile.runtime_config_supports_xenial_and_trusty('/metadata/test-tile.yml',
                                                                      property_defined_stemcell_metadata)
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


class MetadataParsing(unittest.TestCase):
    def test_text_icon_image_returned_as_string(self):
        metadata = io.StringIO(
            """---
            icon_image: SGVsbG8hCg==
            """
        )
        tile = MagicMock()
        tile.namelist.return_value = ["metadata/foo.yml"]
        tile.open.return_value = metadata
        metadata = scan_tile.get_metadata(tile)
        self.assertEqual(metadata['icon_image'], "SGVsbG8hCg==")

    def test_binary_icon_image_returned_as_string(self):
        metadata = io.StringIO(
            """---
            icon_image: !!binary SGVsbG8hCg==
            """
        )
        tile = MagicMock()
        tile.namelist.return_value = ["metadata/foo.yml"]
        tile.open.return_value = metadata
        metadata = scan_tile.get_metadata(tile)
        self.assertEqual(metadata['icon_image'], "SGVsbG8hCg==")


class NestedFileSearching(unittest.TestCase):
    def test_empty_tile_does_not_expands(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'empty.pivotal')) as tile:
            files = scan_tile.all_files(tile)
            self.assertEqual(1, len(files))
            self.assertIsNotNone(files["empty/"]["zfile"])
            self.assertEqual(files["empty/"]["prefix"], "")

    def test_tile_containing_zipfile_does_not_expand(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'contains_zipfile.pivotal')) as tile:
            files = scan_tile.all_files(tile)
            self.assertEqual(1, len(files))
            self.assertIsNotNone(files["zipfile.zip"]["zfile"])
            self.assertEqual(files["zipfile.zip"]["prefix"], "")

    def test_tile_containing_tarfile_does_not_expand(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'contains_tarfile.pivotal')) as tile:
            files = scan_tile.all_files(tile)
            self.assertEqual(1, len(files))
            self.assertIsNotNone(files["tarfile.tar"]["zfile"])
            self.assertEqual(files["tarfile.tar"]["prefix"], "")

    def test_tile_containing_tgz_file_does_expand(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'contains_gzipped_tarfile.pivotal')) as tile:
            files = scan_tile.all_files(tile)
            self.assertEqual(2, len(files))
            self.assertIsNotNone(files["gzipped_tar_file.tgz"]["zfile"])
            self.assertEqual(files["gzipped_tar_file.tgz"]["prefix"], "")
            self.assertIsNotNone(files["a_file"]["zfile"])
            self.assertEqual(files["a_file"]["prefix"], "/gzipped_tar_file.tgz")

    def test_tile_containing_tarfile_that_is_named_tgz_is_skipped(self):
        this_dir = os.path.dirname(os.path.realpath(__file__))
        with zipfile.ZipFile(os.path.join(this_dir, 'test-input-files', 'contains_tgz_file_but_is_tarfile.pivotal')) as tile:
            files = scan_tile.all_files(tile)
            self.assertEqual(0, len(files))


if __name__ == '__main__':
    unittest.main()
