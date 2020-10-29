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
import re
import sys
import glob
import json
import time
import importlib
import subprocess

from parser import ArgParser
from config import msg, ait_path, generation_steps, Accelerator, MIN_PYTHON_VERSION, \
    MIN_WRAPPER_VERSION

if sys.version_info < MIN_PYTHON_VERSION:
    sys.exit('Python %s.%s or later is required.\n' % MIN_PYTHON_VERSION)


class Logger(object):
    def __init__(self):
        self.terminal = sys.stdout
        self.log = open(project_vars['path'] + '/' + args.name + '.ait.log', 'w+')
        self.subprocess = subprocess.PIPE if args.verbose else self.log
        self.re_color = re.compile(r'\033\[[0,1][0-9,;]*m')

    def write(self, message):
        self.terminal.write(message)
        self.log.write(self.re_color.sub('', message))
        self.log.flush()

    def flush(self):
        pass


class JSONObject:
    def __init__(self, dict):
        vars(self).update(dict)


def check_board_support(board):
    global args

    chip_part = board.chip_part + ('-' + board.es if board.es and not args.ignore_eng_sample else '')

    if args.verbose_info:
        msg.log('Checking vendor support for selected board')

    module = importlib.import_module('check_board_support')
    step_func = getattr(module, 'check_board_support')
    step_func(chip_part)


def get_accelerators():
    global accels
    global num_accels
    global num_instances

    if args.verbose_info:
        msg.log('Searching accelerators in folder: ' + os.getcwd())

    accels = []
    accel_ids = []
    num_accels = 0
    num_instances = 0
    args.extended_hwruntime = False  # Can't be enabled if no accelerator requires it
    args.lock_hwruntime = False  # Will not be enabled if no accelerator requires it

    for file_ in sorted(glob.glob(os.getcwd() + '/*[0-9]:*[0-9]:*_hls_automatic_mcxx.cpp')):
        acc_file = os.path.basename(file_)
        acc_id = acc_file.split(':')[0]
        acc_num_instances = acc_file.split(':')[1]
        acc_file = acc_file.split(':')[2]
        acc_name = os.path.splitext(acc_file)[0]
        accel = Accelerator(acc_id, acc_name, acc_num_instances, acc_file, file_)

        if not re.match('^[A-Za-z][A-Za-z0-9_]*$', accel.short_name):
            msg.error('\'' + accel.short_name + '\' is an invalid accelerator name. Must start with a letter and contain only letters, numbers or underscores', True)

        msg.info('Found accelerator \'' + accel.short_name + '\'')

        num_accels += 1
        num_instances += accel.num_instances

        if accel.id in accel_ids:
            msg.error('Two accelerators use the same id: \'' + accel.id + '\' (maybe you should use the onto clause)')
        accel_ids.append(accel.id)

        # Check if the accel has a port called: mcxx_eInPort
        if 'ap_hs port=mcxx_eInPort' in open(file_).read():
            args.extended_hwruntime = True
            accels.insert(0, accel)
        else:
            accels.append(accel)

        # Check if the accel needs instrumentation support
        if not args.hwinst and 'ap_hs port=mcxx_instr' in open(file_).read():
            args.hwinst = True

        # Check if the accel needs lock support
        if not args.lock_hwruntime and 'nanos_set_lock' in open(file_).read():
            args.lock_hwruntime = True
            args.extended_hwruntime = True  # Lock support is only available in extended mode

    if num_accels == 0:
        msg.error('No accelerators found in this folder')

    if args.extended_hwruntime and args.hwruntime is None:
        msg.error('Some accelerator use Extended Hardware Runtime features but there is no Hardware Runtime enabled. Enable one using the --hwruntime option', True)

    if args.lock_hwruntime and args.hwruntime is None:
        msg.error('Some accelerator requires Lock support but there is no Hardware Runtime enabled. Enable one using the --hwruntime option', True)

    # Generate the .xtasks.config file
    xtasks_config_file = open(project_vars['path'] + '/' + args.name + '.xtasks.config', 'w')
    xtasks_config = 'type\t#ins\tname\t    \n'
    for accel in accels:
        xtasks_config += accel.id.zfill(19) + '\t' + str(accel.num_instances).zfill(3) + '\t' + accel.short_name.ljust(31)[:31] + '\t000\n'
    xtasks_config_file.write(xtasks_config)
    xtasks_config_file.close()


