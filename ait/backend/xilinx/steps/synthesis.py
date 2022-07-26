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

import os
import random
import subprocess
import sys

import ait.backend.xilinx.utils.checkers as checkers
from ait.frontend.utils import ait_path, msg

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def run_step(project_args):
    global args
    global board
    global chip_part
    global start_time
    global ait_backend_path
    global project_backend_path

    args = project_args['args']
    board = project_args['board']
    start_time = project_args['start_time']
    project_path = project_args['path']

    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend

    # Check if the requirements are met
    checkers.check_vivado()

    if os.path.isfile(project_backend_path + '/' + args.name + '/' + args.name + '.xpr'):
        # Enable beta device on Vivado init script
        if board.board_part:
            p = subprocess.Popen('echo "enable_beta_device ' + chip_part + '\nset_param board.repoPaths [list '
                                 + project_backend_path + '/board/' + board.name + '/board_files]" > '
                                 + project_backend_path + '/vivado.tcl', shell=True)
            retval = p.wait()
        else:
            p = subprocess.Popen('echo "enable_beta_device ' + chip_part + '" > '
                                 + project_backend_path + '/vivado.tcl', shell=True)
            retval = p.wait()

        user_id = str(hex(random.randrange(2**32)))
        msg.log('Setting bitstream user id: ' + user_id)
        p = subprocess.Popen('sed -i s/BITSTREAM_USERID/' + user_id + '/ ' + project_backend_path + '/board/' + board.name + '/constraints/basic_constraints.xdc', shell=True)
        retval = p.wait()

        p = subprocess.Popen('vivado -init -nojournal -nolog -notrace -mode batch -source '
                             + project_backend_path + '/tcl/scripts/synthesize_design.tcl',
                             cwd=project_backend_path,
                             stdout=sys.stdout.subprocess,
                             stderr=sys.stdout.subprocess, shell=True)

        if args.verbose:
            for line in iter(p.stdout.readline, b''):
                sys.stdout.write(line.decode('utf-8'))

        retval = p.wait()
        if retval:
            msg.error('Hardware synthesis failed', start_time, False)
        else:
            msg.success('Hardware synthesized')
    else:
        msg.error('No Vivado .xpr file exists for the current project. Hardware synthesis failed')
