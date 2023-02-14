#!/usr/bin/env vpython3

import os
import sys
import logging
import subprocess
from pathlib import Path
from typing import List

### - CONSTANTS

CWD_PATH = os.path.dirname(os.path.realpath(__file__))
ROOT_PATH = os.path.join(CWD_PATH, os.pardir)
POD_SPECS_URL = 'https://github.com/pexip/pexip-pod-specs.git'

### - FUNCTIONS

def run(cmd: List[str], cwd: str):
    logging.debug(f"Running: {' '.join(str(cmd))}")
    subprocess.check_call(cmd, cwd=cwd)

### - MAIN

def main():
    logging.basicConfig()
    logging.getLogger().setLevel(logging.INFO)

    repo_name = 'pexip-specs'
    
    if not os.path.isdir(f"{Path.home()}/.cocoapods/repos/{repo_name}"):
        run(['pod', 'repo', 'add', repo_name, POD_SPECS_URL], cwd=ROOT_PATH)
    
    for podspec in Path(ROOT_PATH).glob('*.podspec'):
        run(['pod', 'repo', 'push', repo_name, podspec, '--allow-warnings'], cwd=ROOT_PATH)

    return 0

if __name__ == '__main__':
  sys.exit(main())