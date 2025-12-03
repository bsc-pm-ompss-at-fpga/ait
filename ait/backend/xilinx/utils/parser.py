#!/usr/bin/env python3
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

import argparse
import json
import re
import os

from ait.frontend.utils import decimalToHumanReadable, msg


class StoreChoiceValue(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, self.choices.index(values))


# Custom argparse type representing the number of pipeline stages
class PipelineStagesType:
    def __call__(self, arg):
        if re.match('[1-5](:[1-5]){2}', arg):
            return str(arg)
        elif arg == 'auto':
            return arg
        else:
            raise argparse.ArgumentTypeError('must be an integer between 1 and 5 in the format x:y:z or \'auto\'')


# Custom argparse type representing a path to a file
class FileType:
    def __call__(self, arg):
        if os.path.isfile(arg):
            return os.path.realpath(arg)
        else:
            raise argparse.ArgumentTypeError('Invalid file')


# Custom argparse type representing a bounded int
class IntRangeType:
    def __init__(self, imin=None, imax=None):
        self.imin = imin
        self.imax = imax

    def __call__(self, arg):
        try:
            value = int(arg)
        except ValueError:
            raise self.exception()
        if (self.imin is not None and value < self.imin) or (self.imax is not None and value > self.imax):
            raise self.exception()
        return value

    def exception(self):
        if self.imin is not None and self.imax is not None:
            return argparse.ArgumentTypeError(f'must be an integer in the range [{self.imin}, {self.imax}]')
        elif self.imin is not None:
            return argparse.ArgumentTypeError(f'must be an integer >= {self.imin}')
        elif self.imax is not None:
            return argparse.ArgumentTypeError(f'must be an integer <= {self.imax}')
        else:
            return argparse.ArgumentTypeError('must be an integer')


class ArgParser():
    def parse_known_args(self, args=None, namespace=None):
        # Check if configuration file exists and parse its values
        config_file_path = f'{os.path.expanduser("~")}/.ait/config.json'
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
        # NOTE: usage must be suppressed as this parser is not called directly
        self.parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, epilog='  environment variables:\n    PETALINUX_BUILD\tpath where the Petalinux project is located', prog='ait', usage=argparse.SUPPRESS)

        # Rename help title
        self.parser._optionals.title = 'Xilinx-specific arguments'

        # Vendor-specific arguments
        self.parser.add_argument('--regslice_pipeline_stages',
                                 help='number of register slice pipeline stages per SLR \
                                      \n\'x:y:z\': add between 1 and 5 stages in master:middle:slave SLRs \
                                      \nauto: let Vivado choose the number of stages \
                                      \n(def: auto)',
                                 type=PipelineStagesType(),
                                 default='auto')

        self.parser.add_argument('--interconnect_regslices',
                                 help='enable register slices on AXI interconnects',
                                 action='store_true',
                                 default=False)

        self.parser.add_argument('--interconnect_opt',
                                 help='AXI interconnect optimization strategy: Minimize \'area\' or maximize \'performance\' \
                                      \n(def: area)',
                                 choices=['area', 'performance'],
                                 metavar='OPT_STRATEGY',
                                 default=0)

        self.parser.add_argument('--interconnect_priorities',
                                 help='enable priorities in the memory interconnect',
                                 action='store_true',
                                 default=False)

        self.parser.add_argument('--power_monitor',
                                 help='enable power monitoring infrastructure',
                                 action='store_true',
                                 default=False)

        self.parser.add_argument('--thermal_monitor',
                                 help='enable thermal monitoring infrastructure',
                                 action='store_true',
                                 default=False)

        self.parser.add_argument('--ignore_eng_sample',
                                 help='ignore engineering sample status from chip part number',
                                 action='store_true',
                                 default=False)

        self.parser.add_argument('--target_language',
                                 help='choose target language to synthesize files to: vhdl or verilog \
                                      \n(def: verilog)',
                                 choices=['vhdl', 'verilog'],
                                 metavar='TARGET_LANG',
                                 default='verilog')

    def check_args(self, args):
        pass

    def check_board_args(self, args, board):
        if args.memory_interleaving_stride > 0:
            if board.arch.device == 'zynq' or board.arch.device == 'zynqmp':
                msg.error('Memory interleaving is not available on neither Zynq nor ZynqMP boards')
            elif args.memory_interleaving_stride & (args.memory_interleaving_stride - 1):
                msg.error('Memory interleaving stride must be power of 2')
            elif int(board.memory.bank_size, 0) < args.memory_interleaving_stride:
                msg.error('Max allowed interleaving stride in current board: ' + decimalToHumanReadable(int(board.memory.bank_size, 0)))

        if args.power_monitor and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Power monitoring is not available on neither Zynq nor ZynqMP boards')

        if args.thermal_monitor and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Thermal monitoring is not available on neither Zynq nor ZynqMP boards')


parser = ArgParser()
help_text = parser.parser.format_help().split('\n')[0] + '\n' + '\n'.join(parser.parser.format_help().split('\n')[2:])
