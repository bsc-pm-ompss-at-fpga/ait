# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2025 Barcelona Supercomputing Center              #
#                             Centro Nacional de Supercomputacion          #
#                                                                          #
#     This file is part of OmpSs@FPGA toolchain.                           #
#                                                                          #
#     This code is free software; you can redistribute it and/or modify    #
#     it under the terms of the GNU Lesser General Public License as       #
#     published by the Free Software Foundation; either version 3 of       #
#     the License, or (at your option) any later version.                  #
#                                                                          #
#     OmpSs@FPGA toolchain is distributed in the hope that it will be      #
#     useful, but WITHOUT ANY WARRANTY; without even the implied           #
#     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.     #
#     See the GNU Lesser General Public License for more details.          #
#                                                                          #
#     You should have received a copy of the GNU Lesser General Public     #
#     License along with this code. If not, see <www.gnu.org/licenses/>.   #
# ------------------------------------------------------------------------ #

import subprocess

import setuptools
from setuptools.command.develop import develop
from setuptools.command.install import install


class PostDevelopCommand(develop):
    """Post-installation for development mode."""
    def run(self):
        develop.run(self)
        with open('ait/frontend/config.py', 'r') as config_file:
            config = config_file.read()

        config_commit = config.replace(f"VERSION_COMMIT = '{version_commit}'", "VERSION_COMMIT = ''")

        with open('ait/frontend/config.py', 'w') as config_file:
            config_file.write(config_commit)


class PostInstallCommand(install):
    """Post-installation for installation mode."""
    def run(self):
        install.run(self)
        with open('ait/frontend/config.py', 'r') as config_file:
            config = config_file.read()

        config_commit = config.replace(f"VERSION_COMMIT = '{version_commit}'", "VERSION_COMMIT = ''")

        with open('ait/frontend/config.py', 'w') as config_file:
            config_file.write(config_commit)


tag = subprocess.run('git describe --tags --exact-match HEAD', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
dirty = subprocess.run('git diff', shell=True, capture_output=True)
commit_hash = subprocess.run('git show -s --format=%h', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
commit_file = subprocess.run('cat COMMIT', shell=True, capture_output=True, encoding='utf-8').stdout.strip()

version_commit = ''
if dirty.stdout and not dirty.returncode:
    if commit_hash:
        version_commit = f'commit: {commit_hash}-dirty'
    elif commit_file:
        version_commit = f'commit: {commit_file}-dirty'
else:
    if tag:
        version_commit = tag
    elif commit_hash:
        version_commit = f'commit: {commit_hash}'
    elif commit_file:
        version_commit = f'commit: {commit_file}'

if version_commit:
    with open('ait/frontend/config.py', 'r') as config_file:
        config = config_file.read()

    config_commit = config.replace("VERSION_COMMIT = ''", f"VERSION_COMMIT = '{version_commit}'")

    with open('ait/frontend/config.py', 'w') as config_file:
        config_file.write(config_commit)

with open('README.md', 'r') as fh:
    long_description = fh.read()

setuptools.setup(
    cmdclass={
        'develop': PostDevelopCommand,
        'install': PostInstallCommand,
    }
)

if version_commit:
    with open('ait/frontend/config.py', 'w') as config_file:
        config_file.write(config)
