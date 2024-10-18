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

        config_commit = config.replace("VERSION_COMMIT = '{}'".format(version_commit), "VERSION_COMMIT = ''")

        with open('ait/frontend/config.py', 'w') as config_file:
            config_file.write(config_commit)


class PostInstallCommand(install):
    """Post-installation for installation mode."""
    def run(self):
        install.run(self)
        with open('ait/frontend/config.py', 'r') as config_file:
            config = config_file.read()

        config_commit = config.replace("VERSION_COMMIT = '{}'".format(version_commit), "VERSION_COMMIT = ''")

        with open('ait/frontend/config.py', 'w') as config_file:
            config_file.write(config_commit)


tag = subprocess.run('git describe --tags --exact-match HEAD', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
commit_hash = subprocess.run('git show -s --format=%h', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
commit_file = subprocess.run('cat COMMIT', shell=True, capture_output=True, encoding='utf-8').stdout.strip()

version_commit = ''
if tag:
    version_commit = tag
elif commit_hash:
    commit_hash += subprocess.run("git diff --quiet HEAD || echo '-dirty'", shell=True, capture_output=True, encoding='utf-8').stdout.strip()
    version_commit = 'commit: ' + commit_hash
elif commit_file:
    version_commit = 'commit: ' + commit_file

if version_commit:
    with open('ait/frontend/config.py', 'r') as config_file:
        config = config_file.read()

    config_commit = config.replace("VERSION_COMMIT = ''", "VERSION_COMMIT = '{}'".format(version_commit))

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
    with open("ait/frontend/config.py", "w") as config_file:
        config_file.write(config)
