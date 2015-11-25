#!/usr/bin/env python

"""
Scan stdin for bug number list and print output with URL to stdout.

Note that titles for private bugs are not fetched but instead are marked
(Private).

Example use:
% cat file_with_bugs.txt | lp_bug_titles.py >

Required pacakages:
python-launchpadlib

Original author: kiko (contributed to launchpadlib)
Modified by: beagles
(Modified to help track bugfixes between releases)
"""

import os
import sys
import re

from launchpadlib import errors
from launchpadlib.launchpad import Launchpad

launchpad = Launchpad.login_anonymously(os.path.basename(sys.argv[0]),
                                        'production')
bugs = launchpad.bugs

def main():
    text = sys.stdin.read()

    bug_list = text.split('\n')

    for b in bug_list:
        if not b:
            continue
        try:
            bug = bugs[b]
            summary = bug.title
        except errors.HTTPError:
            summary = 'Private'
        print 'https://bugs.launchpad.net/neutron/+bug/%s' % b.strip(), summary

if __name__ == '__main__':
    main()
