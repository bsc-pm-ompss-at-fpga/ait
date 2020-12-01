#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2020 Barcelona Supercomputing Center              #
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

import os
import json
import argparse
import subprocess


class StoreChoiceValue(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, self.choices.index(values))


# Create vendor-specific parser
# NOTE: usage must be supressed as this parser is not called directly
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, epilog='  environment variables:\n    PETALINUX_INSTALL\tpath where Petalinux is installed\n    PETALINUX_BUILD\tpath where the Petalinux project is located', prog='ait', usage=argparse.SUPPRESS)

# Rename help title
parser._optionals.title = 'Xilinx-specific arguments'

# Vendor-specific arguments
parser.add_argument('--ignore_eng_sample', help='ignore engineering sample status from chip part number', action='store_true', default=False)
parser.add_argument('--interconnect_opt', help='AXI interconnect optimization strategy: Minimize \'area\' or maximize \'performance\'\n(def: \'area\')', choices=['area', 'performance'], metavar='OPT_STRATEGY', action=StoreChoiceValue, default=0)
parser.add_argument('--interconnect_regslice', help='enable register slices on AXI interconnects\nall: enables them on all interconnects\nDDR: enables them on interconnects in DDR datapath\nnone: do not enable any register slice\n(def: \'none\')', choices=['none', 'DDR', 'all'], metavar='INTER_REGSLICE', action=StoreChoiceValue, default=0)
parser.add_argument('--target_language', help='choose target language to synthesize files to: VHDL or Verilog\n(def: \'VHDL\')', choices=['VHDL', 'Verilog'], metavar='TARGET_LANG', default='VHDL')
parser.add_argument('-j', '--jobs', help='specify the number of Vivado jobs to run simultaneously. By default it uses the value returned by `nproc`', type=int, default=int(subprocess.check_output(['nproc'])))


def parse_args(self):
    # Check if configuration file exists and parse its values
    config_file_path = os.path.expanduser('~') + '/.ait/config.json'
    if os.path.exists(config_file_path):
        with open(config_file_path) as config_file:
            config = json.load(config_file)
        self.parser.set_defaults(**config)

    # Parse values from argv
    args = self.parser.parse_args()

    return args

    def is_default(self, dest, backend):
        value = False
        if self.defaults[backend][dest] is not None:
            value = self.defaults[backend][dest]['used']
        return value
