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

import glob
import importlib
import json
import os
import re
import sys
import time

from ait.frontend.config import LONG_VERSION
from ait.frontend.parser import ArgParser
from ait.frontend.utils import Logger, JSONDottedDict, ait_path, backends, msg, secondsToHumanReadable


def check_board_support(board):
    chip_part = board.chip_part + ('-' + board.es if board.es and not args.ignore_eng_sample else '')

    if args.verbose_info:
        msg.log('Checking vendor support for selected board')

    backend_utils = importlib.import_module(f'ait.backend.{args.backend}.utils')
    checker = getattr(backend_utils, 'checkers')
    checker.check_board_support(chip_part)


def get_accelerators(project_path):
    global accs

    if args.verbose_info:
        msg.log(f'Searching accelerators in folder: {os.getcwd()}')

    accs = []
    acc_types = []
    acc_names = []
    args.num_accs = 0
    args.num_instances = 0
    args.num_acc_creators = 0
    args.ompif = False

    for file_ in sorted(glob.glob(f'{os.getcwd()}/ait_*.json')):
        acc_config_json = json.load(open(file_))
        for acc_config in acc_config_json:
            acc = JSONDottedDict(acc_config_json[acc_config])

            if not re.match('^[A-Za-z][A-Za-z0-9_]*$', acc.name):
                msg.error(f"'{acc.name}' is an invalid accelerator name. Must start with a letter and contain only letters, numbers or underscores")

            msg.info(f"Found accelerator '{acc.name}'")

            args.num_accs += 1
            args.num_instances += acc.num_instances

            if acc.type in acc_types:
                msg.error(f"Two accelerators use the same type: '{acc.type}' (maybe you should use the onto clause)")
            elif acc.name in acc_names:
                msg.error(f"Two accelerators use the same name: '{acc.name}' (maybe you should change the fpga task definition)")
            acc_types.append(acc.type)
            acc_names.append(acc.name)

            # Check if the acc is a task creator
            if acc.task_creation:
                args.task_creation = True
                args.num_acc_creators += acc.num_instances
                aux = dict()
                aux[acc.name] = acc
                accs.insert(0, aux)
            else:
                aux = dict()
                aux[acc.name] = acc
                accs.append(aux)

            # Check if the acc needs instrumentation support
            if acc.instrumentation:
                args.hwinst = True

            # Check if the acc needs lock support
            if acc.lock:
                args.lock_hwruntime = True

            # Check if the acc needs dependencies
            if acc.deps:
                args.deps_hwruntime = True

            # Check if the acc needs ompif
            if acc.ompif:
                args.ompif = True

            # If the json does not have IMP field, by default set it to False
            if 'imp' not in acc_config:
                acc.imp = False

    if args.num_accs == 0:
        msg.error('No accelerators found')
    elif args.num_acc_creators == 0:
        args.disable_spawn_queues = True
        args.spawnin_queue_len = 0
        args.spawnout_queue_len = 0

    if args.ompif:
        args.num_accs += 2
        args.num_instances += 2


def main():
    global args
    global backend

    start_time = time.time()

    parser = ArgParser()
    args = parser.parse_args()

    msg.setProjectName(args.name)
    msg.setPrintTime(args.verbose_info)
    msg.setVerbose(args.verbose)

    # Dump board info json and exit
    if args.dump_board_info:
        board = json.load(open(f'{ait_path}/backend/{args.backend}/board/{args.board}/board_info.json'))
        print(json.dumps(board, indent=4))
        sys.exit(0)

    sys.stdout = Logger(args)
    msg.log(f'{LONG_VERSION}')
    msg.log(f'{os.path.basename(sys.argv[0])} {" ".join(sys.argv[1:])}')
    msg.info(f'Using {args.backend} backend')

    driver = importlib.import_module(f'ait.backend.{args.backend}.driver')
    steps, board = driver.load(args)

    project_path = os.path.normpath(os.path.realpath(f'{args.dir}/{args.name}_ait'))

    get_accelerators(project_path)

    parser.check_hardware_runtime_args(args)
    if args.deps_hwruntime:
        parser.check_picos_args(args)

    project_args = {
        'path': os.path.normpath(f'{os.path.realpath(args.dir)}/{args.name}_ait'),
        'accs': accs,
        'board': board,
        'args': args
    }

    ait_config_file = open(f'{project_path}/ait_config.json', 'w')
    ait_config_file.write(json.dumps(vars(args), indent=4))
    ait_config_file.close()

    for step in backends[args.backend]['steps']:
        if backends[args.backend]['steps'].index(args.from_step) <= backends[args.backend]['steps'].index(step) <= backends[args.backend]['steps'].index(args.to_step):
            step_func = getattr(steps, step)
            msg.info(f"Starting '{step}' step")
            step_start_time = time.time()
            project_args['start_time'] = step_start_time
            step_func.run_step(project_args)
            msg.success(f"Step '{step}' finished. {secondsToHumanReadable(int(time.time() - step_start_time))} elapsed")
        else:
            msg.warning(f"Step '{step}' is disabled")

    msg.success(f'Accelerator automatic integration finished. {secondsToHumanReadable(int(time.time() - start_time))} elapsed')


if __name__ == '__main__':
    main()
