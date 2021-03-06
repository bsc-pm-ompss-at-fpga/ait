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

from frontend.config import msg, ait_path, MIN_VIVADO_VERSION

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def check_requirements():
    if not distutils.spawn.find_executable('vivado'):
        msg.error('vivado not found. Please set PATH correctly')

    vivado_version = str(subprocess.check_output(['vivado -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
    if vivado_version < MIN_VIVADO_VERSION:
        msg.error('Installed Vivado version ({}) not supported (>= {})'.format(vivado_version, MIN_VIVADO_VERSION))


def gen_utilization_report(out_path):
    av_resources = {}
    used_resources = {}
    util_resources = {}

    # Check Zynq boards path
    rpt_path = project_backend_path + '/' + args.name + '/' + args.name + '.runs/impl_1'
    rpt_path += '/' + args.name + '_design_wrapper_utilization_placed.rpt'
    if not os.path.exists(rpt_path):
        # Check Alpha Data path
        rpt_path = project_backend_path + '/' + args.name + '/' + args.name + '.runs/impl_1'
        rpt_path += '/' + args.name + '_design_top_utilization_placed.rpt'
        if not os.path.exists(rpt_path):
            msg.warning('Cannot find rpt file. Skipping bitstream utilization report')
            return

    with open(rpt_path, 'r') as rpt_file:
        rpt_data = rpt_file.readlines()

        # Search LUT/FF section
        # NOTE: Possible section names: Slice Logic, CLB Logic
        ids = [idx for idx in range(len(rpt_data) - 1) if ((re.match(r'^[0-9]\. ' + 'Slice Logic\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '--------------\n')
                                                           or (re.match(r'^[0-9]\. ' + 'CLB Logic\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '------------\n'))]
        if len(ids) != 1:
            msg.warning('Cannot find LUT/FF info in rpt file. Skipping bitstream utilization report')
            return

        # Get LUT
        elems = rpt_data[ids[0] + 6].split('|')
        used_resources['LUT'] = elems[2].strip()
        av_resources['LUT'] = elems[4].strip()
        util_resources['LUT'] = elems[5].strip()

        # Get FF
        elems = rpt_data[ids[0] + 11].split('|')
        used_resources['FF'] = elems[2].strip()
        av_resources['FF'] = elems[4].strip()
        util_resources['FF'] = elems[5].strip()

        # Get DSP
        # NOTE: Possible section names: DSP, ARITHMETIC
        ids = [idx for idx in range(len(rpt_data) - 1) if ((re.match(r'^[0-9]\. ' + 'DSP\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '------\n')
                                                           or (re.match(r'^[0-9]\. ' + 'ARITHMETIC\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '-------------\n'))]
        if len(ids) != 1:
            msg.warning('Cannot find DSP info in rpt file. Skipping bitstream utilization report')
            return
        elems = rpt_data[ids[0] + 6].split('|')
        used_resources['DSP'] = elems[2].strip()
        av_resources['DSP'] = elems[4].strip()
        util_resources['DSP'] = elems[5].strip()

        # Search BRAM/URAM
        # NOTE: Possible section names: Memory, BLOCKRAM
        ids = [idx for idx in range(len(rpt_data) - 1) if ((re.match(r'^[0-9]\. ' + 'Memory\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '---------\n')
                                                           or (re.match(r'^[0-9]\. ' + 'BLOCKRAM\n', rpt_data[idx])
                                                           and rpt_data[idx + 1] == '-----------\n'))]
        if len(ids) != 1:
            msg.warning('Cannot find BRAM info in rpt file. Skipping bitstream utilization report')
            return

        # BRAM
        elems = rpt_data[ids[0] + 6].split('|')
        used_resources['BRAM'] = str(int(float(elems[2].strip()) * 2))
        av_resources['BRAM'] = str(int(float(elems[4].strip()) * 2))
        util_resources['BRAM'] = elems[5].strip()

        # URAM
        # NOTE: It is not placed in the same offset for all boards (search in some lines)
        # NOTE: It is not available in all boards, so check if valid data is found
        ids = [idx for idx in range(ids[0] + 6, ids[0] + 20) if ((re.match(r'^| URAM', rpt_data[idx])))]
        for idx in ids:
            elems = rpt_data[idx].split('|')
            if len(elems) >= 6 and elems[1].strip() == 'URAM':
                used_resources['URAM'] = elems[2].strip()
                av_resources['URAM'] = elems[4].strip()
                util_resources['URAM'] = elems[5].strip()
                break

    resources_file = open(out_path, 'w')
    msg.log('Resources utilization summary')
    for name in ['BRAM', 'DSP', 'FF', 'LUT', 'URAM']:
        # Check if resource is available
        if name not in used_resources:
            continue

        report_string = '{0:<9} {1:>6} used | {2:>6} available - {3:>6}% utilization'
        report_string_formatted = report_string.format(name, used_resources[name],
                                                       av_resources[name], util_resources[name])
        msg.log(report_string_formatted)
        resources_file.write(report_string_formatted + '\n')
    resources_file.close()


def gen_wns_report(out_path):
    wns = None
    tns = None
    num_fail = 0
    num_total = 0

    # Check Zynq boards path
    rpt_path = project_backend_path + '/' + args.name + '/' + args.name + '.runs/impl_1'
    rpt_path += '/' + args.name + '_design_wrapper_timing_summary_routed.rpt'
    if not os.path.exists(rpt_path):
        # Check Alpha Data path
        rpt_path = project_backend_path + '/' + args.name + '/' + args.name + '.runs/impl_1'
        rpt_path += '/' + args.name + '_design_top_timing_summary_routed.rpt'
        if not os.path.exists(rpt_path):
            msg.warning('Cannot find rpt file. Skipping WNS report')
            return

    with open(rpt_path, 'r') as rpt_file:
        rpt_data = rpt_file.readlines()

        # Search header line
        ids = [idx for idx in range(len(rpt_data) - 1) if (re.match(r'^\s+WNS\(ns\)\s+TNS\(ns\)\s+', rpt_data[idx]))]
        if len(ids) != 1:
            msg.warning('Cannot find WNS report table header. Skipping WNS report')
            return

        # Get information from 1st row
        elems = rpt_data[ids[0] + 2].split()
        wns = float(elems[0])
        tns = float(elems[1])
        num_fail = int(elems[2])
        num_total = int(elems[3])

    msg.log('Worst Negative Slack (WNS) summary')
    if wns >= 0.0:
        msg.success(str(num_fail) + ' endpoints of ' + str(num_total) + ' have negative slack (WNS: '
                    + str(wns) + ')')
    else:
        msg.warning(str(num_fail) + ' endpoints of ' + str(num_total) + ' have negative slack (WNS: '
                    + str(wns) + ', TNS: ' + str(tns) + ')')

    with open(out_path, 'w') as timing_file:
        timing_file.write('WNS ' + str(wns) + '\n')
        timing_file.write('TNS ' + str(tns) + '\n')
        timing_file.write('NUM_ENDPOINTS ' + str(num_total) + '\n')
        timing_file.write('NUM_FAIL_ENDPOINTS ' + str(num_fail))


def run_bitstream_step(project_args):
    global args
    global board
    global chip_part
    global ait_backend_path
    global project_backend_path

    args = project_args['args']
    board = project_args['board']
    project_path = project_args['path']

    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend
    project_step_path = project_backend_path + '/scripts/' + script_folder

    # Check if the requirements are met
    check_requirements()

    # Remove old directories used on the bitstream step
    shutil.rmtree(project_step_path, ignore_errors=True)

    # Create directories and copy necessary files for bitstream step
    shutil.copytree(ait_backend_path + '/scripts/' + script_folder, project_step_path, ignore=shutil.ignore_patterns('*.py*'))

    if os.path.isfile(project_backend_path + '/' + args.name + '/' + args.name + '.xpr'):
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

        os.environ['MYVIVADO'] = project_backend_path + '/scripts'

        p = subprocess.Popen('vivado -nojournal -nolog -notrace -mode batch -source '
                             + project_step_path + '/generate_bitstream.tcl',
                             cwd=project_backend_path + '/scripts/',
                             stdout=sys.stdout.subprocess,
                             stderr=sys.stdout.subprocess, shell=True)

        if args.verbose:
            for line in iter(p.stdout.readline, b''):
                sys.stdout.write(line.decode('utf-8'))

        retval = p.wait()
        del os.environ['MYVIVADO']
        if retval:
            msg.error('Bitstream generation failed', False)
        else:
            shutil.copy2(glob.glob(project_backend_path + '/' + args.name + '/' + args.name
                         + '.runs/impl_1/' + args.name + '*.bit')[0],
                         project_path + '/' + args.name + '.bit')
            shutil.copy2(glob.glob(project_backend_path + '/' + args.name + '/' + args.name
                         + '.runs/impl_1/' + args.name + '*.bin')[0],
                         project_path + '/' + args.name + '.bin')
            msg.success('Bitstream generated')
            gen_utilization_report(project_path + '/' + args.name + '.resources-impl.txt')
            gen_wns_report(project_path + '/' + args.name + '.timing-impl.txt')
    else:
        msg.error('No Vivado .xpr file exists for the current project. Bitstream generation failed')


STEP_FUNC = run_bitstream_step
