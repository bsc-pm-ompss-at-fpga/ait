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

from config import msg, ait_path, supported_boards, generation_steps, \
    available_hwruntimes, BITINFO_VERSION, MIN_WRAPPER_VERSION, VERSION_MAJOR, \
    VERSION_MINOR, VERSION_COMMIT


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
    for key in supported_boards:
        defaults[key] = dict()

        # IP cache location defaults
        defaults[key]['IP_cache_location'] = {
            'value': ait_path + '/backend/' + key + '/IP_cache',
            'used': False
        }

        defaults[key]['hwinst'] = {
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
        flow_args.add_argument('--IP_cache_location', help='path where the IP cache will be located\n(def: \'<ait>/backend/<vendor>/IP_cache/\')', action=StorePath)
        flow_args.add_argument('--to_step', help='final generation step. Generation steps by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in generation_steps.items()]) + '\n(def: \'bitstream\')', choices=[value for key, values in generation_steps.items() for value in values], metavar='TO_STEP', default='bitstream')

        # Bitstream configuration arguments
        bitstream_args = self.parser.add_argument_group('Bitstream configuration')
        bitstream_args.add_argument('-c', '--clock', help='FPGA clock frequency in MHz\n(def: \'100\')', type=int, default='100')
        bitstream_args.add_argument('--hwruntime', help='add a hardware runtime. Available hardware runtimes by vendor:\n' + '\n'.join([key + ': ' + ', '.join([value for value in values]) for key, values in available_hwruntimes.items()]) + '\n(def: som)', choices=[value for key, values in available_hwruntimes.items() for value in values], metavar='HWRUNTIME', default='som')
        bitstream_args.add_argument('--hwcounter', help='add a hardware counter to the bitstream', action='store_true', default=False)
        bitstream_args.add_argument('--interconnection_level', help='specify the desired level of interconnection between accelerators. Affects resource utilization\nbasic: accelerators are only connected to themselves and hwruntime\ntype: adds interconnection between accelerators of the same type\nfull: all accelerators are interconnected\n(def: \'basic\')', choices=['basic', 'type', 'full'], metavar='LEVEL', action=StoreChoiceValue, default=0)
        bitstream_args.add_argument('--wrapper_version', help='version of accelerator wrapper shell. This information will be placed in the bitstream information', type=int)
        bitstream_args.add_argument('--datainterfaces_map', help='path of mappings file for the data interfaces', action=StorePath)

        # User-defined files arguments
        user_args = self.parser.add_argument_group('User-defined files')
        user_args.add_argument('--user_constraints', help='path of user defined constraints file', action=StorePath)
        user_args.add_argument('--user_pre_design', help='path of user TCL script to be executed before the design step (not after the board base design)', action=StorePath)
        user_args.add_argument('--user_post_design', help='path of user TCL script to be executed after the design step', action=StorePath)

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

    def check_required_args(self, args):
        # Validate required args
        if not re.match('^[A-Za-z][A-Za-z0-9_]*$', args.name):
            msg.error('Invalid project name. Must start with a letter and contain only letters, numbers or underscores', True)

        if args.wrapper_version and args.wrapper_version < MIN_WRAPPER_VERSION:
            msg.error('Unsupported wrapper version (' + str(args.wrapper_version) + '). Minimum version is ' + str(MIN_WRAPPER_VERSION))

        if not os.path.isdir(args.dir):
            msg.error('Project directory (' + args.dir + ') does not exist or is not a folder', True)
        elif not os.path.exists(args.dir + '/' + args.name + '_ait'):
            os.mkdir(args.dir + '/' + args.name + '_ait')

    def check_flow_args(self, args):
        # Validate flow args
        if args.from_step not in generation_steps[args.backend]:
            msg.error('Initial step \'' + args.from_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly', True)

        if args.to_step not in generation_steps[args.backend]:
            msg.error('Final step \'' + args.to_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly', True)

        if generation_steps[args.backend].index(args.from_step) > generation_steps[args.backend].index(args.to_step):
            msg.error('Initial step \'' + args.from_step + '\' is posterior to the final step \'' + args.to_step + '\'. Set them correctly', True)

        if not args.disable_IP_caching and not os.path.isdir(args.IP_cache_location):
            if parser.is_default('IP_cache_location', args.backend):
                os.mkdir(args.IP_cache_location)
            else:
                msg.error('Cache location (' + args.IP_cache_location + ') does not exist or is not a folder', True)

    def is_default(self, dest, backend):
        value = False
        if self.defaults[backend][dest] is not None:
            value = self.defaults[backend][dest]['used']
        return value
