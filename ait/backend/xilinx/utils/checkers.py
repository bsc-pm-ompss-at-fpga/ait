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

from ait.backend.xilinx.info import MIN_VITIS_HLS_VERSION, MIN_VIVADO_VERSION, MIN_PETALINUX_VERSION
from ait.frontend.utils import msg

vivado_version = None
vitis_hls_version = None
petalinux_version = None


def check_vivado():
    global vivado_version

    if shutil.which('vivado'):
        vivado_version = subprocess.run('vivado -version | head -n1 | sed "s/\(Vivado.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
        if vivado_version < MIN_VIVADO_VERSION:
            msg.error('Installed Vivado version ({}) not supported (>= {})'.format(vivado_version, MIN_VIVADO_VERSION))
    else:
        msg.error('vivado not found. Please set PATH correctly')

    return True


def check_vitis_hls():
    global vitis_hls_version

    if shutil.which('vitis_hls'):
        vitis_hls_version = subprocess.run('vitis_hls -version | head -n1 | sed "s/\(Vitis.\+v\)\(\([0-9]\|\.\)\+\).\+/\\2/"', shell=True, capture_output=True, encoding='utf-8').stdout.strip()
        if vitis_hls_version < MIN_VITIS_HLS_VERSION:
            msg.error('Installed Vitis HLS version ({}) not supported (>= {})'.format(vitis_hls_version, MIN_VITIS_HLS_VERSION))
    else:
        msg.error('vitis_hls not found. Please set PATH correctly')

    return True


def check_bootgen():
    if not shutil.which('bootgen'):
        msg.warning('bootgen not found. .bit.bin file will not be generated')
        return False

    return True


def check_petalinux():
    global petalinux_version

    petalinux_build_path = os.getenv('PETALINUX_BUILD', 'empty')
    if not os.path.exists(petalinux_build_path):
        msg.error('PETALINUX_BUILD (' + petalinux_build_path + ') variable not properly set')

    petalinux_version = os.getenv('PETALINUX_VER', '')

    if not shutil.which('petalinux-config'):
        msg.error('petalinux-config command not found. Please correctly source Petalinux settings.sh')
    elif not shutil.which('petalinux-build'):
        msg.error('petalinux-build command not found. Please correctly source Petalinux settings.sh')
    elif not shutil.which('petalinux-package'):
        msg.error('petalinux-package command not found. Please correctly source Petalinux settings.sh')
    elif petalinux_version < MIN_PETALINUX_VERSION:
        msg.error('Installed Petalinux version ({}) not supported (>= {})'.format(petalinux_version, MIN_PETALINUX_VERSION))

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
