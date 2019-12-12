import tarfile
import tempfile
import shutil
import textwrap
import zipfile
import scan_tile
import sys
import io
import os
import unittest

PATH = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(1, os.path.join(PATH, '..', '..', 'lib'))


def bad_news_bears_matcher(file_path, file_bytes):
    return [{
        'file': file_path,
        'line': 'bad news bears',
        'lineno': 42,
    }]


class ScanTileIntegrationTest(unittest.TestCase):

    def create_rule_file(self, rules):
        rule_path = os.path.join(self.tile_dir, "scan_rules.yml")
        with open(rule_path, 'w') as rules_file:
            rules_file.write(textwrap.dedent(rules))
        return rule_path

    def tile_factory(self, has_broken_symlink=False):
        tar_file_name = os.path.join(self.tile_dir, "test-tile.tgz")

        with tarfile.open(tar_file_name, "w:gz") as tar:
            if has_broken_symlink:
                link_file = os.path.join(self.tile_dir, "myfile.txt")
                os.symlink("/somewhere/else/myfile.txt", link_file)
                tar.add(link_file, "myfile.txt")

            else:
                tinfo = tarfile.TarInfo("myfile.txt")
                contents = "Goldilocks and the three bears"
                tinfo.size = len(contents)
                tar.addfile(tinfo, io.BytesIO(contents.encode('utf8')))

        file_path = os.path.join(self.tile_dir, "test-tile.pivotal")
        with open(file_path, 'wb') as tile:
            with zipfile.ZipFile(tile, 'w') as zip:
                zip.writestr('metadata/test-tile.yml', 'name: test-tile')
                zip.write(tar_file_name, 'releases/test-tile.tgz')
                zip.writestr('migrations/noop.js', '# Do nothing')

        return file_path

    def setUp(self):
        super(ScanTileIntegrationTest, self).setUp()
        self.tile_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tile_dir)

    def test_passes_sha_to_result(self):
        tile_path = self.tile_factory()
        result = scan_tile.main(tile_path, sha="1234")
        self.assertEqual("1234", result['sha'])

    def test_known_good_tile_without_rules_passes(self):
        tile_path = self.tile_factory()
        result = scan_tile.main(tile_path)
        self.assertEqual({}, result)

    def test_text_in_file_pattern(self):
        rules = '''
            ---
            version: 6
            rules:
            - rule:
                or:
                - files: "*/myfile.txt"
                  pattern: bears
              level: WARNING
              affects: 2.2+
              message: >-
                If you have a file called myfile.txt, it's bad news to have bears in it!
              id: bad-news-bears
        '''

        rule_path = self.create_rule_file(rules)
        tile_path = self.tile_factory()

        result = scan_tile.main(tile_path, scan_rules=rule_path)

        self.assertEqual(1, len(result['hits']))
        hit = result['hits'][0]

        self.assertEqual('/releases/test-tile.tgz/myfile.txt', hit['matches'][0]['file'])
        self.assertEqual('bad-news-bears', hit['rule']['id'])

    def test_function_rule(self):
        rules = '''
            ---
            version: 6
            rules:
            - rule:
                files: "*/myfile.txt"
                function:
                  module: scan_tile_integration_test
                  name: bad_news_bears_matcher
              level: WARNING
              affects: 2.2+
              message: >-
                If you have a file called myfile.txt, it's bad news to have bears in it!
              id: bad-news-bears
        '''
        rule_path = self.create_rule_file(rules)
        tile_path = self.tile_factory()

        result = scan_tile.main(tile_path, scan_rules=rule_path)

        self.assertEqual(1, len(result['hits']))
        hit = result['hits'][0]

        self.assertEqual('/releases/test-tile.tgz/myfile.txt', hit['matches'][0]['file'])
        self.assertEqual('bad-news-bears', hit['rule']['id'])

    def test_broken_symlinks_are_ignored(self):
        rules = '''
            ---
            version: 6
            rules:
            - rule:
                or:
                - files: "*/myfile.txt"
                  pattern: bears
                - files: "*/myfile.txt"
                  regex: .*bears.*
                - files: "*/myfile.txt"
                  objectpath: this-doesnt-matter
              level: WARNING
              affects: 2.2+
              message: >-
                If you have a file called myfile.txt, it's bad news to have bears in it!
              id: bad-news-bears
        '''

        rule_path = self.create_rule_file(rules)
        tile_path = self.tile_factory(has_broken_symlink=True)

        result = scan_tile.main(tile_path, scan_rules=rule_path)

        self.assertEqual({'hits': []}, result)


if __name__ == '__main__':
    unittest.main()
