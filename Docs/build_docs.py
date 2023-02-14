#!/usr/bin/env vpython3

import os
import sys
import re
import argparse
from dataclasses import dataclass
from pathlib import Path

CWD_PATH = os.path.dirname(os.path.realpath(__file__))
OUTPUT_PATH = os.path.join(CWD_PATH, 'output')
SITE_PATH = os.path.join(CWD_PATH, 'static')
HEADER_PATH = os.path.join(CWD_PATH, 'header.html')

### - CLASSES

@dataclass
class Platform:
    name: str
    display_name: str
    destination: str

### - FUNCTIONS

def set_version(version):
    path = Path(HEADER_PATH)
    text = path.read_text()
    text = re.sub(r'<div class="version">.*</div>', f'<div class="version">{version}</div>', text)
    path.open('w').write(text)

def add_header(output_path):
    docs_path = os.path.join(output_path, 'documentation')
    
    header = Path(HEADER_PATH).read_text()
    header_css = '<link rel="stylesheet" href="/pexip-swift-sdk/assets/header.css">'
    
    for path in Path(docs_path).rglob('*.html'):
        text = path.read_text()
        text = re.sub(r'(.*)(<title)', rf'\1{header_css}\2', text)
        text = re.sub(r'(<body data-color-scheme="auto">)(.*)', rf'\1{header}\2', text)
        path.open('w').write(text)

def add_display_name_platform(path, platform):
    for path in Path(path).rglob('*.md'):
        text = path.read_text()
        text = re.sub(rf'(@DisplayName\(".*)(")', rf'\1{platform}\2', text)
        path.open('w').write(text)

def remove_display_name_platform(path, platform):
    for path in Path(path).rglob('*.md'):
        text = path.read_text()
        text = text.replace(f'{platform}", style: symbol)', f'", style: symbol)')
        path.open('w').write(text)

def build_sdk_docs():
    package_path = os.path.join(CWD_PATH, 'pexip-swift-sdk-docs')
    output_path = os.path.join(OUTPUT_PATH, 'sdk')
    
    os.chdir(package_path)

    cmd = [
        f'swift package',
        f'--allow-writing-to-directory {output_path}',
        'generate-documentation',
        f'--output-path {output_path}',
        '--transform-for-static-hosting',
        '--hosting-base-path pexip-swift-sdk/sdk',
    ]
    
    os.system(' '.join(cmd))
    add_header(output_path)

def build_framework_docs():
    package_path = os.path.join(CWD_PATH, os.pardir)
    sources_path = os.path.join(package_path, 'Sources')
    docs_data_path = os.path.join(OUTPUT_PATH, 'data')
    docs_archives_path = os.path.join(OUTPUT_PATH, 'archives')
    docs_web_path = os.path.join(OUTPUT_PATH, 'frameworks')

    dirs = [
        docs_data_path,
        docs_archives_path,
        docs_web_path
    ]

    for dir in dirs:
        os.system(f'mkdir {dir}')

    platforms = [
        Platform('ios', 'iOS', 'platform=iOS Simulator,name=iPhone 13 Pro'),
        Platform('macos', 'macOS', 'platform=macOS,arch=arm64')
    ]
    
    for platform in platforms:
        # 1. Build documentation
        data_path = os.path.join(docs_data_path, platform.name)

        display_name_suffix = f" ({platform.display_name})"
        add_display_name_platform(sources_path, display_name_suffix)
        
        cmd = [
            'xcodebuild',
            '-scheme',
            'Pexip-Package',
            f'-derivedDataPath {data_path}',
            f'-destination "{platform.destination}"', 
            '-parallelizeTargets', 
            'docbuild'
        ]
        
        os.chdir(package_path)
        os.system(' '.join(cmd))
        os.chdir(CWD_PATH)

        remove_display_name_platform(sources_path, display_name_suffix)

        # 2. Store documentation archives
        archives_path = os.path.join(docs_archives_path, platform.name)
        os.system(f'mkdir {archives_path}')
        os.system(f'cp -R `find {data_path} -type d -name "*.doccarchive"` {archives_path}')

        # 3. Generate the static site
        web_path = os.path.join(docs_web_path, platform.name)
        os.system(f'mkdir {web_path}')
        
        for filename in os.listdir(archives_path):
            file_path = os.path.join(archives_path, filename)
            stem = Path(filename).stem
            output_path = os.path.join(web_path, stem)
            cmd = [
                '$(xcrun --find docc)',
                'process-archive', 
                'transform-for-static-hosting',
                file_path, 
                '--hosting-base-path',
                f'pexip-swift-sdk/frameworks/{platform.name}/{stem}',
                '--output-path',
                output_path
            ]
            os.system(' '.join(cmd))
            add_header(output_path)

### - SCRIPT ARGUMENTS

def parse_args():
    parser = argparse.ArgumentParser(
        description='Build documentation for Pexip Swift SDK frameworks'
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
    args = parse_args()    
    version = f"{args.version}"
    set_version(version)
    
    os.system(f'rm -rf {OUTPUT_PATH}')
    os.system(f'mkdir {OUTPUT_PATH}')
    
    build_sdk_docs()
    build_framework_docs()

    os.system(f'cp -r {OUTPUT_PATH}/sdk {SITE_PATH}')
    os.system(f'cp -r {OUTPUT_PATH}/frameworks {SITE_PATH}')

if __name__ == '__main__':
    sys.exit(main())