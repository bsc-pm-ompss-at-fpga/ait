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
import shutil
import subprocess
import distutils.spawn

from config import msg, ait_path, MIN_OD_VERSION, BITINFO_VERSION, VERSION_MAJOR, \
    VERSION_MINOR, MIN_VIVADO_VERSION

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def check_requirements():
    if distutils.spawn.find_executable('vivado'):
        # Check od version
        if not distutils.spawn.find_executable('od'):
            msg.error('od not found. Please set PATH correctly')
        od_version = str(subprocess.check_output(['od', '--version']), 'utf-8').split('\n')[0].split(' ')[-1].split('.')
        od_version = (int(od_version[0]), int(od_version[1]))
        if od_version < MIN_OD_VERSION:
            msg.error('Installed od version not supported (>= ' + str(MIN_OD_VERSION[0]) + '.' + str(MIN_OD_VERSION[1]) + ')')
    else:
        msg.error('vivado not found. Please set PATH correctly')

    vivado_version = str(subprocess.check_output(['vivado -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
    if vivado_version < MIN_VIVADO_VERSION:
        msg.error('Installed Vivado version ({}) not supported (>= {})'.format(vivado_version, MIN_VIVADO_VERSION))


def generate_Vivado_variables_tcl():
    global accels
    vivado_project_variables = '# File automatically generated by the Accelerator Integration Tool. Edit at your own risk.\n' \
                               + '\n' \
                               + '# Paths\n' \
                               + 'variable path_Project ' + os.path.relpath(project_backend_path, project_backend_path + '/scripts') + '\n' \
                               + 'variable path_Repo ' + os.path.relpath(project_backend_path + '/HLS/', project_backend_path + '/scripts') + '\n' \
                               + '\n' \
                               + '# Project variables\n' \
                               + 'variable name_Project ' + args.name + '\n' \
                               + 'variable name_Design ' + args.name + '_design\n' \
                               + 'variable target_lang ' + args.target_language + '\n' \
                               + 'variable num_accs ' + str(num_instances) + '\n' \
                               + 'variable num_jobs ' + str(args.jobs) + '\n' \
                               + 'variable ait_call "' + str(re.escape(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:]))) + '"\n' \
                               + 'variable version_major_ait ' + str(VERSION_MAJOR) + '\n' \
                               + 'variable version_minor_ait ' + str(VERSION_MINOR) + '\n' \
                               + 'variable version_bitInfo ' + str(BITINFO_VERSION).lower() + '\n' \
                               + 'variable version_wrapper ' + (str(args.wrapper_version).lower() if args.wrapper_version else '0') + '\n' \
                               + '\n' \
                               + '# IP caching variables\n' \
                               + 'variable IP_caching ' + str(not args.disable_IP_caching).lower() + '\n'

    if not args.disable_IP_caching:
        vivado_project_variables += 'variable path_CacheLocation ' + os.path.realpath(args.IP_cache_location) + '\n'

    regslice_all = '0'
    regslice_ddr = '0'
    regslice_hwruntime = '0'
    if args.interconnect_regslice is not None:
        for opt in args.interconnect_regslice:
           if opt == 'all':
               regslice_all = '1'
           elif opt == 'DDR':
               regslice_ddr = '1'
           elif opt == 'hwruntime':
               regslice_hwruntime = '1'

    vivado_project_variables += '\n' \
                                + '# ' + board.name + ' board variables\n' \
                                + 'variable board ' + board.name + '\n' \
                                + 'variable chipPart ' + chip_part + '\n' \
                                + 'variable clockFreq ' + str(args.clock) + '\n' \
                                + 'variable size_DDR ' + board.ddr.size + '\n' \
                                + 'variable arch_type ' + board.arch.type + '\n' \
                                + 'variable arch_bits ' + str(board.arch.bits) + '\n' \
                                + 'variable interconOpt ' + str(args.interconnect_opt + 1) + '\n' \
                                + 'variable interconLevel ' + str(args.interconnection_level) + '\n' \
                                + 'variable debugInterfaces ' + str(args.debug_intfs) + '\n' \
                                + 'variable interconRegSlice_all ' + regslice_all + '\n' \
                                + 'variable interconRegSlice_ddr ' + regslice_ddr + '\n' \
                                + 'variable interconRegSlice_hwruntime ' + regslice_hwruntime + '\n'

    if board.arch.type == 'soc':
        if board.arch.bits == 32:
            vivado_project_variables += 'variable addr_base "0x80000000"\n'
        else:
            vivado_project_variables += 'variable addr_base "0x00B0000000"\n'
    elif board.arch.type == 'fpga':
        if board.arch.bits == 32:
            vivado_project_variables += 'variable addr_base "0x00000000"\n'
        else:
            vivado_project_variables += 'variable addr_base "0x003000000000"\n'

    if board.board_part:
        vivado_project_variables += '\n' \
                                    + 'variable boardPart [list ' + ' '.join(board.board_part) + ']\n'
    vivado_project_variables += '\n' \
                                + '# Hardware Instrumentation variables\n' \
                                + 'variable hwcounter ' + str(args.hwcounter) + '\n' \
                                + 'variable hwinst ' + str(args.hwinst) + '\n'

    vivado_project_variables += '\n' \
                                + '# HW runtime variables\n' \
                                + 'variable hwruntime ' + str(args.hwruntime) + '\n' \
                                + 'variable extended_hwruntime ' + str(args.extended_hwruntime) + '\n' \
                                + 'variable lock_hwruntime ' + str(args.lock_hwruntime) + '\n' \
                                + 'variable cmdInSubqueue_len ' + str(args.cmdin_subqueue_len) + '\n' \
                                + 'variable cmdOutSubqueue_len ' + str(args.cmdout_subqueue_len) + '\n' \
                                + 'variable spawnInQueue_len ' + str(args.spawnin_queue_len) + '\n' \
                                + 'variable spawnOutQueue_len ' + str(args.spawnout_queue_len)

    vivado_project_variables += '\n' \
                                + '# List of accelerators\n' \
                                + 'set accels [list'

    for accel in accels[0:num_accels]:
        acc_name = accel.id + ':' + str(accel.num_instances) + ':' + accel.name

        vivado_project_variables += ' ' + acc_name

    vivado_project_variables += ']\n'

    if args.datainterfaces_map and os.path.exists(args.datainterfaces_map):
        if args.verbose_info:
            msg.log('Parsing user data interfaces map: ' + args.datainterfaces_map)

        vivado_project_variables += '\n' \
                                    + '# List of datainterfaces map\n' \
                                    + 'set dataInterfaces_map [list'

        with open(args.datainterfaces_map) as map_file:
            map_data = map_file.readlines()
            for map_line in map_data:
                elems = map_line.strip().replace('\n', '').split('\t')
                if len(elems) >= 2 and len(elems[0]) > 0 and elems[0][0] != '#':
                    vivado_project_variables += ' {' + elems[0] + ' ' + elems[1] + '}'

        vivado_project_variables += ']\n'
    elif args.datainterfaces_map:
        msg.error('User data interfaces map not found: ' + args.datainterfaces_map)
    else:
        vivado_project_variables += '\n' \
                                    + '# List of datainterfaces map\n' \
                                    + 'set dataInterfaces_map [list]\n'

    if args.debug_intfs == 'custom' and os.path.exists(args.debug_intfs_list):
        if args.verbose_info:
            msg.log('Parsing user-defined interfaces to debug: ' + args.debug_intfs_list)

        vivado_project_variables += '\n' \
                                    + '# List of debugInterfaces list\n' \
                                    + 'set debugInterfaces_list [list'

        with open(args.debug_intfs_list) as map_file:
            map_data = map_file.readlines()
            for map_line in map_data:
                elems = map_line.strip().replace('\n', '').split('\t')
                if len(elems) >= 2 and len(elems[0]) > 0 and elems[0][0] != '#':
                    vivado_project_variables += ' {' + elems[0] + ' ' + elems[1] + '}'

        vivado_project_variables += ']\n'
    elif args.debug_intfs == 'custom':
        msg.error('User-defined interfaces to debug file not found: ' + args.debug_intfs_list)

    vivado_project_variables_file = open(project_backend_path + '/scripts/projectVariables.tcl', 'w')
    vivado_project_variables_file.write(vivado_project_variables)
    vivado_project_variables_file.close()


def run_design_step(project_vars):
    global args
    global board
    global accels
    global chip_part
    global num_accels
    global num_instances
    global ait_backend_path
    global project_backend_path

    args = project_vars['args']
    board = project_vars['board']
    accels = project_vars['accels']
    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    num_accels = project_vars['num_accels']
    num_instances = project_vars['num_instances']
    project_path = project_vars['path']

    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend
    project_step_path = project_backend_path + '/scripts/' + script_folder

    # Check if the requirements are met
    check_requirements()

    # Remove old directories used on the design step
    shutil.rmtree(project_step_path, ignore_errors=True)
    shutil.rmtree(project_backend_path + '/board', ignore_errors=True)
    shutil.rmtree(project_backend_path + '/IPs', ignore_errors=True)
    shutil.rmtree(project_backend_path + '/templates', ignore_errors=True)

    # Create directories and copy necessary files for design step
    shutil.copytree(ait_backend_path + '/scripts/' + script_folder, project_step_path, ignore=shutil.ignore_patterns('*.py*'))
    shutil.copytree(ait_backend_path + '/board/' + board.name, project_backend_path + '/board/' + board.name)

    os.makedirs(project_backend_path + '/IPs')
    os.makedirs(project_backend_path + '/templates')
    shutil.copy2(ait_backend_path + '/templates/dummy_acc.tcl', project_backend_path + '/templates')

    ip_list = [ip for ip in os.listdir(ait_backend_path + '/IPs/') if re.search(r'.*\.(zip|v|vhdl)$', ip)]
    for ip in ip_list:
        shutil.copy2(ait_backend_path + '/IPs/' + ip, project_backend_path + '/IPs')

    if args.hwruntime is not None:
        for template in glob.glob(ait_backend_path + '/templates/hwruntime/' + args.hwruntime
                                  + '/' + ('extended/' if args.extended_hwruntime else '')
                                  + '*.tcl'):
            shutil.copy2(template, project_backend_path + '/templates')

        for ipdef in glob.glob(ait_backend_path + '/IPs/hwruntime/' + args.hwruntime + '/*.zip'):
            shutil.copy2(ipdef, project_backend_path + '/IPs')

    if args.user_constraints and os.path.exists(args.user_constraints):
        constraints_path = project_backend_path + '/board/' + board.name + '/constraints'
        if not os.path.exists(constraints_path):
            os.mkdir(constraints_path)
        if args.verbose_info:
            msg.log('Adding user constraints file: ' + args.user_constraints)
        shutil.copy2(args.user_constraints, constraints_path + '/')
    elif args.user_constraints:
        msg.error('User constraints file not found: ' + args.user_constraints)

    if args.user_pre_design and os.path.exists(args.user_pre_design):
        user_pre_design_ext = args.user_pre_design.split('.')[-1] if len(args.user_pre_design.split('.')) > 1 else ''
        if user_pre_design_ext != 'tcl':
            msg.error('Invalid extension for PRE design TCL script: ' + args.user_pre_design)
        elif args.verbose_info:
            msg.log('Adding pre design user script: ' + args.user_pre_design)
        shutil.copy2(args.user_pre_design, project_step_path + '/userPreDesign.tcl')
    elif args.user_pre_design:
        msg.error('User PRE design TCL script not found: ' + args.user_pre_design)

    if args.user_post_design and os.path.exists(args.user_post_design):
        user_post_design_ext = args.user_post_design.split('.')[-1] if len(args.user_post_design.split('.')) > 1 else ''
        if user_post_design_ext != 'tcl':
            msg.error('Invalid extension for POST design TCL script: ' + args.user_post_design)
        elif args.verbose_info:
            msg.log('Adding post design user script: ' + args.user_post_design)
        shutil.copy2(args.user_post_design, project_step_path + '/userPostDesign.tcl')
    elif args.user_post_design:
        msg.error('User POST design TCL script not found: ' + args.user_post_design)

    # Generate tcl file with project variables
    generate_Vivado_variables_tcl()

    # Enable beta device on Vivado init script
    if board.board_part:
        p = subprocess.Popen('echo "enable_beta_device ' + chip_part + '\nset_param board.repoPaths [list '
                             + project_backend_path + '/board/' + board.name + '/board_files]" > '
                             + project_backend_path + '/scripts/Vivado_init.tcl', shell=True)
        retval = p.wait()
    else:
        p = subprocess.Popen('echo "enable_beta_device ' + chip_part + '" > '
                             + project_backend_path + '/scripts/Vivado_init.tcl', shell=True)
        retval = p.wait()

    os.environ['MYVIVADO'] = project_backend_path

    p = subprocess.Popen('vivado -nojournal -nolog -notrace -mode batch -source '
                         + project_step_path + '/generate_design.tcl',
                         cwd=project_backend_path + '/scripts', stdout=sys.stdout.subprocess,
                         stderr=sys.stdout.subprocess, shell=True)

    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    del os.environ['MYVIVADO']
    if retval:
        msg.error('Block Design generation failed')
    else:
        msg.success('Block Design generated')


STEP_FUNC = run_design_step
