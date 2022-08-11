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

import distutils.spawn
import os
import subprocess

from ait.backend.xilinx.info import MIN_VITIS_HLS_VERSION, MIN_VIVADO_HLS_VERSION, MIN_VIVADO_VERSION
from ait.frontend.utils import msg


def check_vivado():
    if distutils.spawn.find_executable('vivado'):
        vivado_version = str(subprocess.check_output(['vivado -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
        if vivado_version < MIN_VIVADO_VERSION:
            msg.error('Installed Vivado version ({}) not supported (>= {})'.format(vivado_version, MIN_VIVADO_VERSION))
    else:
        msg.error('vivado not found. Please set PATH correctly')

    return True


def check_hls_tool():
    if distutils.spawn.find_executable('vivado_hls'):
        check_vivado_hls()
        return 'vivado_hls'
    elif distutils.spawn.find_executable('vitis_hls'):
        check_vitis_hls()
        return 'vitis_hls'
    else:
        msg.error('No HLS tool found. Please set PATH correctly')


def check_vivado_hls():
    if distutils.spawn.find_executable('vivado_hls'):
        vivado_hls_version = str(subprocess.check_output(['vivado_hls -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
        if vivado_hls_version < MIN_VIVADO_HLS_VERSION:
            msg.error('Installed Vivado HLS version ({}) not supported (>= {})'.format(vivado_hls_version, MIN_VIVADO_HLS_VERSION))
    else:
        msg.warning('vivado_hls not found. Please set PATH correctly')

    return True


def check_vitis_hls():
    if distutils.spawn.find_executable('vitis_hls'):
        vitis_hls_version = str(subprocess.check_output(['vitis_hls -version | head -n1 | sed "s/\(Vitis.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"'], shell=True), 'utf-8').strip()
        if vitis_hls_version < MIN_VITIS_HLS_VERSION:
            msg.error('Installed Vitis HLS version ({}) not supported (>= {})'.format(vivado_hls_version, MIN_VITIS_HLS_VERSION))
    else:
        msg.error('vitis_hls not found. Please set PATH correctly')

    return True


def check_bootgen():
    if distutils.spawn.find_executable('bootgen'):
        msg.warning('bootgen not found. .bit.bin file will not be generated')
        return False

    return True


def check_petalinux(petalinux_build_path, petalinux_install_path):
    if (not os.path.exists(petalinux_build_path) or not os.path.exists(petalinux_install_path)):
        msg.error('PETALINUX_BUILD (' + (petalinux_build_path if petalinux_build_path else 'empty') + ') or PETALINUX_INSTALL ('
                  + (petalinux_install_path if petalinux_install_path else 'empty') + ') variables not properly set')
        msg.error('Generation of petalinux boot files failed')

    env = str(subprocess.Popen('bash -c "trap \'env\' exit; source ' + petalinux_install_path
                               + '/settings.sh > /dev/null 2>&1"', shell=True,
                               stdout=subprocess.PIPE).communicate()[0], 'utf-8').strip('\n')

    # NOTE: Only importing some environment variables as there may be complex functions/expansions that
    #       we do not need to handle here
    for line in env.split('\n'):
        splitted = line.split('=', 1)
        if splitted[0] == 'PATH' or splitted[0].find('PETALINUX') != -1:
            os.environ.update(dict([line.split('=', 1)]))

    if not distutils.spawn.find_executable('petalinux-config'):
        msg.error('petalinux commands not found. Please check PETALINUX_INSTALL environment variable')

    return True


def check_board_support(chip_part):
    check_vivado()

    tmp_dir = os.popen('mktemp -d --suffix=_ait').read().rstrip()

    os.mkdir(tmp_dir + '/scripts')

    os.system('echo "enable_beta_device ' + chip_part + '" >' + tmp_dir + '/scripts/vivado.tcl')
    os.system('echo "if {[llength [get_parts ' + chip_part + ']] == 0} {exit 1}" > ' + tmp_dir + '/scripts/ait_part_check.tcl')
    p = subprocess.Popen('vivado -init -nojournal -nolog -mode batch -source ' + tmp_dir + '/scripts/ait_part_check.tcl', shell=True, stdout=open(os.devnull, 'w'), cwd=tmp_dir + '/scripts')
    retval = p.wait()
    os.system('rm -rf ' + tmp_dir)
    if (int(retval) == 1):
        msg.error('Your current version of Vivado does not support part ' + chip_part)
