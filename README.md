# Accelerator Integration Tool (AIT)

The Accelerator Integration Tool (AIT) automatically integrates OmpSs@FPGA accelerators into FPGA designs using different vendor backends.

This README should help you install the AIT component of the OmpSs@FPGA toolchain from the repository.
However, it is preferred using the pre-build Docker image with the latest stable toolchain.
They are available at [ompssatfpga.bsc.es/downloads/](https://ompssatfpga.bsc.es/downloads/docker/).
Moreover, there are pre-build SD images for the current supported board families: Zynq7000 and Ultrascale.
They are also available at [ompssatfpga.bsc.es/downloads/](https://ompssatfpga.bsc.es/downloads/SD-images/).

# Prerequisites
 - [Git Large File Storage](https://git-lfs.github.com/)
 - [Python 3.5 or later](https://www.python.org/)
 - Vendor backends:
   - [Xilinx Vivado 2018.3 or later](https://www.xilinx.com/products/design-tools/vivado.html)

#### Git Large File Storage

This repository uses Git Large File Storage to handle relatively-large files that are frequently updated (i.e. hardware runtime IP files) to avoid increasing the history size unnecessarily. You must install it so Git is able to download these files.

Follow instructions on their website to install it.

#### Vendor backends

##### Xilinx Vivado

Follow installation instructions from Xilinx
Vivado, VivadoHLS and SDK, as well as the device support for the devices you're working, should be enabled during setup.
However, components can be added or removed afterwards.

Current version supports Vivado 2018.3 onwards.

# Installation

To install AIT just clone the repository, run the `<ait>/install.sh` script and add `PREFIX/ait/` to PATH.
```bash
git clone https://gitlab.bsc.es/ompss-at-fpga/ait
cd ait
./install.sh PREFIX/ait/ all
export PATH=PREFIX/<ait>/:$PATH
```

This will install AIT for all the vendor backends available and all the boards supported. If you want to make a lighter installation, with fewer vendors, you can change the arguments passed to `install.sh`:
```bash
USAGE:  ./install.sh <prefix> <backend>
  <prefix> path where the AIT files will be installed
  <backend> supported values: all, xilinx
```
Finally, if you plan to make any commit, you must enable Git LFS inside the repository:
```bash
cd ait
git lfs install
```

# Tests

#### Style testing

The python code follows pycodestyle (formerly pep8) which is verified using the `pycode style` tool (can be installed with `pip install pycodestyle`).
To check the current source code just execute `pycodestyle`.

#### Unit testing

The `test` folder contains some unitary tests for python sources.
To run all tests the command `python3 -m unittest` can be executed in the root directory of the repository.
