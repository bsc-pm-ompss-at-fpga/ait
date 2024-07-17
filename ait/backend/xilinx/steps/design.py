#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2024 Barcelona Supercomputing Center              #
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
import random
import re
import shutil
import subprocess
import sys

import ait.backend.xilinx.utils.checkers as checkers
from ait.frontend.config import BITINFO_VERSION,  \
    VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH
from ait.frontend.utils import ait_path, decimalFromHumanReadable, msg

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def generate_Vivado_variables_tcl():
    global accs
    global args

    vivado_project_variables = '# File automatically generated by the Accelerator Integration Tool. Edit at your own risk.\n' \
                               + '\n' \
                               + 'namespace eval AIT {' \
                               + '\n' \
                               + '\t# Project variables\n' \
                               + '\tvariable name_Project {}\n'           .format(args.name) \
                               + '\tvariable name_Design {}_design\n'     .format(args.name) \
                               + '\tvariable target_lang {}\n'            .format(args.target_language) \
                               + '\tvariable num_accs {}\n'               .format(str(args.num_instances)) \
                               + '\tvariable num_acc_creators {}\n'       .format(str(args.num_acc_creators)) \
                               + '\tvariable ait_call "{}"\n'             .format(str(re.escape(os.path.basename(sys.argv[0]) + ' ' + ' '.join(sys.argv[1:])))) \
                               + '\tvariable bitInfo_note {}\n'           .format(str((re.escape(args.bitinfo_note))) if args.bitinfo_note is not None else {}) \
                               + '\tvariable version_major_ait {}\n'      .format(str(VERSION_MAJOR)) \
                               + '\tvariable version_minor_ait {}\n'      .format(str(VERSION_MINOR)) \
                               + '\tvariable version_patch_ait {}\n'      .format(str(VERSION_PATCH)) \
                               + '\tvariable version_bitInfo {}\n'        .format(str(BITINFO_VERSION).lower()) \
                               + '\tvariable version_wrapper {}\n'        .format((str(args.wrapper_version).lower() if args.wrapper_version else '0')) \
                               + '\n' \
                               + '\t# IP caching variables\n' \
                               + '\tvariable IP_caching {}\n'             .format(str(not args.disable_IP_caching).lower())

    if not args.disable_IP_caching:
        vivado_project_variables += '\tvariable path_CacheLocation {}\n'  .format(os.path.realpath(args.IP_cache_location))

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
                                + '\t# Bitstream variables\n' \
                                + '\tvariable user_id {}\n'                     .format(str(user_id)) \
                                + '\tvariable interconOpt {}\n'                 .format(str(args.interconnect_opt + 1)) \
                                + '\tvariable debugInterfaces {}\n'             .format(str(args.debug_intfs)) \
                                + '\tvariable interconRegSlice_all {}\n'        .format(regslice_all) \
                                + '\tvariable interconRegSlice_mem {}\n'        .format(regslice_mem) \
                                + '\tvariable interconRegSlice_hwruntime {}\n'  .format(regslice_hwruntime) \
                                + '\tvariable interleaving_stride {}\n'         .format((hex(args.memory_interleaving_stride) if args.memory_interleaving_stride is not None else str(args.memory_interleaving_stride)))\
                                + '\tvariable simplify_interconnection {}\n'    .format(str(args.simplify_interconnection).lower()) \
                                + '\tvariable interconPriority {}\n'            .format(str(args.interconnect_priorities)) \
                                + '\tvariable floorplanning_constr {}\n'        .format(str(args.floorplanning_constr)) \
                                + '\tvariable slr_slices {}\n'                  .format(str(args.slr_slices)) \
                                + '\tvariable regslice_pipeline_stages {}\n'    .format(args.regslice_pipeline_stages) \
                                + '\tvariable power_monitor {}\n'               .format(str(args.power_monitor)) \
                                + '\tvariable thermal_monitor {}\n'              .format(str(args.thermal_monitor)) \
                                + '\tvariable disable_creator_ports {}\n'       .format(str(args.disable_creator_ports)) \
                                + '\n' \
                                + '\t# {} board variables\n'                    .format(board.name) \
                                + '\tvariable board {}\n'                       .format(board.name) \
                                + '\tvariable chipPart {}\n'                    .format(chip_part)
    if board.board_part:
        vivado_project_variables += '\tvariable boardPart [list {}]\n'          .format(' '.join(board.board_part))

    vivado_project_variables += '\tvariable clockFreq {}\n'                     .format(str(args.clock)) \
                                + '\tvariable arch_device {}\n'                 .format(board.arch.device)

    if args.slr_slices is not None or args.floorplanning_constr is not None:
        vivado_project_variables += '\tvariable board_slr_num {}\n'          .format(str(board.arch.slr.num)) \
                                    + '\tvariable board_hwruntime_slr {}\n'  .format(str(board.arch.slr.hwruntime)) \
                                    + '\tvariable board_memory_slr {}\n'     .format(str(board.arch.slr.memory))

    vivado_project_variables += '\tvariable address_map [dict create]\n' \
                                + '\tdict set address_map "ompss_base_addr" {}\n'  .format(board.address_map.ompss_base_addr) \
                                + '\tdict set address_map "mem_base_addr" {}\n'    .format(board.address_map.mem_base_addr) \
                                + '\tdict set address_map "mem_type" {}\n'         .format(board.mem.type)

    if board.arch.device == 'zynq' or board.arch.device == 'zynqmp':
        vivado_project_variables += '\tdict set address_map "mem_size" {}\n'         .format(hex(decimalFromHumanReadable(board.mem.size)))
    elif board.arch.device == 'alveo':
        vivado_project_variables += '\tdict set address_map "mem_num_banks" {}\n'    .format(str(board.mem.num_banks)) \
                                    + '\tdict set address_map "mem_bank_size" {}\n'  .format(hex(decimalFromHumanReadable(board.mem.bank_size)))

    vivado_project_variables += '\n' \
                                + '\t# Hardware Instrumentation variables\n' \
                                + '\tvariable hwcounter {}\n'                   .format(str(args.hwcounter)) \
                                + '\tvariable hwinst {}\n'                      .format(str(args.hwinst))

    vivado_project_variables += '\n' \
                                + '\t# HW runtime variables\n' \
                                + '\tvariable deps_hwruntime {}\n'          .format(str(args.deps_hwruntime)) \
                                + '\tvariable task_creation {}\n'           .format(str(args.task_creation)) \
                                + '\tvariable lock_hwruntime {}\n'          .format(str(args.lock_hwruntime)) \
                                + '\tvariable cmdInSubqueue_len {}\n'       .format(str(args.cmdin_subqueue_len)) \
                                + '\tvariable cmdOutSubqueue_len {}\n'      .format(str(args.cmdout_subqueue_len)) \
                                + '\tvariable spawnInQueue_len {}\n'        .format(str(args.spawnin_queue_len)) \
                                + '\tvariable spawnOutQueue_len {}\n'       .format(str(args.spawnout_queue_len)) \
                                + '\tvariable hwruntime_interconnect {}\n'  .format(str(args.hwruntime_interconnect)) \
                                + '\tvariable enable_spawn_queues {}\n'     .format(str(not args.disable_spawn_queues)) \
                                + '\tvariable max_args_per_task {}\n'       .format(str(args.max_args_per_task)) \
                                + '\tvariable max_deps_per_task {}\n'       .format(str(args.max_deps_per_task)) \
                                + '\tvariable max_copies_per_task {}\n'     .format(str(args.max_copies_per_task)) \
                                + '\tvariable enable_pom_axilite {}\n'      .format(str(args.enable_pom_axilite))

    if args.deps_hwruntime:
        vivado_project_variables += '\n' \
                                    + '\t# Picos parameters\n' \
                                    + '\tvariable picos_num_dcts {}\n'     .format(str(args.picos_num_dcts)) \
                                    + '\tvariable picos_tm_size {}\n'      .format(str(args.picos_tm_size)) \
                                    + '\tvariable picos_dm_size {}\n'      .format(str(args.picos_dm_size)) \
                                    + '\tvariable picos_vm_size {}\n'      .format(str(args.picos_vm_size)) \
                                    + '\tvariable picos_dm_ds {}\n'        .format(args.picos_dm_ds) \
                                    + '\tvariable picos_dm_hash {}\n'      .format(args.picos_dm_hash) \
                                    + '\tvariable picos_hash_t_size {}\n'  .format(str(args.picos_hash_t_size))

    vivado_project_variables += '\n' \
                                + '\t# List of accelerators\n' \
                                + '\tset accs [list'

    for acc in accs[0:args.num_accs]:
        acc_name = str(acc.type) + ':' + str(acc.num_instances) + ':' + acc.name + ':' + str(acc.task_creation)
        vivado_project_variables += ' ' + acc_name

    vivado_project_variables += '\t]\n'

    # Generate acc instance list with SLR info
    acc_pl_dict = 'set acc_placement [dict create '
    for acc in accs[0:args.num_accs]:
        if hasattr(acc, 'SLR'):
            acc_pl_dict += ' ' + str(acc.name) + ' [list'
            for slrnum in acc.SLR:
                acc_pl_dict += ' ' + str(slrnum)
            acc_pl_dict += ']'
    acc_pl_dict += ']'
    vivado_project_variables += '\t' + acc_pl_dict + '\n'

    # Generate acc constraint file
    if (args.floorplanning_constr == 'acc') or (args.floorplanning_constr == 'all'):
        accConstrFiles = open(project_board_path + '/constraints/acc_floorplan.xdc', 'w')
        for acc in accs[0:args.num_accs]:
            if hasattr(acc, 'SLR'):
                instancesToPlace = len(acc.SLR)
                if len(acc.SLR) > acc.num_instances:
                    instancesToPlace = acc.num_instances
                    msg.warning('Placement list for accelerator {} has more instances than expected ({} > {}). Placing instances 0-{}'.format(acc.name, len(acc.SLR), acc.num_instances, instancesToPlace - 1))
                elif len(acc.SLR) < acc.num_instances:
                    instancesToPlace = len(acc.SLR)
                    msg.warning('Placement list for accelerator {} has less instances than expected ({} < {}). Placing instances 0-{}'.format(acc.name, len(acc.SLR), acc.num_instances, instancesToPlace - 1))
                # Instantiate each accelerator with a single instance and placement info
                for instanceNumber in range(instancesToPlace):
                    accBlock = '{}_{}'                                                    .format(acc.name, instanceNumber)
                    accConstrFiles.write('add_cells_to_pblock [get_pblocks slr{}_pblock] '.format(acc.SLR[instanceNumber])
                                         + '[get_cells {'
                                         + '*/{}/Adapter_* '                              .format(accBlock)
                                         + '*/{}/TID_subset_converter '                   .format(accBlock)
                                         + '*/{}/{}_ompss'                                .format(accBlock, acc.name)
                                         + '}]\n')
                    if acc.task_creation:
                        accConstrFiles.write('add_cells_to_pblock [get_pblocks slr{}_pblock] '  .format(acc.SLR[instanceNumber])
                                             + '[get_cells {'
                                             + '*/{}/new_task_spawner '                         .format(accBlock)
                                             + '*/{}/axis_tid_demux '                           .format(accBlock)
                                             + '}]\n')
        accConstrFiles.close()

    if args.datainterfaces_map and os.path.exists(args.datainterfaces_map):
        if args.verbose_info:
            msg.log('Parsing user data interfaces map: ' + args.datainterfaces_map)

        vivado_project_variables += '\n' \
                                    + '\t# List of datainterfaces map\n' \
                                    + '\tset dataInterfaces_map [list'

        with open(args.datainterfaces_map) as map_file:
            map_data = map_file.readlines()
            for map_line in map_data:
                elems = map_line.strip().replace('\n', '').replace('\t', ' ').split(' ')
                if len(elems) >= 2 and len(elems[0]) > 0 and elems[0][0] != '#':
                    vivado_project_variables += '\t {' + elems[0] + ' ' + elems[1] + '}'

        vivado_project_variables += '\t]\n'
    elif args.datainterfaces_map:
        msg.error('User data interfaces map not found: ' + args.datainterfaces_map)
    else:
        vivado_project_variables += '\n' \
                                    + '\t# List of datainterfaces map\n' \
                                    + '\tset dataInterfaces_map [list]\n'

    if args.debug_intfs == 'custom' and os.path.exists(args.debug_intfs_list):
        if args.verbose_info:
            msg.log('Parsing user-defined interfaces to debug: ' + args.debug_intfs_list)

        vivado_project_variables += '\n' \
                                    + '\t# List of debugInterfaces list\n' \
                                    + '\tset debugInterfaces_list [list'

        with open(args.debug_intfs_list) as map_file:
            map_data = map_file.readlines()
            for map_line in map_data:
                elems = map_line.strip().replace('\n', '')
                if elems[0][0] != '#':
                    vivado_project_variables += '\t ' + str(elems)

        vivado_project_variables += ']\n'
    elif args.debug_intfs == 'custom':
        msg.error('User-defined interfaces to debug file not found: ' + args.debug_intfs_list)

    vivado_project_variables += '}\n'

    vivado_project_variables_file = open(project_backend_path + '/tcl/projectVariables.tcl', 'w')
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
                acc.SLR = usrPlacement[acc.name]

    elif args.placement_file:
        msg.error('Placement file not found: ' + args.user_constraints)


