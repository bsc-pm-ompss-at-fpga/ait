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

import json
import os
import shutil
import subprocess
import sys
import xml.etree.cElementTree as cET

import ait.backend.xilinx.utils.checkers as checkers
from ait.frontend.utils import ait_path, msg


script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def update_resource_utilization(acc):
    global available_resources
    global used_resources

    report_file = project_backend_path + '/HLS/' + acc.name + '/solution1/syn/report/' + acc.name + '_wrapper_csynth.xml'

    tree = cET.parse(report_file)
    root = tree.getroot()

    for resource in root.find('AreaEstimates').find('AvailableResources'):
        available_resources[resource.tag] = int(resource.text)

    if args.verbose_info:
        res_msg = 'Resources estimation for \'' + acc.name + '\': '
        res_msg += ', '.join(sorted(map(lambda r: r.tag + ' ' + r.text, list(root.find('AreaEstimates').find('Resources')))))
        msg.log(res_msg)

    depleted_resources = False
    error_message = 'Resource utilization over 100%\nResources estimation summary\n'
    for resource in root.find('AreaEstimates').find('Resources'):
        used_resources[resource.tag] = int(resource.text) * acc.num_instances + (int(used_resources[resource.tag]) if resource.tag in used_resources else 0)
        if used_resources[resource.tag] > available_resources[resource.tag]:
            if available_resources[resource.tag] == 0:
                msg.error('The HLS code is using resources not available in the selected FPGA')
            utilization_percentage = str(round(float(used_resources[resource.tag]) / float(available_resources[resource.tag]) * 100, 2))
            report_string = '{0:<9} {1:>7} used | {2:>7} available - {3:>6}% utilization\n'
            report_string_formatted = report_string.format(resource.tag, used_resources[resource.tag], available_resources[resource.tag], utilization_percentage)
            error_message += report_string_formatted
            depleted_resources = True

    if not args.disable_utilization_check and depleted_resources:
        msg.error(error_message.rstrip())


def synthesize_accelerator(acc):
    shutil.rmtree(project_backend_path + '/HLS/' + acc.name, ignore_errors=True)
    os.makedirs(project_backend_path + '/HLS/' + acc.name)

    shutil.copy2(acc.full_path, project_backend_path + '/HLS/' + acc.name + '/' + acc.filename)

    acc_tcl_script = '# Script automatically generated by the Accelerator Integration Tool. Edit at your own risk.\n' \
                     + 'open_project ' + acc.name + '\n' \
                     + 'set_top ' + acc.name + '_wrapper\n' \
                     + 'add_files ' + acc.name + '/' + acc.filename + ' -cflags "-I' + os.getcwd() + '"\n' \
                     + 'open_solution "solution1"\n' \
                     + 'set_part {' + chip_part + '} -tool vivado\n' \
                     + 'create_clock -period ' + str(args.clock) + 'MHz -name default\n' \
                     + 'config_rtl -reset control -reset_level low -reset_async\n'

    if board.arch.device == 'zynqmp' or board.arch.device == 'alveo':
        acc_tcl_script += 'config_interface -m_axi_addr64\n'

    acc_tcl_script += 'csynth_design\n' \
                      + 'export_design -rtl verilog -format ip_catalog -vendor bsc -library ompss -display_name ' + acc.name + ' -taxonomy /BSC/OmpSs\n' \
                      + 'exit\n'

    acc_tcl_script_file = open(project_backend_path + '/HLS/' + acc.name + '/HLS_' + acc.name + '.tcl', 'w')
    acc_tcl_script_file.write(acc_tcl_script)
    acc_tcl_script_file.close()

    msg.info('Synthesizing \'' + acc.name + '\'')

    p = subprocess.Popen('vivado_hls ' + project_backend_path + '/HLS/' + acc.name
                         + '/HLS_' + acc.name + '.tcl -l ' + project_backend_path
                         + '/HLS/' + acc.name + '/HLS_' + acc.name + '.log',
                         cwd=project_backend_path + '/HLS',
                         stdout=sys.stdout.subprocess, stderr=sys.stdout.subprocess, shell=True)
    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        if not args.keep_files:
            shutil.rmtree(project_backend_path + '/HLS/' + acc.name, ignore_errors=True)
        msg.error('Synthesis of \'' + acc.name + '\' failed', start_time, False)
    else:
        msg.success('Finished synthesis of \'' + acc.name + '\'')

    update_resource_utilization(acc)


def run_step(project_args):
    global args
    global board
    global chip_part
    global start_time
    global num_accs
    global ait_backend_path
    global project_backend_path
    global used_resources
    global available_resources

    args = project_args['args']
    board = project_args['board']
    start_time = project_args['start_time']
    num_accs = project_args['num_accs']
    project_path = project_args['path']
    accs = project_args['accs']

    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')
    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend

    # Check if Vivado HLS requirements are met
    checkers.check_vivado_hls()

    # Remove old directories used on the HLS step
    shutil.rmtree(project_backend_path + '/HLS', ignore_errors=True)
    os.makedirs(project_backend_path + '/HLS')

    msg.info('Synthesizing ' + str(num_accs) + ' accelerator' + ('s' if num_accs > 1 else ''))

    # Load used resources by hwruntime
    used_resources = json.load(open(ait_backend_path + '/IPs/hwruntime/' + args.hwruntime + '/' + args.hwruntime + '_resource_utilization.json'))
    available_resources = dict()

    for acc in range(0, num_accs):
        synthesize_accelerator(accs[acc])

    if len(accs) > num_accs:
        msg.info('Synthesizing ' + str(len(accs) - num_accs) + ' additional auxiliary IP' + ('s' if len(accs) - num_accs > 1 else ''))

        for acc in range(num_accs, len(accs)):
            synthesize_accelerator(accs[acc])

    resources_file = open(project_path + '/' + args.name + '.resources-hls.txt', 'w')
    msg.log('Resources estimation summary')
    for res_name, res_value in sorted(used_resources.items()):
        if res_name in available_resources:
            available = available_resources[res_name]
        else:
            available = 0
        if available > 0:
            utilization_percentage = str(round(float(res_value) / float(available) * 100, 2))
            report_string = '{0:<9} {1:>7} used | {2:>7} available - {3:>6}% utilization'
            report_string_formatted = report_string.format(res_name, res_value, available, utilization_percentage)
            msg.log(report_string_formatted)
            resources_file.write(report_string_formatted + '\n')
    resources_file.close()
