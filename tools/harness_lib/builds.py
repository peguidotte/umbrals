"""Publish compatibility pointers; task consumers always use immutable build paths."""
import os
from .manifest import ROOT

def publish_build(build, target):
    # Compatibility pointer only. Runner consumers use the immutable build directory.
    directory = ROOT / 'builds'
    directory.mkdir(exist_ok=True)
    destination = directory / target.lower()
    if destination.exists() and not destination.is_symlink():
        archive = directory / '.previous'
        archive.mkdir(exist_ok=True)
        destination.rename(archive / (target.lower() + '-' + os.urandom(4).hex()))
    temporary = destination.with_name(destination.name + '.tmp-' + str(os.getpid()))
    temporary.symlink_to(build, target_is_directory=True)
    temporary.replace(destination)