if __name__ == '__main__':
    start_time = time.time()

    args = None

    parser = ArgParser()

    args = parser.parse_args()
    msg.setProjectName(args.name)
    if args.verbose_info:
        msg.setPrintTime(True)

    project_vars = dict()

    project_vars['path'] = os.path.normpath(os.path.realpath(args.dir + '/' + args.name + '_ait'))

    msg.info('Using ' + args.backend + ' backend')

    board = json.load(open(ait_path + '/backend/' + args.backend + '/board/' + args.board + '/basic_info.json'), object_hook=JSONObject)

    if args.from_step not in generation_steps[args.backend]:
        msg.error('Initial step \'' + args.from_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly', True)

    if args.from_step not in generation_steps[args.backend]:
        msg.error('Final step \'' + args.to_step + '\' is not a valid generation step for \'' + args.backend + '\' backend. Set it correctly', True)

    if generation_steps[args.backend].index(args.from_step) > generation_steps[args.backend].index(args.to_step):
        msg.error('Initial step \'' + args.from_step + '\' is posterior to the final step \'' + args.to_step + '\'. Set them correctly', True)

    if not args.disable_IP_caching and not os.path.isdir(args.IP_cache_location):
        if parser.is_default('IP_cache_location', args.backend):
            os.mkdir(args.IP_cache_location)
        else:
            msg.error('Cache location (' + args.IP_cache_location + ') does not exist or is not a folder', True)

    if args.hwruntime is None and not args.enable_DMA:
        msg.error('You have to select at least one type of communication with the FPGA: --hwruntime or --enable_DMA', True)

    if args.enable_DMA:
        msg.info('**********************************************************************************************************\n'
                 '**********************************************************************************************************\n'
                 '           The stream backend has been deprecated and will be removed in the following releases\n'
                 '                        You will need to switch to hwruntime backend\n'
                 '                       For support contact: ompss-fpga-support@bsc.es\n'
                 '**********************************************************************************************************\n'
                 '**********************************************************************************************************\n')

    if not re.match('^[A-Za-z][A-Za-z0-9_]*$', args.name):
        msg.error('Invalid project name. Must start with a letter and contain only letters, numbers or underscores', True)

    if not int(board.frequency.min) <= args.clock <= int(board.frequency.max):
        msg.error('Clock frequency requested (' + str(args.clock) + 'MHz) is not within the board range (' + str(board.frequency.min) + '-' + str(board.frequency.max) + 'MHz)', True)

    if args.wrapper_version and args.wrapper_version < MIN_WRAPPER_VERSION:
        msg.error('Unsupported wrapper version (' + str(args.wrapper_version) + '). Minimum version is ' + str(MIN_WRAPPER_VERSION))

    if not os.path.isdir(args.dir):
        msg.error('Project directory (' + args.dir + ') does not exist or is not a folder', True)
    elif not os.path.exists(args.dir + '/' + args.name + '_ait'):
        os.mkdir(args.dir + '/' + args.name + '_ait')

    project_backend_path = os.path.normpath(project_vars['path'] + '/' + args.backend)

    # Add backend to python import path
    sys.path.insert(0, ait_path + '/backend/' + args.backend + '/scripts')

    # Check for backend support for the given board
    if not args.disable_board_support_check:
        check_board_support(board)

    sys.stdout = Logger()
    sys.stdout.log.write(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:]) + '\n\n')

    get_accelerators()

    project_args = {
        'path': os.path.normpath(os.path.realpath(args.dir) + '/' + args.name + '_ait'),
        'num_accels': num_accels,
        'num_instances': num_instances,
        'accels': accels,
        'board': board,
        'args': args
    }

    for step in generation_steps[args.backend]:
        if generation_steps[args.backend].index(args.from_step) <= generation_steps[args.backend].index(step) <= generation_steps[args.backend].index(args.to_step):
            generation_step_package = os.path.basename(os.path.dirname(glob.glob(ait_path + '/backend/' + args.backend + '/scripts/*-' + step + '/')[0]))
            generation_step_module = '%s.%s' % (generation_step_package, step)
            module = importlib.import_module(generation_step_module)
            step_func = getattr(module, 'STEP_FUNC')
            msg.info('Starting \'' + step + '\' step')
            step_start_time = time.time()
            step_func(project_args)
            msg.success('Step \'' + step + '\' finished. ' + str(int(time.time() - step_start_time)) + 's elapsed')
        else:
            msg.warning('Step \'' + step + '\' is disabled')

    msg.success('Hardware automatic generation finished. ' + str(int(time.time() - start_time)) + 's elapsed')
