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
import re
import sys
import json
import argparse
import importlib
from math import log2
from math import ceil

from frontend.config import msg, ait_path, supported_boards, generation_steps, \
    available_hwruntimes, utils, BITINFO_VERSION, MIN_WRAPPER_VERSION, \
    VERSION_MAJOR, VERSION_MINOR, VERSION_COMMIT


# Custom argparse type representing a power of 2 int
class IntPower:
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
        elif value & (value - 1):
            raise self.exception(value)
        return value

    def exception(self, value=None):
        if value is not None and (value & (value - 1)):
            return argparse.ArgumentTypeError('must be power of 2')
        elif self.imin is not None and self.imax is not None:
            return argparse.ArgumentTypeError('must be an integer power of 2 in the range [{}, {}]'.format(self.imin, self.imax))
        elif self.imin is not None:
            return argparse.ArgumentTypeError('must be an integer power of 2 >= {}'.format(self.imin))
        elif self.imax is not None:
            return argparse.ArgumentTypeError('must be an integer power of 2 <= {}'.format(self.imax))
        else:
            return argparse.ArgumentTypeError('must be an integer power of 2')


# Custom argparse type representing a bounded int
class IntRange:
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


class StoreHumanReadable(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, utils.decimalFromHumanReadable(values))


class StorePath(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, os.path.realpath(values))


class StoreChoiceValue(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, self.choices.index(values))


