#!/usr/bin/env python3

import argparse
import importlib
import json
import sys
import zipfile
import tarfile
import gzip
import fnmatch
import yaml
import re
import objectpath


def scan_tile(tile, all_rules):
    rule_ids = []
    hits = []
    file_list = all_files(tile)
    for rule in all_rules:
        if 'id' not in rule:
            raise Exception('Rule is missing id: {}'.format(rule))
        if rule['id'] in rule_ids:
            raise Exception('Duplicate rule id: {}'.format(rule['id']))
        rule_ids.append(rule['id'])
        matches = evaluate_rule(tile, rule['rule'], file_list)
        if matches:
            hits.append({
                'rule': rule,
                'matches': matches,
            })
    return hits


def evaluate_rule(tile, rule, file_list):
    matches = []
    if 'and' in rule:
        conditions = rule['and']
        for condition in conditions:
            condition_matches = evaluate_rule(tile, condition, file_list)
            if not condition_matches:
                return []
            matches += condition_matches
    elif 'or' in rule:
        conditions = rule['or']
        for condition in conditions:
            condition_matches = evaluate_rule(tile, condition, file_list)
            if condition_matches:
                matches += condition_matches
    elif 'pattern' in rule:
        for name, entry in file_list.items():
            if fnmatch.fnmatch('/' + name, rule.get('files', '*')):
                try:
                    with open_embedded_file(name, entry['zfile']) as f:
                        for lineno, line in enumerate(f.readlines(), start=1):
                            if rule['pattern'] in line.decode(errors="ignore"):
                                matches.append({
                                    'file': entry['prefix'] + '/' + name,
                                    'line': line.decode(),
                                    'lineno': lineno,
                                })
                        f.close()
                except KeyError:
                    continue
    elif 'regex' in rule:
        for name, entry in file_list.items():
            if fnmatch.fnmatch('/' + name, rule.get('files', '*')):
                try:
                    with open_embedded_file(name, entry['zfile']) as f:
                        content = f.read().decode(errors="ignore")
                        regex_matches = re.findall(rule['regex'], content)
                        for match in regex_matches:
                            matches.append({
                                'file': entry['prefix'] + '/' + name,
                                'line': match,
                            })
                        f.close()
                except KeyError:
                    continue
    elif 'objectpath' in rule:
        for name, entry in file_list.items():
            if fnmatch.fnmatch('/' + name, rule.get('files', '*')):
                try:
                    with open_embedded_file(name, entry['zfile']) as f:
                        tree = objectpath.Tree(yaml.safe_load(f))
                        try:
                            if tree.execute(rule['objectpath']):
                                matches.append({
                                    'file': entry['prefix'] + '/' + name
                                })
                        except StopIteration:
                            pass
                        f.close()
                except KeyError:
                    continue
    elif 'file_exists' in rule:
        for name, entry in file_list.items():
            if fnmatch.fnmatch('/' + name, rule['file_exists']):
                matches.append({
                        'file': entry['prefix'] + '/' + name,
                })
    elif 'function' in rule:
        for name, entry in file_list.items():
            if fnmatch.fnmatch('/' + name, rule.get('files', '*')):
                with open_embedded_file(name, entry['zfile']) as f:
                    matcher_module = importlib.import_module(rule['function']['module'])
                    matcher_function = getattr(matcher_module, rule['function']['name'])
                    matches = matcher_function(entry['prefix'] + '/' + name, f)
                    f.close()
    else:
        raise Exception(
            'Incorrect rule in scan-rules.yml:\n' + yaml.safe_dump(rule))
    return matches


def get_metadata(tile):
    metadata_file = next(path for path in tile.namelist() if path.startswith('metadata/') and path.endswith('.yml'))
    with tile.open(metadata_file) as metadata:
        return yaml.safe_load(metadata.read())


def get_tile_generator(tile):
    result = None
    version_file = next((path for path in tile.namelist()
                         if path == 'tile-generator/version'), None)
    if version_file:
        result = {}
        with tile.open(version_file) as f:
            result['version'] = f.read().decode()
    tile_yml_file = next((path for path in tile.namelist()
                          if path == 'tile-generator/tile.yml'), None)
    if version_file and tile_yml_file:
        with tile.open(tile_yml_file) as f:
            result['tile_yml'] = f.read().decode()
    return result


generated_types = [
    'rsa_cert_credentials',
    'rsa_pkey_credentials',
    'salted_credentials',
    'simple_credentials',
    'secret',
    'uuid',
]


