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
import os
import shutil
import subprocess
import sys

import ait.backend.xilinx.utils as utils
from ait.frontend.utils import ait_path, getNumJobs, msg

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))
STEP_NAME = 'bitstream'


def run_step(project_args):
    global args
    global board
    global start_time
    global ait_backend_path
    global project_backend_path

    args = project_args['args']
    board = project_args['board']
    start_time = project_args['start_time']
    project_path = project_args['path']

    ait_backend_path = f'{ait_path}/backend/{args.backend}'
    project_backend_path = f'{project_path}/{args.backend}'
    project_products_path = f'{project_path}/products'

    # Check if Vivado requirements are met
    utils.check_vivado()

    # Remove directories and files deprecated by the current step
    utils.cleanup_step_files(project_args, STEP_NAME)

    # Create directories and move files required by the current step
    utils.prepare_step_files(project_args, STEP_NAME)

    if os.path.isfile(f'{project_backend_path}/{args.name}/{args.name}.xpr'):
        p = subprocess.Popen('vivado -init -nojournal -nolog -notrace -mode batch '
                             + f'-source {project_backend_path}/tcl/ait.tcl '
                             + f'-source {project_backend_path}/tcl/scripts/generate_bitstream.tcl '
                             + '-tclargs ' + (str(args.jobs) if args.jobs is not None else str(getNumJobs(args.mem_per_job))),
                             cwd=project_backend_path,
                             stdout=sys.stdout.subprocess,
                             stderr=sys.stdout.subprocess, shell=True)

        if args.verbose:
            for line in iter(p.stdout.readline, b''):
                sys.stdout.write(line.decode('utf-8'))

        retval = p.wait()
        if retval:
            msg.error('Bitstream generation failed', start_time, False)
        else:
            os.makedirs(project_products_path, exist_ok=True)

            shutil.copy2(glob.glob(f'{project_backend_path}/{args.name}/'
                         + f'{args.name}.runs/impl_1/{args.name}*.bit')[0],
                         f'{project_products_path}/{args.name}.bit')

            if board.arch.device == 'zynq' and utils.check_bootgen():
                bif_file = open(f'{project_backend_path}/{args.name}/{args.name}.runs/impl_1/bitstream.bif', 'w')
                bif_file.write('all:\n'
                               + '{\n'
                               + f'\t{args.name}_design_wrapper.bit\n'
                               + '}')
                bif_file.close()
                p = subprocess.Popen('bootgen -image bitstream.bif -arch zynq -process_bitstream bin -w',
                                     cwd=f'{project_backend_path}/{args.name}/{args.name}.runs/impl_1',
                                     stdout=sys.stdout.subprocess,
                                     stderr=sys.stdout.subprocess, shell=True)

                if args.verbose:
                    for line in iter(p.stdout.readline, b''):
                        sys.stdout.write(line.decode('utf-8'))

                retval = p.wait()
                if retval:
                    msg.warning('Could not create .bit.bin file')
                else:
                    shutil.copy2(glob.glob(f'{project_backend_path}/{args.name}/'
                                 + f'{args.name}.runs/impl_1/{args.name}*.bit.bin')[0],
                                 f'{project_products_path}/{args.name}.bit.bin')

            if board.arch.device == 'zynq' or board.arch.device == 'zynqmp':
                os.makedirs(f'{project_products_path}/boot')
                if os.path.exists(f'{ait_backend_path}/board/{board.name}/boot'):
                    shutil.copytree(f'{ait_backend_path}/board/{board.name}/boot', f'{project_products_path}/boot', dirs_exist_ok=True)
                shutil.copy2(glob.glob(f'{project_backend_path}/{args.name}/'
                             + f'{args.name}.sdk/{args.name}*.xsa')[0],
                             f'{project_products_path}/boot/{args.name}.xsa')

                shutil.copy2(glob.glob(f'{project_backend_path}/{args.name}/'
                             + f'{args.name}.runs/impl_1/{args.name}*.bin')[0],
                             f'{project_products_path}/{args.name}.bin')

            msg.success('Bitstream generated')
    else:
        msg.error('No Vivado .xpr file exists for the current project. Bitstream generation failed')