class ChangedArg(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        msg.warning('Argument ' + '/'.join(self.option_strings) + ' has changed. Check `ait -h` and fix your program call')


class RemovedArg(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        msg.info('Argument ' + '/'.join(self.option_strings) + ' is no longer used. Please remove it from the program call')


class CustomParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('usage: ait -b BOARD -n NAME\nait error: %s\n' % message)
        sys.exit(2)


class ArgParser:
    defaults = dict()
    for backend in supported_boards:
        defaults[backend] = dict()

        # IP cache location defaults
        defaults[backend]['IP_cache_location'] = {
            'value': '/var/tmp/ait/' + backend + '/IP_cache',
            'used': False
        }

        defaults[backend]['hwinst'] = {
            'value': False,
            'used': False
        }

    def __init__(self):
        # Load vendor-specific parsers
        self.vendor_parser = dict()
        for backend in supported_boards:
            if os.path.exists(ait_path + '/backend/' + backend + '/scripts/vendor_parser.pyc'):
                sys.path.insert(0, ait_path + '/backend/' + backend + '/scripts')
                module = importlib.import_module('vendor_parser')
                self.vendor_parser[backend] = getattr(module, 'parser')

        # Create main parser
        self.parser = CustomParser(formatter_class=argparse.RawTextHelpFormatter, epilog='\n'.join(self.vendor_parser[backend].parser.format_help().split('\n')[0] + '\n' + '\n'.join(self.vendor_parser[backend].parser.format_help().split('\n')[2:]) for backend in self.vendor_parser), prog='ait', add_help=False, usage='%(prog)s -b BOARD -n NAME\nThe Accelerator Integration Tool (AIT) automatically integrates OmpSs@FPGA accelerators into FPGA designs using different vendor backends.')

        # Required arguments
        required_args = self.parser.add_argument_group('Required')
        required_args.add_argument('-b', '--board', help='board model. Supported boards by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in supported_boards.items()]), choices=[value for key, values in supported_boards.items() for value in values], metavar='BOARD', type=str.lower, required=True)
        required_args.add_argument('-n', '--name', help='project name', metavar='NAME', required=True)

        # Generation flow arguments
        flow_args = self.parser.add_argument_group('Generation flow')
        flow_args.add_argument('-d', '--dir', help='path where the project directory tree will be created\n(def: \'./\')', action=StorePath, default='./')
        flow_args.add_argument('--disable_IP_caching', help='disable IP caching. Significantly increases generation time', action='store_true', default=False)
        flow_args.add_argument('--disable_utilization_check', help='disable resources utilization check during HLS generation', action='store_true', default=False)
        flow_args.add_argument('--disable_board_support_check', help='disable board support check', action='store_true', default=False)
        flow_args.add_argument('--from_step', help='initial generation step. Generation steps by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in generation_steps.items()]) + '\n(def: \'HLS\')', choices=[value for key, values in generation_steps.items() for value in values], metavar='FROM_STEP', default='HLS')
        flow_args.add_argument('--IP_cache_location', help='path where the IP cache will be located\n(def: \'/var/tmp/ait/<vendor>/IP_cache/\')', action=StorePath)
        flow_args.add_argument('--to_step', help='final generation step. Generation steps by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in generation_steps.items()]) + '\n(def: \'bitstream\')', choices=[value for key, values in generation_steps.items() for value in values], metavar='TO_STEP', default='bitstream')

        # Bitstream configuration arguments
        bitstream_args = self.parser.add_argument_group('Bitstream configuration')
        bitstream_args.add_argument('-c', '--clock', help='FPGA clock frequency in MHz\n(def: \'100\')', type=int, default='100')
        bitstream_args.add_argument('--hwruntime', help='add a hardware runtime. Available hardware runtimes by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in available_hwruntimes.items()]) + '\n(def: som)', choices=[value for key, values in available_hwruntimes.items() for value in values], metavar='HWRUNTIME', default='som')
        bitstream_args.add_argument('--hwcounter', help='add a hardware counter to the bitstream', action='store_true', default=False)
        bitstream_args.add_argument('--wrapper_version', help='version of accelerator wrapper shell. This information will be placed in the bitstream information', type=int)
        bitstream_args.add_argument('--datainterfaces_map', help='path of mappings file for the data interfaces', action=StorePath)
        bitstream_args.add_argument('--placement_file', help='json file specifying accelerator placement', action=StorePath)
        bitstream_args.add_argument('--floorplanning_constr', help='built-in floorplanning constraints for accelerators and static logic\nacc: accelerator kernels are constrained to a SLR region\nstatic: each static logic IP is constrained to its relevant SLR\nall: enables both \'acc\' and \'static\' options\nBy default no floorplanning constraints are used', choices=['acc', 'static', 'all'], metavar='FLOORPLANNING_CONSTR')
        bitstream_args.add_argument('--slr_slices', help='enable SLR crossing register slices\nacc: create register slices for SLR crossing on accelerator-related interfaces\nstatic: create register slices for static logic IPs\nall: enable both \'acc\' and \'static\' options \nBy default they are disabled', choices=['acc', 'static', 'all'], metavar='SLR_SLICES')
        bitstream_args.add_argument('--memory_interleaving_stride', help='size in bytes of the stride of the memory interleaving. By default there is no interleaving', metavar='MEM_INTERLEAVING_STRIDE', action=StoreHumanReadable)

        # User-defined files arguments
        user_args = self.parser.add_argument_group('User-defined files')
        user_args.add_argument('--user_constraints', help='path of user defined constraints file', action=StorePath)
        user_args.add_argument('--user_pre_design', help='path of user TCL script to be executed before the design step (not after the board base design)', action=StorePath)
        user_args.add_argument('--user_post_design', help='path of user TCL script to be executed after the design step', action=StorePath)

        # Hardware Runtime arguments
        hwruntime_args = self.parser.add_argument_group('Hardware Runtime')
        hwruntime_args.add_argument('--cmdin_queue_len', help='maximum length (64-bit words) of the queue for the hwruntime command in\nThis argument is mutually exclusive with --cmdin_subqueue_len', type=IntRange(4))
        hwruntime_args.add_argument('--cmdin_subqueue_len', help='length (64-bit words) of each accelerator subqueue for the hwruntime command in.\nThis argument is mutually exclusive with --cmdin_queue_len\nMust be power of 2\nDef. max(64, 1024/num_accs)', type=IntPower(4))
        hwruntime_args.add_argument('--cmdout_queue_len', help='maximum length (64-bit words) of the queue for the hwruntime command out\nThis argument is mutually exclusive with --cmdout_subqueue_len', type=IntRange(2))
        hwruntime_args.add_argument('--cmdout_subqueue_len', help='length (64-bit words) of each accelerator subqueue for the hwruntime command out. This argument is mutually exclusive with --cmdout_queue_len\nMust be power of 2\nDef. max(64, 1024/num_accs)', type=IntPower(2))
        hwruntime_args.add_argument('--spawnin_queue_len', help='length (64-bit words) of the hwruntime spawn in queue. Must be power of 2\n(def: \'1024\')', type=IntPower(4), default=1024)
        hwruntime_args.add_argument('--spawnout_queue_len', help='length (64-bit words) of the hwruntime spawn out queue. Must be power of 2\n(def: \'1024\')', type=IntPower(4), default=1024)
        hwruntime_args.add_argument('--hwruntime_interconnect', help='type of hardware runtime interconnection with accelerators\ncentralized\ndistributed\n(def: \'centralized\')', choices=['centralized', 'distributed'], metavar='HWR_INTERCONNECT', default='centralized')  # TODO: Explain what does each option do

        # Picos arguments
        picos_args = self.parser.add_argument_group('Picos')
        picos_args.add_argument('--picos_max_args_per_task', help='maximum number of arguments for any task in the bitstream\n(def: \'15\')', type=IntRange(1), default=15)
        picos_args.add_argument('--picos_max_deps_per_task', help='maximum number of dependencies for any task in the bitstream\n(def: \'8\')', type=IntRange(2), default=8)
        picos_args.add_argument('--picos_max_copies_per_task', help='maximum number of copies for any task in the bitstream\n(def: \'15\')', type=IntRange(1), default=15)
        picos_args.add_argument('--picos_num_dcts', help='number of DCTs instantiated\n(def: \'1\')', choices=['1', '2', '4'], metavar='NUM_DCTS', default=1)
        picos_args.add_argument('--picos_tm_size', help='size of the TM memory\n(def: \'128\')', type=IntRange(2), default=128)
        picos_args.add_argument('--picos_dm_size', help='size of the DM memory\n(def: \'512\')', type=IntRange(2), default=512)
        picos_args.add_argument('--picos_vm_size', help='size of the VM memory\n(def: \'512\')', type=IntRange(2), default=512)
        picos_args.add_argument('--picos_dm_ds', help='data structure of the DM memory\nBINTREE: Binary search tree (not autobalanced)\nLINKEDLIST: Linked list\n(def: \'BINTREE\')', choices=['BINTREE', 'LINKEDLIST'], metavar='DATA_STRUCT', default='BINTREE')
        picos_args.add_argument('--picos_dm_hash', help='hashing function applied to dependence addresses\nP_PEARSON: Parallel Pearson function\nXOR\n(def: \'P_PEARSON\')', choices=['P_PEARSON', 'XOR'], metavar='HASH_FUN', default='P_PEARSON')  # TODO: Explain what XOR does
        picos_args.add_argument('--picos_hash_t_size', help='DCT hash table size\n(def: \'64\')', type=IntRange(2), default=64)

        # Miscellaneous arguments
        misc_args = self.parser.add_argument_group('Miscellaneous')
        misc_args.add_argument('-h', '--help', action='help', help='show this help message and exit')
        misc_args.add_argument('-i', '--verbose_info', help='print extra information messages', action='store_true', default=False)
        misc_args.add_argument('-k', '--keep_files', help='keep files on error', action='store_true', default=False)
        misc_args.add_argument('-v', '--verbose', help='print vendor backend messages', action='store_true', default=False)
        misc_args.add_argument('--version', help='print AIT version and exits', action='version', version=str('.'.join([str(VERSION_MAJOR), str(VERSION_MINOR)]) + ' (commit: ' + VERSION_COMMIT + ', bitInfo: ' + str(BITINFO_VERSION) + ')'))

    def parse_args(self):
        # Check if configuration file exists and parse its values
        config_file_path = os.path.expanduser('~') + '/.ait/config.json'
        if os.path.exists(config_file_path):
            with open(config_file_path) as config_file:
                try:
                    config = json.load(config_file)
                    self.parser.set_defaults(**config)
                except ValueError as err:
                    print('Invalid configuration file (' + config_file_path + '). ' + str(err))
                    print('================')
                    config_file.seek(0)
                    print(config_file.read())
                    print('================')
                    sys.exit(1)

        # Parse values from argv
        args, extras = self.parser.parse_known_args()

        # Get vendor backend and parse vendor-specific arguments
        args_vars = vars(args)
        args_vars['backend'] = [key for key, values in supported_boards.items() if args.board in values][0]
        if (args.backend in self.vendor_parser):
            args, extras = self.vendor_parser[args.backend].parse_known_args(extras, namespace=args)
        if len(extras):
            self.parser.error('unrecognized arguments: ' + ','.join(extras) + '. Try \'ait -h\' for more information.')

        # Set default values for non-provided options
        for arg in self.defaults[args_vars['backend']]:
            if arg not in args_vars or args_vars[arg] is None:
                args_vars[arg] = self.defaults[args_vars['backend']][arg]['value']
                self.defaults[args_vars['backend']][arg]['used'] = True

        self.check_args(args)

        return args

    def check_args(self, args):
        # Validate arguments
        self.check_required_args(args)
        self.check_flow_args(args)
        self.check_bitstream_args(args)
        if args.hwruntime == "pom":
            self.check_picos_args(args)

    def check_required_args(self, args):
        # Validate required args
        if not re.match('^[A-Za-z][A-Za-z0-9_]*$', args.name):
            msg.error('Invalid project name. Must start with a letter and contain only letters, numbers or underscores')

        if args.wrapper_version and args.wrapper_version < MIN_WRAPPER_VERSION:
            msg.error('Unsupported wrapper version (' + str(args.wrapper_version) + '). Minimum version is ' + str(MIN_WRAPPER_VERSION))

        if not os.path.isdir(args.dir):
            msg.error('Project directory (' + args.dir + ') does not exist or is not a folder')
        elif not os.path.exists(args.dir + '/' + args.name + '_ait'):
            os.mkdir(args.dir + '/' + args.name + '_ait')

    def check_flow_args(self, args):
        # Validate flow args
        if args.from_step not in generation_steps[args.backend]:
            msg.error('Initial step \'' + args.from_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly')

        if args.to_step not in generation_steps[args.backend]:
            msg.error('Final step \'' + args.to_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly')

        if generation_steps[args.backend].index(args.from_step) > generation_steps[args.backend].index(args.to_step):
            msg.error('Initial step \'' + args.from_step + '\' is posterior to the final step \'' + args.to_step + '\'. Set them correctly')

        if not args.disable_IP_caching and not os.path.isdir(args.IP_cache_location):
            if self.is_default('IP_cache_location', args.backend):
                # Create cache folder and set perms to allow all users writing there
                os.makedirs(args.IP_cache_location)
                os.chmod(args.IP_cache_location, 0o777)
            else:
                msg.error('Cache location (' + args.IP_cache_location + ') does not exist or is not a folder')

    def check_bitstream_args(self, args):
        # Validate bitstream args
        if (args.slr_slices == 'acc' or args.slr_slices == 'all') and args.placement_file is None:
            msg.error('--placement_file argument required when enabling SLR-crossing register slices on accelerators')
        elif (args.floorplanning_constr == 'acc' or args.floorplanning_constr == 'all') and args.placement_file is None:
            msg.error('--placement_file argument required when setting floorplanning constraints on accelerators')

    # This check has to be delayed because arguments are parsed before the number of accelerators is calculated
    def check_hardware_runtime_args(self, args, num_accs):

        def prev_power_of_2(num):
            if num & (num - 1) != 0:
                num = int(log2(num))
                num = int(pow(2, num))
            return num

        if args.cmdin_subqueue_len is not None and args.cmdin_queue_len is not None:
            msg.error('--cmdin_subqueue_len and --cmdin_queue_len are mutually exclusive')
        if args.cmdout_subqueue_len is not None and args.cmdout_queue_len is not None:
            msg.error('--cmdout_subqueue_len and --cmdout_queue_len are mutually exclusive')

        if args.cmdin_queue_len is not None:
            args.cmdin_subqueue_len = prev_power_of_2(int(args.cmdin_queue_len / num_accs))
            msg.info('Setting --cmdin_subqueue_len to {}'.format(args.cmdin_subqueue_len))
        elif args.cmdin_subqueue_len is None:
            args.cmdin_subqueue_len = max(64, prev_power_of_2(int(1024 / num_accs)))
        if args.cmdout_queue_len is not None:
            args.cmdout_subqueue_len = prev_power_of_2(int(args.cmdout_queue_len / num_accs))
            msg.info('Setting --cmdout_subqueue_len to {}'.format(args.cmdout_subqueue_len))
        elif args.cmdout_subqueue_len is None:
            args.cmdout_subqueue_len = max(64, prev_power_of_2(int(1024 / num_accs)))

        # The subqueue length has to be checked here in the case the user provides the cmdin queue length
        if args.cmdin_subqueue_len < 34:
            msg.warning('Value of --cmdin_subqueue_len={} is less than 34, which is the length of the longest command possible. This design might not work with tasks with enough arguments.'.format(args.cmdin_subqueue_len))
        if args.spawnout_queue_len < 79:
            msg.warning('Value of --spawnout_queue_len={} is less than 79, which is the length of the longest task possible. This design might not work if an accelerator creates SMP tasks with enough copies, dependencies and/or arguments.'.format(args.spawnout_queue_len))

    def check_picos_args(self, args):
        # Validate Picos args
        if (args.picos_dm_hash == 'P_PEARSON' and args.picos_hash_t_size != 64):
            msg.error('With P_PEARSON hash function, --picos_hash_t_size must be 64')
        if (args.picos_hash_t_size > args.picos_dm_size):
            msg.error('Invalid --picos_hash_t_size, maximum value is --picos_dm_size')
        if (ceil(log2(args.picos_hash_t_size)) + ceil(log2(args.picos_num_dcts)) > 8):
            msg.error('Invalid combination of --picos_hash_t_size and --picos_num_dcts, ceil(log2(args.picos_hash_t_size))+ceil(log2(args.picos_num_dcts)) <= 8')

    def is_default(self, dest, backend):
        value = False
        if self.defaults[backend][dest] is not None:
            value = self.defaults[backend][dest]['used']
        return value