def property_is_required(tile_property):
    if 'default' in tile_property:
        return False
    if tile_property['type'] in generated_types:
        return False
    optional = tile_property.get('optional', False)
    return not optional


def required_properties(node, path=[]):
    ret = []
    if isinstance(node, dict):
        for key, value in node.items():
            if key == 'property_blueprints' and value:
                for tile_property in value:
                    if property_is_required(tile_property):
                        ret += ['{} (type: {})'.format(tile_property['name'],
                                                       tile_property['type'])]
                    elif tile_property['type'] == 'selector':
                        ret += ['Check selector {} for required subproperties'.format(
                            path + [key, tile_property['name']])]
            else:
                ret += required_properties(value, path + [key])
    if isinstance(node, list):
        for index, item in enumerate(node):
            ret += required_properties(item, path + [index])
    return ret


def get_namelist(archive_file):
    if isinstance(archive_file, zipfile.ZipFile):
        return archive_file.namelist()
    else:
        return archive_file.getnames()


def open_embedded_file(name, archive_file):
    if isinstance(archive_file, zipfile.ZipFile):
        return archive_file.open(name)
    else:  # tarfile.
        return archive_file.extractfile(name)


def all_files(zfile, prefix=''):
    file_list = {}
    for name in get_namelist(zfile):
        if name.endswith('.tgz'):
            try:
                embedded_file = open_embedded_file(name, zfile)
                embedded_file = gzip.GzipFile(fileobj=embedded_file)
                embedded_file = tarfile.TarFile(fileobj=embedded_file)
                nested_files = all_files(embedded_file, prefix=prefix + '/' + name)
                file_list.update(nested_files)
            except Exception as e:
                print('{}/{} is not a valid tgz file: {}'.format(prefix, name, e), file=sys.stderr)
                continue
        file_list[name] = {'zfile': zfile, 'prefix': prefix}
    return file_list


def main(tile, do_metadata=False, scan_rules=None, sha=None):
    result = {}
    with zipfile.ZipFile(tile) as tile:
        if do_metadata:
            result['metadata'] = get_metadata(tile)
            result['required_properties'] = required_properties(
                result['metadata'])
            tile_generator = get_tile_generator(tile)
            if tile_generator:
                result['tile_generator'] = tile_generator
        if scan_rules:
            with open(scan_rules) as f:
                rules = yaml.safe_load(f)['rules']
            result['hits'] = scan_tile(tile, rules)
    if sha is not None:
        result['sha'] = sha
    return result


def is_property_variable_string(value):
    return value.startswith("((") and value.endswith("))")


def runtime_config_supports_xenial_and_trusty(file_path, file_bytes):
    matches = []
    metadata = yaml.safe_load(file_bytes)
    for runtime_config_item in metadata.get('runtime_configs', []):
        runtime_config_str = runtime_config_item['runtime_config']
        runtime_config = yaml.safe_load(runtime_config_str)
        for addon in runtime_config.get('addons', []):
            includes_trusty = False
            includes_xenial = False
            include_rules = addon.get('include', {})

            stemcell_inclusion_rules = include_rules.get('stemcell', [])
            if isinstance(stemcell_inclusion_rules, list):
                for included_stemcell in stemcell_inclusion_rules:
                    if included_stemcell.get('os') == 'ubuntu-trusty':
                        includes_trusty = True
                    elif included_stemcell.get('os') == 'ubuntu-xenial':
                        includes_xenial = True
                if includes_xenial and not includes_trusty:
                    matches.append({
                        'file': file_path,
                    })
                elif includes_trusty and not includes_xenial:
                    matches.append({
                        'file': file_path,
                    })
            elif isinstance(stemcell_inclusion_rules, str):
                if not is_property_variable_string(stemcell_inclusion_rules):
                    print(stemcell_inclusion_rules, 'is not a valid stemcell inclusion rule', file=sys.stderr)
            else:
                print('unexpected stemcell inclusion rule type', file=sys.stderr)

    return matches


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Scan a tile for potential issues',
        epilog='Exit code: 0 if no issues found, otherwise 1 and issues are printed.',
    )
    parser.add_argument('--metadata', help='print tile metadata as json', action='store_true')
    parser.add_argument('--scan', help='yaml file with rules to scan for', nargs=1)
    parser.add_argument('--sha', help='sha to include with results', nargs=1)
    parser.add_argument('tile', help='.pivotal file to scan')
    args = parser.parse_args()
    result = main(args.tile, args.metadata,
                  args.scan[0] if args.scan else None, args.sha[0] if args.sha else None)

    print(json.dumps(result))
