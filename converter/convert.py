#!/usr/bin/env python3

import json


def main():
    fname = "quickjump.json"
    with open(fname) as f:
        d = json.load(f)
    #
    longest_key = 0
    for path, key in d.items():
        if len(key) > longest_key:
            longest_key = len(key)
        #
    #
    for path, key in d.items():
        width = longest_key - len(key) + 4
        print('"{0}":{1}"{2}"'.format(key, width * " ", path))
    #


##############################################################################

if __name__ == "__main__":
    main()
