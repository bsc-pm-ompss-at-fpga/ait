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
import sys
import glob
import shutil
import subprocess
import distutils.spawn
import xml.etree.cElementTree as cET

from config import Accelerator, msg, ait_path, hwruntime_resources

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def check_requirements():
    if not distutils.spawn.find_executable('vivado_hls'):
        msg.error('vivado_hls not found. Please set PATH correctly')


def update_resource_utilization(acc):
    global available_resources
    global used_resources

    report_file = project_backend_path + '/HLS/' + acc.short_name + '/solution1/syn/report/' + acc.name + '_wrapper_csynth.xml'

    tree = cET.parse(report_file)
    root = tree.getroot()

    for resource in root.find('AreaEstimates').find('AvailableResources'):
        available_resources[resource.tag] = int(resource.text)

    if args.verbose_info:
        res_msg = 'Resources estimation for \'' + acc.short_name + '\': '
        res_msg += ', '.join(sorted(map(lambda r: r.tag + ' ' + r.text, list(root.find('AreaEstimates').find('Resources')))))
        msg.log(res_msg)

    for resource in root.find('AreaEstimates').find('Resources'):
        used_resources[resource.tag] = int(resource.text) * acc.num_instances + (int(used_resources[resource.tag]) if resource.tag in used_resources else 0)
        if used_resources[resource.tag] > available_resources[resource.tag] and not args.disable_utilization_check:
            msg.error(resource.tag + ' utilization over 100% (' + str(used_resources[resource.tag]) + '/' + str(available_resources[resource.tag]) + ')')


def synthesize_accelerator(acc):
    shutil.rmtree(project_backend_path + '/HLS/' + acc.short_name, ignore_errors=True)
    os.makedirs(project_backend_path + '/HLS/' + acc.short_name)

    shutil.copy2(acc.fullpath, project_backend_path + '/HLS/' + acc.short_name + '/' + acc.filename)

    accel_tcl_script = '# Script automatically generated by the Accelerator Integration Tool. Edit at your own risk.\n' \
                       + 'open_project ' + acc.short_name + '\n' \
                       + 'set_top ' + acc.name + '_wrapper\n' \
                       + 'add_files ' + acc.short_name + '/' + acc.filename + ' -cflags "-I' + os.getcwd() + '"\n' \
                       + 'open_solution "solution1"\n' \
                       + 'set_part {' + chip_part + '} -tool vivado\n' \
                       + 'create_clock -period ' + str(args.clock) + 'MHz -name default\n'

    if board.arch.bits == 64 or board.arch.type == 'fpga':
        accel_tcl_script += 'config_interface -m_axi_addr64\n'

    accel_tcl_script += 'csynth_design\n' \
                        + 'export_design -rtl verilog -format ip_catalog -vendor bsc -library ompss -display_name ' + acc.short_name + ' -taxonomy /BSC/OmpSs\n' \
                        + 'exit\n'

    accel_tcl_script_file = open(project_backend_path + '/HLS/' + acc.short_name + '/HLS_' + acc.short_name + '.tcl', 'w')
    accel_tcl_script_file.write(accel_tcl_script)
    accel_tcl_script_file.close()

    msg.info('Synthesizing \'' + acc.short_name + '\'')

    p = subprocess.Popen('vivado_hls ' + project_backend_path + '/HLS/' + acc.short_name
                         + '/HLS_' + acc.short_name + '.tcl -l ' + project_backend_path
                         + '/HLS/' + acc.short_name + '/HLS_' + acc.short_name + '.log',
                         cwd=project_backend_path + '/HLS',
                         stdout=sys.stdout.subprocess, stderr=sys.stdout.subprocess, shell=True)
    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        msg.error('Synthesis of \'' + acc.short_name + '\' failed')
        if not args.keep_files:
            shutil.rmtree(project_backend_path + '/HLS/' + acc.short_name, ignore_errors=True)
    else:
        msg.success('Finished synthesis of \'' + acc.short_name + '\'')

    update_resource_utilization(acc)


def run_HLS_step(project_vars):
    global args
    global board
    global chip_part
    global num_accels
    global ait_backend_path
    global project_backend_path
    global used_resources
    global available_resources

    args = project_vars['args']
    board = project_vars['board']
    num_accels = project_vars['num_accels']
    project_path = project_vars['path']
    accels = project_vars['accels']

    ait_backend_path = ait_path + '/backend/' + args.backend
    project_backend_path = project_path + '/' + args.backend
    project_step_path = project_backend_path + '/scripts/' + script_folder
    chip_part = board.chip_part + ('-' + board.es if (board.es and not args.ignore_eng_sample) else '')

    # Check if the requirements are met
    check_requirements()

    # Remove old directories used on the HLS step
    shutil.rmtree(project_step_path, ignore_errors=True)
    shutil.rmtree(project_backend_path + '/HLS', ignore_errors=True)

    # Create directories and copy necessary files for HLS step
    shutil.copytree(ait_backend_path + '/scripts/' + script_folder, project_step_path, ignore=shutil.ignore_patterns('*.py*'))
    os.makedirs(project_backend_path + '/HLS')

    if args.hwinst:
        acc_adap_instr = Accelerator(0, 'Adapter_instr', 1, 'Adapter_instr.cpp', ait_path + '/backend/' + args.backend + '/HLS/src/Adapter_instr.cpp')
        accels.append(acc_adap_instr)

    if args.hwruntime is not None:
        for hls_file in glob.glob(ait_path + '/backend/' + args.backend + '/HLS/src/hwruntime/' + args.hwruntime + '/*.cpp'):
            acc_file = os.path.basename(hls_file)
            acc_name = os.path.splitext(acc_file)[0]
            acc_aux = Accelerator(0, acc_name, 1, acc_file, hls_file)
            accels.append(acc_aux)
        if args.extended_hwruntime:
            for extended_hls_file in glob.glob(ait_path + '/backend/' + args.backend + '/HLS/src/hwruntime/' + args.hwruntime + '/extended/*.cpp'):
                acc_file = os.path.basename(extended_hls_file)
                acc_name = os.path.splitext(acc_file)[0]
                acc_aux = Accelerator(0, acc_name, 1, acc_file, extended_hls_file)
                accels.append(acc_aux)

    msg.info('Synthesizing ' + str(num_accels) + ' accelerator' + ('s' if num_accels > 1 else ''))

    available_resources = dict()
    if args.hwruntime in hwruntime_resources[args.backend]:
        used_resources = hwruntime_resources[args.backend][args.hwruntime][args.extended_hwruntime]
    else:
        used_resources = dict()

    for acc in range(0, num_accels):
        synthesize_accelerator(accels[acc])

    if len(accels) > num_accels:
        msg.info('Synthesizing ' + str(len(accels) - num_accels) + ' additional support IP' + ('s' if len(accels) - num_accels > 1 else ''))

        for acc in range(num_accels, len(accels)):
            synthesize_accelerator(accels[acc])

    resources_file = open(project_path + '/' + args.name + '.resources-hls.txt', 'w')
    msg.log('Resources estimation summary')
    for res_name, res_value in sorted(used_resources.items()):
        if res_name in available_resources:
            available = available_resources[res_name]
        else:
            available = 0
        if available > 0:
            utilization_percentage = str(round(float(res_value) / float(available) * 100, 2))
            report_string = '{0:<9} {1:>6} used | {2:>6} available - {3:>6}% utilization'
            report_string_formatted = report_string.format(res_name, res_value, available, utilization_percentage)
            msg.log(report_string_formatted)
            resources_file.write(report_string_formatted + '\n')
    resources_file.close()


STEP_FUNC = run_HLS_step