def run_step(project_args):
    global args
    global board
    global accs
    global chip_part
    global start_time
    global user_id
    global ait_backend_path
    global project_backend_path
    global project_board_path

    args = project_args['args']
    board = project_args['board']
    accs = project_args['accs']
    start_time = project_args['start_time']
    project_path = project_args['path']

    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend
    project_board_path = project_backend_path + '/board/' + args.board

    # Check if Vivado requirements are met
    checkers.check_vivado()

    # Copy AIT tcl scripts and IPs to project directory tree
    shutil.rmtree(project_backend_path + '/tcl', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/tcl', project_backend_path + '/tcl')
    shutil.rmtree(project_backend_path + '/IPs', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/IPs', project_backend_path + '/IPs')
    shutil.rmtree(project_backend_path + '/board', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/board/' + args.board, project_board_path)

    # Load accelerator placement info
    load_acc_placement(accs[0:args.num_accs], args)

    if args.memory_interleaving_stride is not None:
        subprocess.run('sed -i "s/\`undef __ENABLE__/\`define __ENABLE__/" {}/IPs/bsc_axiu_addrInterleaver.v'.format(project_backend_path), shell=True, check=True)

    if args.user_constraints and os.path.exists(args.user_constraints):
        constraints_path = project_board_path + '/constraints'
        if not os.path.exists(constraints_path):
            os.mkdir(constraints_path)
        if args.verbose_info:
            msg.log('Adding user constraints file: ' + args.user_constraints)
        shutil.copy2(args.user_constraints, constraints_path + '/')
    elif args.user_constraints:
        msg.error('User constraints file not found: ' + args.user_constraints)

    # Generate random USERID to identify the bitstream
    user_id = str(hex(random.randrange(2**32)))
    msg.log('Setting bitstream user id: ' + user_id)
    subprocess.run('sed -i s/BITSTREAM_USERID/{}/ {}/constraints/basic_constraints.xdc'.format(user_id, project_board_path), shell=True, check=True)

    if args.user_pre_design and os.path.exists(args.user_pre_design):
        user_pre_design_ext = args.user_pre_design.split('.')[-1] if len(args.user_pre_design.split('.')) > 1 else ''
        if user_pre_design_ext != 'tcl':
            msg.error('Invalid extension for PRE design TCL script: ' + args.user_pre_design)
        elif args.verbose_info:
            msg.log('Adding pre design user script: ' + args.user_pre_design)
        shutil.copy2(args.user_pre_design, project_backend_path + '/tcl/scripts/userPreDesign.tcl')
    elif args.user_pre_design:
        msg.error('User PRE design TCL script not found: ' + args.user_pre_design)

    if args.user_post_design and os.path.exists(args.user_post_design):
        user_post_design_ext = args.user_post_design.split('.')[-1] if len(args.user_post_design.split('.')) > 1 else ''
        if user_post_design_ext != 'tcl':
            msg.error('Invalid extension for POST design TCL script: ' + args.user_post_design)
        elif args.verbose_info:
            msg.log('Adding post design user script: ' + args.user_post_design)
        shutil.copy2(args.user_post_design, project_backend_path + '/tcl/scripts/userPostDesign.tcl')
    elif args.user_post_design:
        msg.error('User POST design TCL script not found: ' + args.user_post_design)

    # Generate tcl file with project variables
    generate_Vivado_variables_tcl()

    # Enable beta device on Vivado init script
    init_script_str = 'enable_beta_device {}'.format(chip_part)
    if os.path.exists(project_board_path + '/board_files'):
        init_script_str += '\nset_param board.repoPaths [list {}]'.format(project_board_path + '/board_files')

    subprocess.run('echo {} > {}/vivado.tcl'.format(init_script_str, project_backend_path), shell=True, check=True)

    p = subprocess.Popen('vivado -init -nojournal -nolog -notrace -mode batch -source '
                         + project_backend_path + '/tcl/scripts/generate_design.tcl',
                         cwd=project_backend_path, stdout=sys.stdout.subprocess,
                         stderr=sys.stdout.subprocess, shell=True)

    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        msg.error('Block Design generation failed', start_time, False)
    else:
        msg.success('Block Design generated')
