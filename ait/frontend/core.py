#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2022 Barcelona Supercomputing Center              #
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

import glob
import importlib
import json
import os
import re
import subprocess
import sys
import time

from ait.frontend.parser import ArgParser
from ait.frontend.utils import Accelerator, ait_path, backends, msg, secondsToHumanReadable


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


def check_board_support(board):
    chip_part = board.chip_part + ('-' + board.es if board.es and not args.ignore_eng_sample else '')

    if args.verbose_info:
        msg.log('Checking vendor support for selected board')

    backend_utils = importlib.import_module('ait.backend.{}.utils'.format(args.backend))
    checker = getattr(backend_utils, 'checkers')
    checker.check_board_support(chip_part)


def get_accelerators(project_path):
    global accs

    if args.verbose_info:
        msg.log('Searching accelerators in folder: ' + os.getcwd())

    accs = []
    acc_types = []
    acc_names = []
    args.num_accs = 0
    args.num_instances = 0
    args.num_acc_creators = 0

    for file_ in sorted(glob.glob(os.getcwd() + '/ait_*.json')):
        acc_config_json = json.load(open(file_))
        for acc_config in acc_config_json:
            acc = Accelerator(acc_config)

            if not re.match('^[A-Za-z][A-Za-z0-9_]*$', acc.name):
                msg.error('\'' + acc.name + '\' is an invalid accelerator name. Must start with a letter and contain only letters, numbers or underscores')

            msg.info('Found accelerator \'' + acc.name + '\'')

            args.num_accs += 1
            args.num_instances += acc.num_instances

            if acc.type in acc_types:
                msg.error('Two accelerators use the same type: \'' + str(acc.type) + '\' (maybe you should use the onto clause)')
            elif acc.name in acc_names:
                msg.error('Two accelerators use the same name: \'' + str(acc.name) + '\' (maybe you should change the fpga task definition)')
            acc_types.append(acc.type)
            acc_names.append(acc.name)

            # Check if the acc is a task creator
            if acc.task_creation:
                args.task_creation = True
                args.num_acc_creators += acc.num_instances
                accs.insert(0, acc)
            else:
                accs.append(acc)

            # Check if the acc needs instrumentation support
            if acc.instrumentation:
                args.hwinst = True

            # Check if the acc needs lock support
            if acc.lock:
                args.lock_hwruntime = True

            # Check if the acc needs dependencies
            if acc.deps:
                args.deps_hwruntime = True

    if args.num_accs == 0:
        msg.error('No accelerators found')
    elif args.num_acc_creators == 0:
        args.disable_spawn_queues = True
        args.spawnin_queue_len = 0
        args.spawnout_queue_len = 0

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


def main():
    global args
    global backend

    start_time = time.time()

    parser = ArgParser()
    args = parser.parse_args()

    msg.setProjectName(args.name)
    msg.setPrintTime(args.verbose_info)
    msg.setVerbose(args.verbose)

    msg.info('Using ' + args.backend + ' backend')

    driver = importlib.import_module('ait.backend.{}.driver'.format(args.backend))
    steps, board = driver.load(args)

    project_path = os.path.normpath(os.path.realpath(args.dir + '/' + args.name + '_ait'))

    sys.stdout = Logger(project_path)
    sys.stdout.log.write(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:]) + '\n\n')

    get_accelerators(project_path)

    parser.check_hardware_runtime_args(args, max(2, args.num_instances))
    if args.deps_hwruntime:
        parser.check_picos_args(args)

    project_args = {
        'path': os.path.normpath(os.path.realpath(args.dir) + '/' + args.name + '_ait'),
        'accs': accs,
        'board': board,
        'args': args
    }

    for step in backends[args.backend]['steps']:
        if backends[args.backend]['steps'].index(args.from_step) <= backends[args.backend]['steps'].index(step) <= backends[args.backend]['steps'].index(args.to_step):
            step_func = getattr(steps, step)
            msg.info('Starting \'' + step + '\' step')
            step_start_time = time.time()
            project_args['start_time'] = step_start_time
            step_func.run_step(project_args)
            msg.success('Step \'' + step + '\' finished. ' + secondsToHumanReadable(int(time.time() - step_start_time)) + ' elapsed')
        else:
            msg.warning('Step \'' + step + '\' is disabled')

    msg.success('Accelerator automatic integration finished. ' + secondsToHumanReadable(int(time.time() - start_time)) + ' elapsed')


if __name__ == '__main__':
    main()
