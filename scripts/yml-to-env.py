#!/usr/bin/env python
import re
import yaml
import sys
from shellescape import quote

'''
To call this, do this:
  $ eval `./scripts/yml-to-env.py <YML or JSON file>`
'''
if __name__ == '__main__':
    with open(sys.argv[1], 'r') as yaml_file:
        parsed = yaml.safe_load(yaml_file);
        for key, value in parsed.iteritems():
            print("export %s=%s" % (re.sub("-", "_", key.upper()), quote(str(value))))
