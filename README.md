# Accelerator Integration Tool (AIT)

The Accelerator Integration Tool (AIT) automatically integrates OmpSs@FPGA accelerators into FPGA designs using different vendor backends.

This README should help you install the AIT component of the OmpSs@FPGA toolchain from the repository.
However, it is preferred using the pre-built Docker image with the latest stable toolchain.
They are available at [OmpSs@FPGA pre-built Docker images](https://ompssatfpga.bsc.es/downloads/docker/).
Moreover, there are pre-built SD images for the current supported board families: Zynq7000 and Ultrascale.
They are also available at [OmpSs@FPGA pre-built SD images](https://ompssatfpga.bsc.es/downloads/sd-images/).

# Prerequisites
 - [Git Large File Storage](https://git-lfs.github.com/)
 - [Python 3.5 or later](https://www.python.org/)
 - Vendor backends:
   - [Xilinx Vivado 2018.3 or later](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html)

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

* Clone AIT's repository

    From GitHub:

	  git clone https://github.com/bsc-pm-ompss-at-fpga/ait.git

	From our internal GitLab repository (BSC users only):

	  git clone https://pm.bsc.es/gitlab/ompss-at-fpga/ait.git

* Enable Git LFS and install

	  cd ait
	  git lfs install
	  git lfs pull
	  export AIT=/path/to/install/ait
	  ./install.sh $AIT all

* Add the installed binaries to your PATH

	  export PATH=$AIT:$PATH

This will install AIT for all the vendor backends available and all the boards supported. If you want to make a lighter installation, with fewer vendors, you can change the arguments passed to `install.sh`:

	USAGE:  ./install.sh <prefix> <backend>
  	<prefix> path where the AIT files will be installed
  	<backend> supported values: all, xilinx

# Tests

#### Style testing

The python code follows pycodestyle which is verified using the `pycodestyle` tool (can be installed with `pip install pycodestyle`).
To check the current source code just execute `pycodestyle`.

#### Unit testing

The `test` folder contains some unitary tests for python sources.
To run all tests the command `python3 -m unittest` can be executed in the root directory of the repository.
