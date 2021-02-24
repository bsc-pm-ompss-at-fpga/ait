#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2021 Barcelona Supercomputing Center              #
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

from config import msg


class StoreChoiceValue(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, self.choices.index(values))


class StorePath(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, os.path.realpath(values))


class ArgParser():
    def parse_known_args(self, args=None, namespace=None):
        # Check if configuration file exists and parse its values
        config_file_path = os.path.expanduser('~') + '/.ait/config.json'
        if os.path.exists(config_file_path):
            with open(config_file_path) as config_file:
                config = json.load(config_file)
            self.parser.set_defaults(**config)

        # Parse values from argv
        args, extras = self.parser.parse_known_args(args, namespace)
        self.check_args(args)

        return args, extras

        def is_default(self, dest, backend):
            value = False
            if self.defaults[backend][dest] is not None:
                value = self.defaults[backend][dest]['used']
            return value

    def __init__(self):
        # Create vendor-specific parser
        # NOTE: usage must be supressed as this parser is not called directly
        self.parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, epilog='  environment variables:\n    PETALINUX_INSTALL\tpath where Petalinux is installed\n    PETALINUX_BUILD\tpath where the Petalinux project is located', prog='ait', usage=argparse.SUPPRESS)

        # Rename help title
        self.parser._optionals.title = 'Xilinx-specific arguments'

        # Vendor-specific arguments
        self.parser.add_argument('--debug_intfs', help='choose which interfaces mark for debug and instantiate the correspondent ILA cores\nAXI: debug accelerator\'s AXI interfaces\nstream: debug accelerator\'s AXI-Stream interfaces\nboth: debug both accelerator\'s AXI and AXI-Stream interfaces\ncustom: debug user-defined interfaces\nnone: do not mark for debug any interface\n(def: \'none\')', choices=['AXI', 'stream', 'both', 'custom', 'none'], metavar='INTF_TYPE', default='none')
        self.parser.add_argument('--debug_intfs_list', help='path of file with the list of interfaces to debug', action=StorePath)
        self.parser.add_argument('--ignore_eng_sample', help='ignore engineering sample status from chip part number', action='store_true', default=False)
        self.parser.add_argument('--interconnect_opt', help='AXI interconnect optimization strategy: Minimize \'area\' or maximize \'performance\'\n(def: \'area\')', choices=['area', 'performance'], metavar='OPT_STRATEGY', action=StoreChoiceValue, default=0)
        self.parser.add_argument('--interconnect_regslice', help='enable register slices on AXI interconnects\nall: enables them on all interconnects\nDDR: enables them on interconnects in DDR datapath\nhwruntime: enables them on the AXI-stream interconnects betwen the hwruntime and the accelerators\n', nargs='+', choices=['DDR', 'hwruntime', 'all'], metavar='INTER_REGSLICE_LIST')
        self.parser.add_argument('-j', '--jobs', help='specify the number of Vivado jobs to run simultaneously. By default it uses the value returned by `nproc`', type=int, default=int(subprocess.check_output(['nproc'])))
        self.parser.add_argument('--target_language', help='choose target language to synthesize files to: VHDL or Verilog\n(def: \'VHDL\')', choices=['VHDL', 'Verilog'], metavar='TARGET_LANG', default='VHDL')

    def check_args(self, args):
        if args.debug_intfs == 'custom' and args.debug_intfs_list is None:
            msg.error('A file specifying which interfaces to mark for debug is required when choosing \'custom\' value on --debug_intfs argument')
        if args.interconnect_regslice is not None:
            for opt in args.interconnect_regslice:
                if opt == 'all' and len(args.interconnect_regslice) != 1:
                    msg.error("Invalid combination of values for --interconnect_regslice")

parser = ArgParser()
