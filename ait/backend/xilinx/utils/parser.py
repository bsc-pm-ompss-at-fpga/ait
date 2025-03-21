#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2024 Barcelona Supercomputing Center              #
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
import math
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
            return argparse.ArgumentTypeError('must be an integer in the range [{}, {}]'.format(self.imin, self.imax))
        elif self.imin is not None:
            return argparse.ArgumentTypeError('must be an integer >= {}'.format(self.imin))
        elif self.imax is not None:
            return argparse.ArgumentTypeError('must be an integer <= {}'.format(self.imax))
        else:
            return argparse.ArgumentTypeError('must be an integer')


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
        # NOTE: usage must be suppressed as this parser is not called directly
        self.parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, epilog='  environment variables:\n    PETALINUX_BUILD\tpath where the Petalinux project is located', prog='ait', usage=argparse.SUPPRESS)

        # Rename help title
        self.parser._optionals.title = 'Xilinx-specific arguments'

        # Vendor-specific arguments
        self.parser.add_argument('--floorplanning_constr', help='built-in floorplanning constraints for accelerators and static logic\nacc: accelerator kernels are constrained to a SLR region\nstatic: each static logic IP is constrained to its relevant SLR\nall: enables both \'acc\' and \'static\' options\nBy default no floorplanning constraints are used', choices=['acc', 'static', 'all'], metavar='FLOORPLANNING_CONSTR')
        self.parser.add_argument('--placement_file', help='json file specifying accelerator placement', type=FileType())
        self.parser.add_argument('--slr_slices', help='enable SLR crossing register slices\nacc: create register slices for SLR crossing on accelerator-related interfaces\nstatic: create register slices for static logic IPs\nall: enable both \'acc\' and \'static\' options \nBy default they are disabled', choices=['acc', 'static', 'all'], metavar='SLR_SLICES')
        self.parser.add_argument('--regslice_pipeline_stages', help='number of register slice pipeline stages per SLR\n\'x:y:z\': add between 1 and 5 stages in master:middle:slave SLRs\nauto: let Vivado choose the number of stages\n(def: auto)', type=PipelineStagesType(), default='auto')
        self.parser.add_argument('--interconnect_regslice', help='enable register slices on AXI interconnects\nall: enables them on all interconnects\nmem: enables them on interconnects in memory datapath\nhwruntime: enables them on the AXI-stream interconnects between the hwruntime and the accelerators\n', nargs='+', choices=['mem', 'hwruntime', 'all'], metavar='INTER_REGSLICE_LIST')
        self.parser.add_argument('--interconnect_opt', help='AXI interconnect optimization strategy: Minimize \'area\' or maximize \'performance\'\n(def: \'area\')', choices=['area', 'performance'], metavar='OPT_STRATEGY', action=StoreChoiceValue, default=0)
        self.parser.add_argument('--interconnect_priorities', help='enable priorities in the memory interconnect', action='store_true', default=False)
        self.parser.add_argument('--simplify_interconnection', help='simplify interconnection between accelerators and memory. Might negatively impact timing', action='store_true', default=False)
        self.parser.add_argument('--power_monitor', help='enable power monitoring infrastructure', action='store_true', default=False)
        self.parser.add_argument('--thermal_monitor', help='enable thermal monitoring infrastructure', action='store_true', default=False)
        self.parser.add_argument('--debug_intfs', help='choose which interfaces mark for debug and instantiate the correspondent ILA cores\nAXI: debug accelerator\'s AXI interfaces\nstream: debug accelerator\'s AXI-Stream interfaces\nboth: debug both accelerator\'s AXI and AXI-Stream interfaces\ncustom: debug user-defined interfaces\nnone: do not mark for debug any interface\n(def: \'none\')', choices=['AXI', 'stream', 'both', 'custom', 'none'], metavar='INTF_TYPE', default='none')
        self.parser.add_argument('--debug_intfs_list', help='path of file with the list of interfaces to debug', type=FileType())
        self.parser.add_argument('--ignore_eng_sample', help='ignore engineering sample status from chip part number', action='store_true', default=False)
        self.parser.add_argument('--target_language', help='choose target language to synthesize files to: vhdl or verilog\n(def: \'verilog\')', choices=['vhdl', 'verilog'], metavar='TARGET_LANG', default='verilog')

    def check_args(self, args):
        if args.debug_intfs == 'custom' and args.debug_intfs_list is None:
            msg.error('A file specifying which interfaces to mark for debug is required when choosing \'custom\' value on --debug_intfs argument')

        if args.interconnect_regslice is not None:
            for opt in args.interconnect_regslice:
                if opt == 'all' and len(args.interconnect_regslice) != 1:
                    msg.error('Invalid combination of values for --interconnect_regslice')

        if (args.slr_slices == 'acc' or args.slr_slices == 'all') and args.placement_file is None:
            msg.error('--placement_file argument required when enabling SLR-crossing register slices on accelerators')
        elif (args.floorplanning_constr == 'acc' or args.floorplanning_constr == 'all') and args.placement_file is None:
            msg.error('--placement_file argument required when setting floorplanning constraints on accelerators')

    def check_board_args(self, args, board):
        if args.memory_interleaving_stride is not None:
            if board.arch.device == 'zynq' or board.arch.device == 'zynqmp':
                msg.error('Memory interleaving is not available on neither Zynq nor ZynqMP boards')
            elif args.memory_interleaving_stride & (args.memory_interleaving_stride - 1):
                msg.error('Memory interleaving stride must be power of 2')
            elif math.log2(int(board.memory.bank_size, 0)) - math.log2(args.memory_interleaving_stride) < math.ceil(math.log2(board.memory.num_banks)):
                msg.error('Max allowed interleaving stride in current board: ' + decimalToHumanReadable(2**(math.log2(int((board.memory.bank_size, 0))) - math.ceil(math.log2(board.memory.num_banks))), 2))

        if args.datainterfaces_map and (board.arch.device == 'alveo' and board.memory.type == 'ddr'):
            msg.error('Custom data interface mapping is not available for DDR-based Alveo boards')

        if args.interconnect_priorities and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Memory interconnect priorities are not available on neither Zynq nor ZynqMP boards')
        elif args.interconnect_priorities and board.memory.type != 'ddr':
            msg.error('Memory interconnect priorities are only available for DDR memories')

        if args.simplify_interconnection and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Simplify memory interconnection is not available on neither Zynq nor ZynqMP boards')
        elif args.simplify_interconnection and board.memory.type != 'ddr':
            msg.error('Simplify memory interconnection is only available for DDR memories')

        if (args.slr_slices is not None or args.floorplanning_constr is not None) and 'slr' not in board.arch:
            msg.error('Use of placement constraints is only available for boards with SLRs')

        if args.power_monitor and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Power monitoring is not available on neither Zynq nor ZynqMP boards')

        if args.thermal_monitor and (board.arch.device == 'zynq' or board.arch.device == 'zynqmp'):
            msg.error('Thermal monitoring is not available on neither Zynq nor ZynqMP boards')


parser = ArgParser()
help_text = parser.parser.format_help().split('\n')[0] + '\n' + '\n'.join(parser.parser.format_help().split('\n')[2:])
