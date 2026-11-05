"""Select one actual Chromium executable for both execution and provenance."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

KEY = 'UMBRAL_CHROMIUM_EXECUTABLE'


def chromium_executable(env=None):
    env = os.environ if env is None else env
    configured = env.get(KEY)
    if configured:
        path = Path(configured).resolve()
        if not path.is_file() or not os.access(path, os.X_OK):
            raise FileNotFoundError('Configured Chromium is missing or not executable: ' + str(path))
        return str(path)
    if env.get('GITHUB_ACTIONS') == 'true':
        raise RuntimeError('CI must pin UMBRAL_CHROMIUM_EXECUTABLE after installing the Playwright browser')
    return shutil.which('chromium', path=env.get('PATH'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--github-env', type=Path)
    args = parser.parse_args()
    from playwright.sync_api import sync_playwright
    with sync_playwright() as engine:
        executable = engine.chromium.executable_path
        executable = chromium_executable({KEY: executable})
        version = subprocess.check_output([executable, '--version'], text=True).strip()
    if not version or '\n' in executable or '\r' in executable:
        raise RuntimeError('Invalid browser executable/version')
    if args.github_env:
        with args.github_env.open('a') as output:
            output.write(KEY + '=' + executable + '\n')
        print('Pinned CI browser: ' + version)
    else:
        print(executable)


if __name__ == '__main__':
    main()
