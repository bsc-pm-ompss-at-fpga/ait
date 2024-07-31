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

import os
import shutil
import subprocess
import sys

import ait.backend.xilinx.utils.checkers as checkers
from ait.frontend.utils import msg

script_folder = os.path.basename(os.path.dirname(os.path.realpath(__file__)))


def run_step(project_args):
    global start_time
    global project_backend_path
    global petalinux_build_path

    start_time = project_args['start_time']
    project_path = project_args['path']
    board = project_args['board']
    args = project_args['args']

    project_backend_path = project_path + '/' + args.backend

    # Check if Petalinux requirements are met
    checkers.check_petalinux()

    xsa_path = project_backend_path + '/' + args.name + '/' + args.name + '.sdk/'
    petalinux_build_path = os.path.realpath(os.getenv('PETALINUX_BUILD'))

    project_boot_path = project_path + '/boot'
    shutil.rmtree(project_boot_path, ignore_errors=True)
    os.mkdir(project_boot_path)

    command = 'petalinux-config --silentconfig --get-hw-description=' + xsa_path

    if args.verbose_info:
        msg.log('> ' + command)
    p = subprocess.Popen(command, stdout=sys.stdout.subprocess, stderr=sys.stdout.subprocess,
                         cwd=petalinux_build_path, shell=True)

    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        msg.error('Configuration of petalinux project failed', start_time, False)

    petalinux_overlay_config = subprocess.run('grep -q CONFIG_SUBSYSTEM_DTB_OVERLAY=y {}/project-spec/configs/config'.format(petalinux_build_path), shell=True).returncode == 0

    if petalinux_overlay_config:
        if args.verbose_info:
            msg.log('Fixing devicetree (overlay mode)')
        project_dtsi_overlay_file = project_backend_path + '/board/' + board.name + '/boot/overlay_ompss_at_fpga.dtsi'
        petalinux_build_dtsi_overlay_file = petalinux_build_path + '/components/plnx_workspace/device-tree/device-tree/pl-custom.dtsi'
        shutil.copy2(project_dtsi_overlay_file, petalinux_build_dtsi_overlay_file)
    else:
        if args.verbose_info:
            msg.log('Fixing devicetree')
        petalinux_build_dts_path = petalinux_build_path + '/project-spec/meta-user/recipes-bsp/device-tree/files/'

        content_dtsi = None
        with open(petalinux_build_dts_path + '/system-user.dtsi', 'r') as file:
            content_dtsi = file.read().splitlines()

        # Remove old includes to pl_ompss_at_fpga.dtsi and insert the new one
        lines = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find('pl_ompss_at_fpga.dtsi') != -1]
        for line in lines:
            content_dtsi.pop(line)

        project_dtsi_file = project_backend_path + '/board/' + board.name + '/boot/pl_ompss_at_fpga.dtsi'
        if os.path.exists(project_dtsi_file):
            shutil.copy2(project_backend_path + '/board/' + board.name + '/boot/pl_ompss_at_fpga.dtsi', petalinux_build_dts_path)
            content_dtsi.insert(len(content_dtsi), '/include/ \"pl_ompss_at_fpga.dtsi\"')

        # Remove old includes to <board>_boot.dtsi and insert the new one
        lines = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find(board.name + '_boot.dtsi') != -1]
        for line in lines:
            content_dtsi.pop(line)

        project_dtsi_fix_file = project_backend_path + '/board/' + board.name + '/boot/' + board.name + '_boot.dtsi'
        if os.path.exists(project_dtsi_fix_file):
            shutil.copy2(project_dtsi_fix_file, petalinux_build_dts_path)
            content_dtsi.insert(len(content_dtsi), '/include/ \"' + board.name + '_boot.dtsi' + '\"')

        with open(petalinux_build_dts_path + '/system-user.dtsi', 'w') as file:
            file.write('\n'.join(content_dtsi))

    command = 'petalinux-build'
    if args.verbose_info:
        msg.log('> ' + command)
    p = subprocess.Popen(command, stdout=sys.stdout.subprocess, stderr=sys.stdout.subprocess,
                         cwd=petalinux_build_path, shell=True)
    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        msg.error('Petalinux project build failed', start_time, False)

    bitstream_path = project_path + '/' + args.name + '.bit'
    command = 'petalinux-package --force --boot --fsbl ./images/linux/*_fsbl.elf'
    command += ' --fpga ' + bitstream_path + ' --u-boot ./images/linux/u-boot.elf'
    if args.verbose_info:
        msg.log('> ' + command)
    p = subprocess.Popen(command, stdout=sys.stdout.subprocess, stderr=sys.stdout.subprocess,
                         cwd=petalinux_build_path, shell=True)
    if args.verbose:
        for line in iter(p.stdout.readline, b''):
            sys.stdout.write(line.decode('utf-8'))

    retval = p.wait()
    if retval:
        msg.error('Generation of petalinux boot files failed', start_time, False)
    else:
        shutil.copy2(petalinux_build_path + '/images/linux/BOOT.BIN', project_boot_path)
        shutil.copy2(petalinux_build_path + '/images/linux/image.ub', project_boot_path)
        shutil.copy2(petalinux_build_path + '/images/linux/boot.scr', project_boot_path)
        if petalinux_overlay_config:
            shutil.copy2(petalinux_build_path + '/images/linux/pl.dtbo', project_boot_path)
        msg.success('Petalinux boot files generated')
