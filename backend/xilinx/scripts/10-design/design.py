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
import re
import sys
import glob
import shutil
import subprocess
import distutils.spawn
import json

from frontend.config import BITINFO_VERSION, VERSION_MAJOR, \
    VERSION_MINOR, MIN_VIVADO_VERSION
from frontend.utils import msg, ait_path, decimalFromHumanReadable

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def check_requirements():
    if not distutils.spawn.find_executable('vivado'):
        msg.error('vivado not found. Please set PATH correctly')

    vivado_version = str(subprocess.check_output(['vivado -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
    if vivado_version < MIN_VIVADO_VERSION:
        msg.error('Installed Vivado version ({}) not supported (>= {})'.format(vivado_version, MIN_VIVADO_VERSION))


def generate_Vivado_variables_tcl():
    global accs
    global args

    vivado_project_variables = '# File automatically generated by the Accelerator Integration Tool. Edit at your own risk.\n' \
                               + '\n' \
                               + '## AIT messages procedures\n' \
                               + '# Error\n' \
                               + 'proc aitError {msg} {\n' \
                               + '   puts "\[AIT\] ERROR: $msg"\n' \
                               + '   exit 1\n' \
                               + '}\n' \
                               + '# Warning\n' \
                               + 'proc aitWarning {msg} {\n' \
                               + '   puts "\[AIT\] WARNING: $msg"\n' \
                               + '}\n' \
                               + '\n' \
                               + '# Info\n' \
                               + 'proc aitInfo {msg} {\n' \
                               + '   puts "\[AIT\] INFO: $msg"\n' \
                               + '}\n' \
                               + '\n' \
                               + '# Log\n' \
                               + 'proc aitLog {msg} {\n' \
                               + '   puts "\[AIT\]: $msg"\n' \
                               + '}\n' \
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
                               + 'variable num_acc_creators ' + str(num_acc_creators) + '\n' \
                               + 'variable num_jobs ' + str(args.jobs) + '\n' \
                               + 'variable ait_call "' + str(re.escape(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:]))) + '"\n' \
                               + 'variable bitInfo_note ' + str(re.escape(args.bitinfo_note)) + '\n' \
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
    regslice_mem = '0'
    regslice_hwruntime = '0'
    if args.interconnect_regslice is not None:
        for opt in args.interconnect_regslice:
            if opt == 'all':
                regslice_all = '1'
            elif opt == 'mem':
                regslice_mem = '1'
            elif opt == 'hwruntime':
                regslice_hwruntime = '1'

    vivado_project_variables += '\n' \
                                + '# Bitstream variables\n' \
                                + 'variable interconOpt ' + str(args.interconnect_opt + 1) + '\n' \
                                + 'variable debugInterfaces ' + str(args.debug_intfs) + '\n' \
                                + 'variable interconRegSlice_all ' + regslice_all + '\n' \
                                + 'variable interconRegSlice_mem ' + regslice_mem + '\n' \
                                + 'variable interconRegSlice_hwruntime ' + regslice_hwruntime + '\n' \
                                + 'variable interleaving_stride ' + (hex(args.memory_interleaving_stride) if args.memory_interleaving_stride is not None else str(args.memory_interleaving_stride)) + '\n'\
                                + 'variable simplify_interconnection ' + str(args.simplify_interconnection).lower() + '\n' \
                                + 'variable floorplanning_constr ' + str(args.floorplanning_constr) + '\n' \
                                + 'variable slr_slices ' + str(args.slr_slices) + '\n' \
                                + '\n' \
                                + '# ' + board.name + ' board variables\n' \
                                + 'variable board ' + board.name + '\n' \
                                + 'variable chipPart ' + chip_part + '\n' \
                                + 'variable clockFreq ' + str(args.clock) + '\n' \
                                + 'variable arch_device ' + board.arch.device + '\n'

    if args.slr_slices is not None or args.floorplanning_constr is not None:
        vivado_project_variables += 'variable board_slr_num ' + str(board.arch.slr.num) + '\n' \
                                    + 'variable board_slr_master ' + str(board.arch.slr.master) + '\n'

    vivado_project_variables += 'variable address_map [dict create]\n' \
                                + 'dict set address_map "ompss_base_addr" ' + board.address_map.ompss_base_addr + '\n' \
                                + 'dict set address_map "mem_base_addr" ' + board.address_map.mem_base_addr + '\n' \
                                + 'dict set address_map "mem_type" ' + board.mem.type + '\n'

    if board.arch.device == 'zynq' or board.arch.device == 'zynqmp':
        vivado_project_variables += 'dict set address_map "mem_size" ' + hex(decimalFromHumanReadable(board.mem.size)) + '\n'
    elif board.arch.device == 'alveo':
        vivado_project_variables += 'dict set address_map "mem_num_banks" ' + str(board.mem.num_banks) + '\n' \
                                    + 'dict set address_map "mem_bank_size" ' + hex(decimalFromHumanReadable(board.mem.bank_size)) + '\n'

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
                                + 'variable spawnOutQueue_len ' + str(args.spawnout_queue_len) + '\n' \
                                + 'variable hwruntime_interconnect ' + str(args.hwruntime_interconnect) + '\n' \
                                + 'variable enable_spawn_queues ' + str(not args.disable_spawn_queues) + '\n'

    vivado_project_variables += '\n' \
                                + '# List of accelerators\n' \
                                + 'set accs [list'

    for acc in accs[0:num_accs]:
        acc_name = str(acc.type) + ':' + str(acc.num_instances) + ':' + acc.name

        vivado_project_variables += ' ' + acc_name

    vivado_project_variables += ']\n'

    # Generate acc instance list with SLR info
    # Placement info is only needed for registers, constraints are dumped into constraint file
    if (args.slr_slices == 'acc') or (args.slr_slices == 'all'):
        acc_pl_dict = 'set acc_placement [dict create '
        for acc in accs[0:num_accs]:
            acc_pl_dict += ' ' + str(acc.type) + ' [list'
            for slrnum in acc.SLR:
                acc_pl_dict += ' ' + str(slrnum)
            acc_pl_dict += ']'
        acc_pl_dict += ']'
        vivado_project_variables += acc_pl_dict + '\n'

    # Generate acc constraint file
    if (args.floorplanning_constr == 'acc') or (args.floorplanning_constr == 'all'):
        accConstrFiles = open(f'{project_backend_path}/board/{board.name}/constraints/acc_floorplan.xdc', 'w')
        for acc in accs[0:num_accs]:
            # Instantiate each accelerator with a single instance and placement info
            for instanceNumber in range(acc.num_instances):
                accBlock = f'{acc.name}_{instanceNumber}'
                accConstrFiles.write(f'add_cells_to_pblock [get_pblocks slr{acc.SLR[instanceNumber]}_pblock] '
                                     + '[get_cells {'
                                     + f'*/{accBlock}/Adapter_outStream '
                                     + f'*/{accBlock}/Adapter_inStream '
                                     + f'*/{accBlock}/accID '
                                     + f'*/{accBlock}/{acc.name}_ompss'
                                     + '}]\n')
        accConstrFiles.close()

    if args.hwruntime == 'pom':
        picos_args_hash = '{}-{}-{}-{}-{}-{}-{}-{}-{}-{}'.format(
                          args.picos_max_args_per_task,
                          args.picos_max_deps_per_task,
                          args.picos_max_copies_per_task,
                          args.picos_num_dcts,
                          args.picos_tm_size,
                          args.picos_dm_size,
                          args.picos_vm_size,
                          args.picos_dm_ds,
                          args.picos_dm_hash,
                          args.picos_hash_t_size)
        vivado_project_variables += '\n' \
                                    + '# Picos parameter hash\n' \
                                    + 'variable picos_args_hash {}'.format(picos_args_hash)

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
                elems = map_line.strip().replace('\n', '')
                if elems[0][0] != '#':
                    vivado_project_variables += ' ' + str(elems)

        vivado_project_variables += ']\n'
    elif args.debug_intfs == 'custom':
        msg.error('User-defined interfaces to debug file not found: ' + args.debug_intfs_list)

    vivado_project_variables_file = open(project_backend_path + '/scripts/projectVariables.tcl', 'w')
    vivado_project_variables_file.write(vivado_project_variables)
    vivado_project_variables_file.close()


def load_acc_placement(accList, args):
    # Read placement info from file
    if args.placement_file and os.path.exists(args.placement_file):
        usrPlacement = json.load(open(args.placement_file))
        for acc in accList:
            if acc.name not in usrPlacement:
                msg.warning('No placement given for acc ' + acc.name)
            else:
                placeList = usrPlacement[acc.name]
                if len(placeList) != acc.num_instances:
                    msg.warning('Placement list does not match number instances, placing only matching instances')
                acc.SLR = placeList

    elif args.placement_file:
        msg.error('Placement file not found: ' + args.user_constraints)


def run_design_step(project_args):
    global args
    global board
    global accs
    global chip_part
    global start_time
    global num_accs
    global num_instances
    global num_acc_creators
    global ait_backend_path
    global project_backend_path

    args = project_args['args']
    board = project_args['board']
    accs = project_args['accs']
    start_time = project_args['start_time']
    num_accs = project_args['num_accs']
    num_instances = project_args['num_instances']
    num_acc_creators = project_args['num_acc_creators']
    project_path = project_args['path']

    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend
    project_step_path = project_backend_path + '/scripts/' + script_folder

    # Check if the requirements are met
    check_requirements()

    # Load accelerator placement info
    load_acc_placement(accs, args)

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

    for template in glob.glob(ait_backend_path + '/templates/hwruntime/' + args.hwruntime
                              + '/' + ('extended/' if args.extended_hwruntime else '')
                              + '*.tcl'):
        shutil.copy2(template, project_backend_path + '/templates')

    for ipdef in glob.glob(ait_backend_path + '/IPs/hwruntime/' + args.hwruntime + '/*.zip'):
        shutil.copy2(ipdef, project_backend_path + '/IPs')

    if args.memory_interleaving_stride is not None:
        subprocess.check_output(['sed -i "s/\`undef __ENABLE__/\`define __ENABLE__/" ' + project_backend_path + '/IPs/addrInterleaver.v'], shell=True)

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
    if os.path.exists(project_backend_path + '/board/' + board.name + '/board_files'):
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
        msg.error('Block Design generation failed', start_time, False)
    else:
        msg.success('Block Design generated')

    if (args.hwruntime == 'pom'):
        regex_strings = [
            (r'MAX_ARGS_PER_TASK = [0-9]*', 'MAX_ARGS_PER_TASK = {}'.format(args.picos_max_args_per_task)),
            (r'MAX_DEPS_PER_TASK = [0-9]*', 'MAX_DEPS_PER_TASK = {}'.format(args.picos_max_deps_per_task)),
            (r'MAX_COPIES_PER_TASK = [0-9]*', 'MAX_COPIES_PER_TASK = {}'.format(args.picos_max_copies_per_task)),
            (r'NUM_DCTS = [0-9]*', 'NUM_DCTS = {}'.format(args.picos_num_dcts)),
            (r'TM_SIZE = [0-9]*', 'TM_SIZE = {}'.format(args.picos_tm_size)),
            (r'DM_SIZE = [0-9]*', 'DM_SIZE = {}'.format(args.picos_dm_size)),
            (r'VM_SIZE = [0-9]*', 'VM_SIZE = {}'.format(args.picos_vm_size)),
            (r'DM_DS = "[a-zA-Z_]*"', 'DM_DS = "{}"'.format(args.picos_dm_ds)),
            (r'DM_HASH = "[a-zA-Z_]*"', 'DM_HASH = "{}"'.format(args.picos_dm_hash)),
            (r'HASH_T_SIZE = [0-9]*', 'HASH_T_SIZE = {}'.format(args.picos_hash_t_size))]

        config_file_path = glob.glob(project_backend_path + '/IPs/bsc_ompss_picosompssmanager_*/')[0] + 'src/config.sv'

        with open(config_file_path, 'r') as config_file:
            config_str = config_file.read()
        for regex_str in regex_strings:
            config_str = re.sub(regex_str[0], regex_str[1], config_str, count=1)
        with open(config_file_path, 'w') as config_file:
            config_file.write(config_str)


STEP_FUNC = run_design_step
