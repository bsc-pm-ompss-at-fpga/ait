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
import glob
import math
import json
import time
import importlib
import subprocess

from frontend.parser import ArgParser
from frontend.config import msg, ait_path, generation_steps, Accelerator, utils, MIN_PYTHON_VERSION

if sys.version_info < MIN_PYTHON_VERSION:
    sys.exit('Python %s.%s or later is required.\n' % MIN_PYTHON_VERSION)


class Logger(object):
    def __init__(self, project_path):
        self.terminal = sys.stdout
        self.log = open(project_path + '/' + args.name + '.ait.log', 'w+')
        self.subprocess = subprocess.PIPE if args.verbose else self.log
        self.re_color = re.compile(r'\033\[[0,1][0-9,;]*m')
        self.tag = '[AIT] ' if not args.verbose else ''

    def write(self, message):
        self.terminal.write(message)
        if message != '\n':
            self.log.write(self.tag)
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


def get_accelerators(project_path):
    global accs
    global num_accs
    global num_instances
    global num_acc_creators

    if args.verbose_info:
        msg.log('Searching accelerators in folder: ' + os.getcwd())

    accs = []
    acc_types = []
    num_accs = 0
    num_instances = 0
    num_acc_creators = 0
    args.extended_hwruntime = False  # Can't be enabled if no accelerator requires it
    args.lock_hwruntime = False  # Will not be enabled if no accelerator requires it

    for file_ in sorted(glob.glob(os.getcwd() + '/ait_*.json')):
        acc_config_json = json.load(open(file_))
        for acc_config in acc_config_json:
            acc = Accelerator(acc_config)

            if not re.match('^[A-Za-z][A-Za-z0-9_]*$', acc.name):
                msg.error('\'' + acc.name + '\' is an invalid accelerator name. Must start with a letter and contain only letters, numbers or underscores')

            msg.info('Found accelerator \'' + acc.name + '\'')

            num_accs += 1
            num_instances += acc.num_instances

            if acc.type in acc_types:
                msg.error('Two accelerators use the same type: \'' + str(acc.type) + '\' (maybe you should use the onto clause)')
            acc_types.append(acc.type)

            # Check if the acc is a task creator
            if acc.task_creation:
                args.extended_hwruntime = True
                num_acc_creators += acc.num_instances
                accs.insert(0, acc)
            else:
                accs.append(acc)

            # Check if the acc needs instrumentation support
            if acc.instrumentation:
                args.hwinst = True

            # Check if the acc needs lock support
            if acc.lock:
                args.lock_hwruntime = True

    if num_accs == 0:
        msg.error('No accelerators found')

    # Generate the .xtasks.config file
    xtasks_config_file = open(project_path + '/' + args.name + '.xtasks.config', 'w')
    xtasks_config = 'type\t#ins\tname\t    \n'
    for acc in accs:
        xtasks_config += str(acc.type).zfill(19) + '\t' + str(acc.num_instances).zfill(3) + '\t' + acc.name.ljust(31)[:31] + '\t000\n'
    xtasks_config_file.write(xtasks_config)
    xtasks_config_file.close()

    if args.hwinst:
        hwinst_acc_json_string = json.dumps({'full_path': ait_path + '/backend/' + args.backend + '/HLS/src/Adapter_instr.cpp', 'filename': 'Adapter_instr.cpp', 'name': 'Adapter_instr', 'type': 0, 'num_instances': 1, 'task_creation': 'false', 'instrumentation': 'false', 'periodic': 'false', 'lock': 'false'}, indent=4)
        hwinst_acc_json = json.loads(hwinst_acc_json_string)
        hwinst_acc = Accelerator(hwinst_acc_json)
        accs.append(hwinst_acc)


def ait_main():
    global args

    start_time = time.time()

    args = None

    parser = ArgParser()

    args = parser.parse_args()
    msg.setProjectName(args.name)
    msg.setPrintTime(args.verbose_info)
    msg.setVerbose(args.verbose)

    msg.info('Using ' + args.backend + ' backend')

    board = json.load(open(ait_path + '/backend/' + args.backend + '/board/' + args.board + '/basic_info.json'), object_hook=JSONObject)

    if not int(board.frequency.min) <= args.clock <= int(board.frequency.max):
        msg.error('Clock frequency requested (' + str(args.clock) + 'MHz) is not within the board range (' + str(board.frequency.min) + '-' + str(board.frequency.max) + 'MHz)')

    if args.memory_interleaving_stride is not None:
        if board.arch.type == 'soc':
            msg.error('Memory interleaving is only available for non-SoC boards')
        elif math.log2(utils.decimalFromHumanReadable(board.ddr.bank_size)) - math.log2(utils.decimalFromHumanReadable(args.memory_interleaving_stride)) < math.ceil(math.log2(board.ddr.num_banks)):
            msg.error('Max allowed interleaving stride in current board: ' + utils.decimalToHumanReadable(2**(math.log2(utils.decimalFromHumanReadable(board.ddr.bank_size)) - math.ceil(math.log2(board.ddr.num_banks))), 2))

    if args.simplify_interconnection and board.arch.type == 'soc':
        msg.error('Simplify DDR interconnection is only available for non-SoC boards')

    if (args.slr_slices is not None or args.floorplanning_constr is not None) and not hasattr(board.arch, 'slr'):
        msg.error('Use of placement constraints is only available for boards with SLRs')

    project_path = os.path.normpath(os.path.realpath(args.dir + '/' + args.name + '_ait'))
    project_backend_path = os.path.normpath(project_path + '/' + args.backend)

    # Add backend to python import path
    sys.path.insert(0, ait_path + '/backend/' + args.backend + '/scripts')

    # Check for backend support for the given board
    if not args.disable_board_support_check:
        check_board_support(board)

    sys.stdout = Logger(project_path)
    sys.stdout.log.write(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:]) + '\n\n')

    get_accelerators(project_path)

    parser.check_hardware_runtime_args(args, max(2, num_instances))

    project_args = {
        'path': os.path.normpath(os.path.realpath(args.dir) + '/' + args.name + '_ait'),
        'num_accs': num_accs,
        'num_instances': num_instances,
        'num_acc_creators': num_acc_creators,
        'accs': accs,
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

    msg.success('Accelerator automatic integration finished. ' + str(int(time.time() - start_time)) + 's elapsed')


if __name__ == '__main__':
    ait()
