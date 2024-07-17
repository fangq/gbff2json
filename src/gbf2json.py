#!/usr/bin/env python

###############################################################################
#
# A GenBank GBFF file to JSON file converter
#
# Author:  Qianqian Fang <q.fang at neu.edu>
# Python conversion: Saurabh Gayali <saurabh.gayali@gmail.com>
# License: BSD 3-clause
# Version: 0.5
# URL:     http://openjdata.org
# Github:  https://github.com/fangq/covid19/
#
###############################################################################

import sys
import json
from collections import OrderedDict
import re

def print_usage():
    print("""gbff2json.py - converting GenBank database file to a JSON/JData file
    Format: python gbff2json.py <options> input.gbff > output.json
The supported options include (multiple parameters can be used, separated by spaces)
    -m  convert key names to MATLAB friendly forms, otherwise, keeps the original key names
    -C  use all-caps for top-level key names, otherwise, capitalize only the first letter
    -c  print JSON in compact form, otherwise, print in the indented form""")
    sys.exit(0)

def rmap(obj, opt, origin):
    res = OrderedDict()
    for k, v in obj.items():
        if isinstance(v, list) and len(v) > 0:
            if len(v) == 1:
                res[k] = v[0]
            elif len(v) % 2 == 0:
                res[k] = fixkey(v, opt)
            else:
                res[k] = v
        else:
            res[k] = v
    if origin:
        concatvalue(res, origin)
    return res

def fixkey(obj, opt):
    res = OrderedDict()
    for i in range(0, len(obj), 2):
        k, v = obj[i], obj[i+1]
        res[validname(k, opt)] = v
    return res

def validname(str_val, opt):
    if 'm' not in opt:
        return str_val
    str_val = re.sub(r'[\s/,()]', '_', str_val)
    str_val = re.sub(r'(\d+)\.\.(\d+)', r'From_\1_to_\2', str_val)
    return str_val

def concatvalue(obj, origin):
    if origin in obj:
        obj[origin] = ''.join(obj[origin].values()).replace(' ', '')

def main():
    if len(sys.argv) < 2:
        print_usage()

    key1, key2, key3, originkey = "", "", "", "Origin"
    lastobj = None
    jsonopt = {"ensure_ascii": False, "indent": 4}

    objroot = []
    obj1, obj2, obj3 = OrderedDict(), OrderedDict(), OrderedDict()

    options = ''
    args = sys.argv[1:]
    while args and args[0].startswith('-'):
        opt = args.pop(0)
        if opt == '-m':
            options += 'm'
        elif opt == '-c':
            jsonopt["indent"] = None
        elif opt == '-C':
            options += 'C'
            originkey = "ORIGIN"

    for line in sys.stdin if not args else open(args[0]):
        line = line.strip()
        if not line:
            continue

        match = re.match(r'^((\s*)(\S+)(\s+))(.*)', line)
        if match:
            value = match.group(4) + match.group(5)
            if len(match.group(2)) == 0:
                if obj3:
                    obj2.setdefault(key2, []).append(rmap(obj3, options, ''))
                    obj3 = OrderedDict()
                    key3 = ""
                if obj2:
                    obj1.setdefault(key1, []).append(rmap(obj2, options, ''))
                    obj2 = OrderedDict()
                    key2 = ""
                if line == '//':
                    continue
                key1 = match.group(3).capitalize() if 'C' not in options else match.group(3)
                if (key1 == 'LOCUS' or key1 == 'Locus') and obj1:
                    objroot.append(rmap(obj1, options, originkey))
                    obj1 = OrderedDict()
                if match.group(5):
                    obj1.setdefault(key1, []).append(match.group(5))
                lastobj = obj1.get(match.group(3))
            elif len(match.group(2)) < 12:
                if obj3:
                    obj2.setdefault(key2, []).append(rmap(obj3, options, ''))
                    obj3 = OrderedDict()
                    key3 = ""
                if match.group(5):
                    obj2.setdefault(match.group(3), []).append(match.group(5))
                key2 = match.group(3)
                lastobj = obj2.get(match.group(3))
            elif match.group(3).startswith('/'):
                key3, value = re.match(r'^/([a-z_]+)="?(.*)', match.group(3)).groups()
                value += match.group(5)
                value = value.rstrip('"')
                obj3.setdefault(key3, []).append(value)
                lastobj = obj3.get(key3)
            else:
                line = line.strip()
                if isinstance(lastobj, list):
                    lastobj[0] += line
                else:
                    lastobj.append(line)

    if obj1:
        objroot.append(rmap(obj1, options, originkey))

    if len(objroot) == 1:
        print(json.dumps(objroot[0], **jsonopt))
    else:
        print(json.dumps(objroot, **jsonopt))

if __name__ == "__main__":
    main()

