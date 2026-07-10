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

import json
import os
import re
import shutil
import sys
import subprocess

from ait.backend.xilinx.info import info, MIN_VITIS_HLS_VERSION, MIN_VIVADO_VERSION
from ait.frontend.utils import ait_path, msg

vivado_version = None
vitis_hls_version = None


def check_vivado():
    global vivado_version

    if vivado_version is None:
        if shutil.which('vivado'):
            vivado_version = subprocess.run('vivado -version | grep -oP "(V|v)ivado v\K([0-9.]*)"', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
            return check_vivado()
        else:
            msg.error('vivado not found. Please set PATH correctly')
    elif vivado_version < MIN_VIVADO_VERSION:
        msg.error(f'Installed Vivado version ({vivado_version}) not supported (>= {MIN_VIVADO_VERSION})')

    return True


def check_vitis_hls():
    global vitis_hls_version

    if vitis_hls_version is None:
        if shutil.which('vitis_hls'):
            vitis_hls_version = subprocess.run('vitis_hls -version | head -n1 | sed "s/\(Vitis.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
            return check_vitis_hls()
        else:
            msg.error('vitis_hls not found. Please set PATH correctly')
    elif vitis_hls_version < MIN_VITIS_HLS_VERSION:
        msg.error(f'Installed Vitis HLS version ({vitis_hls_version}) not supported (>= {MIN_VITIS_HLS_VERSION})')

    return True


def check_bootgen():
    if not shutil.which('bootgen'):
        msg.warning('bootgen not found. .bit.bin file will not be generated')
        return False

    return True


def check_board_support(chip_part):
    check_vivado()

    tmp_dir = os.popen('mktemp -d --suffix=_ait').read().rstrip()

    os.mkdir(f'{tmp_dir}/scripts')

    os.system(f'echo "enable_beta_device {chip_part}" > {tmp_dir}/scripts/vivado.tcl')
    os.system(f'echo "if {{[llength [get_parts {chip_part}]] == 0}} {{exit 1}}" > {tmp_dir}/scripts/ait_part_check.tcl')
    p = subprocess.Popen(f'vivado -init -nojournal -nolog -mode batch -source {tmp_dir}/scripts/ait_part_check.tcl', shell=True, stdout=open(os.devnull, 'w'), cwd=f'{tmp_dir}/scripts')
    retval = p.wait()
    os.system(f'rm -rf {tmp_dir}')
    if (int(retval) == 1):
        msg.error(f'Your current version of Vivado ({vivado_version}) does not support part {chip_part}')


def cleanup_step_files(project_args, step):
    step_index = info['steps'].index(step)

    args = project_args['args']
    project_path = project_args['path']

    project_backend_path = f'{project_path}/{args.backend}'

    if step_index < 5:
        for ext in 'bit', 'bin', 'bit.bin':
            file = f'{project_backend_path}/products/{args.name}.{ext}'
            if os.path.exists(file):
                os.remove(file)
    if step_index < 4:
        for ext in 'resources-impl.txt', 'timing-impl.txt', 'hier-utilization.txt', 'slr-utilization.txt', 'timing-summary':
            file = f'{project_backend_path}/products/reports/{args.name}.{ext}'
            if os.path.exists(file):
                os.remove(file)
    if step_index < 2:
        shutil.rmtree(f'{project_backend_path}/tcl', ignore_errors=True)
        shutil.rmtree(f'{project_backend_path}/IPs', ignore_errors=True)
        shutil.rmtree(f'{project_backend_path}/constraints', ignore_errors=True)
        shutil.rmtree(f'{project_backend_path}/user', ignore_errors=True)
        shutil.rmtree(f'{project_backend_path}/products/boot', ignore_errors=True)
        for ext in 'ait.json', 'xtasks.config':
            file = f'{project_backend_path}/products/{args.name}.{ext}'
            if os.path.exists(file):
                os.remove(file)
    if step_index < 1:
        shutil.rmtree(f'{project_backend_path}', ignore_errors=True)
        shutil.rmtree(f'{project_path}/products', ignore_errors=True)


def prepare_step_files(project_args, step):
    args = project_args['args']
    project_path = project_args['path']
    board = project_args['board']

    ait_backend_path = f'{ait_path}/backend/{args.backend}'
    project_backend_path = f'{project_path}/{args.backend}'

    if step == 'HLS':
        shutil.copytree(f'{ait_backend_path}/board/{board.name}', f'{project_backend_path}/board')
    elif step == 'design':
        user_files_path = f'{project_backend_path}/user'

        shutil.copytree(f'{ait_backend_path}/tcl', f'{project_backend_path}/tcl')
        shutil.copytree(f'{ait_backend_path}/IPs', f'{project_backend_path}/IPs')
        os.symlink(f'{project_backend_path}/board/baseDesign.tcl', f'{project_backend_path}/tcl/templates/baseDesign.tcl')

        if args.user_config and os.path.exists(args.user_config):
            os.makedirs(user_files_path)
            shutil.copy2(args.user_config, f'{user_files_path}/config.json')
        elif args.user_config:
            msg.error(f'User configuration file not found: {args.user_config}')

        if args.user_constraints and os.path.exists(args.user_constraints):
            if args.verbose_info:
                msg.log(f'Adding user constraints file: {args.user_constraints}')
            user_constraints_path = f'{user_files_path}/constraints'
            os.makedirs(user_constraints_path)
            shutil.copy2(args.user_constraints, user_constraints_path)
        elif args.user_constraints:
            msg.error(f'User constraints file not found: {args.user_constraints}')

        if args.user_pre_design and os.path.exists(args.user_pre_design):
            user_pre_design_ext = args.user_pre_design.split('.')[-1] if len(args.user_pre_design.split('.')) > 1 else ''
            if user_pre_design_ext != 'tcl':
                msg.error(f'Invalid extension for PRE design TCL script: {args.user_pre_design}')
            elif args.verbose_info:
                msg.log(f'Adding pre design user script: {args.user_pre_design}')
            user_tcl_scripts_path = f'{user_files_path}/tcl'
            os.makedirs(user_tcl_scripts_path)
            shutil.copy2(args.user_pre_design, f'{user_tcl_scripts_path}/userPreDesign.tcl')
        elif args.user_pre_design:
            msg.error(f'User PRE design TCL script not found: {args.user_pre_design}')

        if args.user_post_design and os.path.exists(args.user_post_design):
            user_post_design_ext = args.user_post_design.split('.')[-1] if len(args.user_post_design.split('.')) > 1 else ''
            if user_post_design_ext != 'tcl':
                msg.error(f'Invalid extension for POST design TCL script: {args.user_post_design}')
            elif args.verbose_info:
                msg.log(f'Adding post design user script: {args.user_post_design}')
            user_tcl_scripts_path = f'{user_files_path}/tcl'
            os.makedirs(user_tcl_scripts_path, exist_ok=True)
            shutil.copy2(args.user_post_design, f'{user_tcl_scripts_path}/userPostDesign.tcl')
        elif args.user_post_design:
            msg.error(f'User POST design TCL script not found: {args.user_post_design}')

    ait_config_file = open(f'{project_path}/ait_config.json', 'w+')
    ait_config_file.write(json.dumps(vars(args), indent=4))
    ait_config_file.close()


def process_output(args, output):
    if args.verbose:
        for line in output:
            sys.stdout.write(line)
    elif args.verbose_info:
        for line in output:
            if re.match(r'^\[AIT\]', line):
                sys.stdout.write(line)
            else:
                sys.stdout.log(line)
