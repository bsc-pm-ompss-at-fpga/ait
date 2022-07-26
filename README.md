# Accelerator Integration Tool (AIT)

The Accelerator Integration Tool (AIT) automatically integrates OmpSs@FPGA accelerators into FPGA designs using different vendor backends.

This README should help you install the AIT component of the OmpSs@FPGA toolchain from the repository.
However, it is preferred using the pre-built Docker image with the latest stable toolchain.
They are available at [OmpSs@FPGA pre-built Docker images](https://ompssatfpga.bsc.es/downloads/docker/).
Moreover, there are pre-built SD images for the current supported board families: Zynq7000 and Ultrascale.
They are also available at [OmpSs@FPGA pre-built SD images](https://ompssatfpga.bsc.es/downloads/sd-images/).

# Prerequisites
 - [Python 3.5 or later](https://www.python.org)
 - [pip](https://pip.pypa.io)
 - Vendor backends:
   - [Xilinx Vivado 2018.3 or later](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html)

#### Git Large File Storage

This repository uses Git Large File Storage to handle relatively-large files that are frequently updated (i.e. hardware runtime IP files) to avoid increasing the history size unnecessarily. You must install it so Git is able to download these files.

Follow instructions on their website to install it.

#### Vendor backends

##### Xilinx Vivado

Follow installation instructions from Xilinx
Vivado, Vivado HLS and SDK, as well as the device support for the devices you're working, should be enabled during setup.
However, components can be added or removed afterwards.

Current version supports Vivado 2018.3 onwards.

# Installation

You can use `pip` to easily install `ait` on your system:

    python3 -m pip install ait-bsc

# Development

1. Make sure you have the following packages installed on your system.

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

# Tests

#### Style testing

The python code follows pycodestyle which is verified using the `pycodestyle` tool (can be installed with `python3 -m pip install pycodestyle`).
To check the current source code just execute `pycodestyle`.

#### Unit testing

The `test` folder contains some unitary tests for python sources.
To run all tests the command `python3 -m unittest` can be executed in the root directory of the repository.
