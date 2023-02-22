#!/usr/bin/env vpython3

import os
import re
import sys
import logging
import argparse
from pathlib import Path
from typing import List

### - CONSTANTS

CWD_PATH = os.path.dirname(os.path.realpath(__file__))
ROOT_PATH = os.path.join(CWD_PATH, os.pardir)

### - FUNCTIONS

def update_repo(version: str):
    for podspec in Path(ROOT_PATH).glob('*.podspec'):
        with open(podspec, 'r') as file:
            data = file.read()
            data = re.sub(r"(s.version\s+)(=\s'.*')", rf"\1= '{version}'", data)
        with open(podspec, 'w') as file:
            file.write(data)

def parse_args() -> List:
    parser = argparse.ArgumentParser(
        description='Update version number in .podspec files'
    )
    parser.add_argument(
        '--version',
        type=str,
        help='Release version.',
        required=True
    )
    return parser.parse_args()

### - MAIN

def main():
    logging.basicConfig()
    logging.getLogger().setLevel(logging.INFO)
    
    args = parse_args()    
    version = f"{args.version}"
    update_repo(version=version)

    return 0

if __name__ == '__main__':
  sys.exit(main())