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
    global petalinux_install_path

    start_time = project_args['start_time']
    project_path = project_args['path']
    board = project_args['board']
    args = project_args['args']

    project_backend_path = project_path + '/' + args.backend

    petalinux_build_path = os.path.realpath(os.getenv('PETALINUX_BUILD')) if os.getenv('PETALINUX_BUILD') else ''
    petalinux_install_path = os.path.realpath(os.getenv('PETALINUX_INSTALL')) if os.getenv('PETALINUX_INSTALL') else ''

    checkers.check_petalinux(petalinux_build_path, petalinux_install_path)

    path_hdf = project_backend_path + '/' + args.name + '/' + args.name + '.sdk/'

    if os.path.exists(petalinux_install_path + '/.version-history'):
        # Seems to be petalinux 2019.1 or later (may match other untested versions)
        command = 'petalinux-config --silentconfig --get-hw-description=' + path_hdf
    else:
        # Seems to be petalinux 2018.3 or previous (may match other untested versions)
        command = 'petalinux-config --oldconfig --get-hw-description=' + path_hdf

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

    if os.path.exists(petalinux_build_path + '/subsystems/linux/configs/device-tree/'):
        # Seems to be petalinux 2016.3 (may match other untested versions)
        if args.verbose_info:
            msg.log('Fixing devicetree (2016.3 mode)')

        petalinux_build_dts_path = petalinux_build_path + '/subsystems/linux/configs/device-tree/'
        shutil.copy2(project_backend_path + '/' + args.name + '/pl_ompss_at_fpga.dtsi', petalinux_build_dts_path)

        content_dtsi = None
        with open(petalinux_build_dts_path + '/system-conf.dtsi', 'r') as file:
            content_dtsi = file.read().splitlines()

        line = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find('/include/ "pl.dtsi"') != -1]
        content_dtsi.insert(line[0] + 1, '/include/ \"pl_ompss_at_fpga.dtsi\"')

        board_dtsi_fix_file = project_backend_path + '/board/' + board.name + '/' + board.name + '_boot.dtsi'
        if os.path.exists(board_dtsi_fix_file):
            shutil.copy2(board_dtsi_fix_file, petalinux_build_dts_path)
            content_dtsi.insert(line[0] + 2, '/include/ \"' + board.name + '_boot.dtsi\"')

        with open(petalinux_build_dts_path + '/system-conf.dtsi', 'w') as file:
            file.write('\n'.join(content_dtsi))

        command = 'petalinux-build -c bootloader -x mrproper'
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
    elif os.path.exists(petalinux_build_path + '/project-spec/meta-user/recipes-bsp/device-tree/files/'):
        # Seems to be petalinux 2018.3 or 2019.1 (may match other untested versions)
        if args.verbose_info:
            msg.log('Fixing devicetree (2018.3 mode)')

        petalinux_build_dts_path = petalinux_build_path + '/project-spec/meta-user/recipes-bsp/device-tree/files/'

        content_dtsi = None
        with open(petalinux_build_dts_path + '/system-user.dtsi', 'r') as file:
            content_dtsi = file.read().splitlines()

        # Remove old includes to pl_bsc.dtsi and insert the new one
        line = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find('pl_bsc.dtsi') != -1]
        if len(line) == 1:
            content_dtsi.pop(line[0])
        elif len(line) > 1:
            msg.error('Uncontrolled path in run_boot_step: more than 1 line of system-user.dtsi contains pl_bsc.dtsi')

        # Remove old includes to pl_ompss_at_fpga.dtsi and insert the new one
        line = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find('pl_ompss_at_fpga.dtsi') != -1]
        if len(line) == 1:
            content_dtsi.pop(line[0])
        elif len(line) > 1:
            msg.error('Uncontrolled path in run_boot_step: more than 1 line of system-user.dtsi contains pl_ompss_at_fpga.dtsi')

        line = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find('pl_ompss_at_fpga.dtsi') != -1]
        content_dtsi.insert(len(content_dtsi), '/include/ \"' + project_backend_path + '/' + args.name + '/pl_ompss_at_fpga.dtsi' + '\"')

        # Remove old includes to <board>_boot.dtsi and insert the new one
        line = [idx for idx in range(len(content_dtsi)) if content_dtsi[idx].find(board.name + '_boot.dtsi') != -1]
        if len(line) == 1:
            content_dtsi.pop(line[0])
        elif len(line) > 1:
            msg.error('Uncontrolled path in run_boot_step: more than 1 line of system-user.dtsi contains <board>_bsc.dtsi')

        board_dtsi_fix_file = project_backend_path + '/board/' + board.name + '/' + board.name + '_boot.dtsi'
        if os.path.exists(board_dtsi_fix_file):
            shutil.copy2(board_dtsi_fix_file, petalinux_build_dts_path)
            content_dtsi.insert(len(content_dtsi), '/include/ \"' + board_dtsi_fix_file + '\"')

        with open(petalinux_build_dts_path + '/system-user.dtsi', 'w') as file:
            file.write('\n'.join(content_dtsi))
    else:
        msg.warning('Devicetree fix failed. Petalinux version cannot be determined. Continuing anyway...')

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
        msg.error('Generation of petalinux boot files failed', start_time, False)

    path_bit = project_path + '/' + args.name + '.bit'
    command = 'petalinux-package --force --boot --fsbl ./images/linux/*_fsbl.elf'
    command += ' --fpga ' + path_bit + ' --u-boot ./images/linux/u-boot.elf'
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
        shutil.copy2(petalinux_build_path + '/images/linux/BOOT.BIN', project_path)
        shutil.copy2(petalinux_build_path + '/images/linux/image.ub', project_path)
        msg.success('Petalinux boot files generated')
