[![PyPI version](https://img.shields.io/pypi/v/ait-bsc.svg?logo=pypi&logoColor=FFE873)](https://pypi.org/project/ait-bsc/)
[![License](https://img.shields.io/github/license/bsc-pm-ompss-at-fpga/ait.svg)](LICENSE)
[![PyPi Downloads](https://img.shields.io/pypi/dm/ait-bsc?label=PyPI%20Downloads)](https://pypistats.org/packages/ait-bsc)
[![Total Downloads](https://static.pepy.tech/personalized-badge/ait-bsc?period=total&units=international_system&left_color=black&right_color=red&left_text=Total+Downloads)](https://pepy.tech/project/ait-bsc)
[![Supported Python versions](https://img.shields.io/pypi/pyversions/ait-bsc.svg?logo=python&logoColor=FFE873)](https://pypi.org/project/ait-bsc/)

# Accelerator Integration Tool (AIT)

The Accelerator Integration Tool (AIT) automatically integrates OmpSs@FPGA and OmpSs-2@FPGA accelerators into FPGA designs using different vendor backends.

This README should help you install the AIT component of the OmpSs@FPGA toolchain from the repository.
However, it is preferred using the pre-built Docker image with the latest stable toolchain.
They are available at [OmpSs@FPGA pre-built Docker images](https://ompssatfpga.bsc.es/downloads/ompss/docker/) and [OmpSs-2@FPGA pre-built Docker images](https://ompssatfpga.bsc.es/downloads/ompss-2/docker/).

Moreover, there are pre-built SD images for the current supported board families: Zynq7000 and Ultrascale.
They are also available at [OmpSs@FPGA pre-built SD images](https://ompssatfpga.bsc.es/downloads/ompss/sd-images/) and [OmpSs-2@FPGA pre-built SD images](https://ompssatfpga.bsc.es/downloads/ompss-2/sd-images/).

# Prerequisites
 - [Python 3.7 or later](https://www.python.org)
 - [pip](https://pip.pypa.io)
 - Vendor backends:
   - [Xilinx Vivado 2021.1 or later](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html)

#### Git Large File Storage

This repository uses Git Large File Storage to handle relatively-large files that are frequently updated (i.e. hardware runtime IP files) to avoid increasing the history size unnecessarily. You must install it so Git is able to download these files.

Follow instructions on their website to install it.

#### Vendor backends

##### Xilinx Vivado

Follow installation instructions for Xilinx Vivado, Vitis HLS and SDK, as well as enable support during setup for the devices you plan to use.
However, components can be added or removed afterwards.

Current version supports Vivado 2021.1 onwards.

# Installation

## Using pip

You can use `pip` to easily install `ait` on your system:

    python3 -m pip install ait-bsc

## Manual installation

1. Make sure you have the following packages installed on your system

    * `git-lfs` ([Git Large File Storage](https://git-lfs.github.com))
    * `setuptools >= 61.0` ([setuptools](https://setuptools.pypa.io/en/latest/userguide/quickstart.html#installation))

2. Clone AIT's repository

    * From GitHub:

          git clone https://github.com/bsc-pm-ompss-at-fpga/ait.git

    * From our internal GitLab repository (BSC users only):

          git clone https://pm.bsc.es/gitlab/ompss-at-fpga/ait.git

3. Enable Git LFS and install

       cd ait
       git lfs install
       git lfs pull
       export AIT_HOME="/path/to/install/ait"
       export DEB_PYTHON_INSTALL_LAYOUT=deb_system
       python3 -m pip install . -t $AIT_HOME

4. Add the installed binaries to your PATH

       export PATH=$AIT_HOME/bin:$PATH
       export PYTHONPATH=$AIT_HOME:$PYTHONPATH

## Offline installation

1. Make sure you have the following packages installed on your system

    * `wheel` ([wheel](https://wheel.readthedocs.io/en/stable/installing.html))
    * `setuptools >= 61.0` ([setuptools](https://setuptools.pypa.io/en/latest/userguide/quickstart.html#installation))

2. Copy AIT sources into target machine

3. Build wheel for AIT and install

       cd ait
       python3 setup.py bdist_wheel
       export AIT_HOME="/path/to/install/ait"
       export DEB_PYTHON_INSTALL_LAYOUT=deb_system
       python3 -m pip install dist/ait_bsc-*.whl --no-index -t $AIT_HOME

4. Add the installed binaries to your PATH

       export PATH=$AIT_HOME/bin:$PATH
       export PYTHONPATH=$AIT_HOME:$PYTHONPATH

# Tests

#### Prerequisites

 * python3-flake8
 * python3-unittest

#### Style testing

The python code follows PEP 8 style guide which is verified using the `flake8` tool.

To check the current source code just execute `python3 -m flake8`.

#### Unit testing

The `test` folder contains some unitary tests for python sources.

To run all tests the command `python3 -m unittest` can be executed in the root directory of the repository.
