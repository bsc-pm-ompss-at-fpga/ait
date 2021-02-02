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
import subprocess
import distutils.spawn

from config import msg


def check_requirements():
    if not distutils.spawn.find_executable('vivado'):
        msg.error('vivado not found. Please set PATH correctly')


def check_board_support(chip_part):

    check_requirements()

    tmp_dir = os.popen('mktemp -d --suffix=_ait').read().rstrip()
    os.environ['MYVIVADO'] = tmp_dir

    os.mkdir(tmp_dir + '/scripts')

    os.system('echo "enable_beta_device ' + chip_part + '" >' + tmp_dir + '/scripts/Vivado_init.tcl')
    os.system('echo "if {[llength [get_parts ' + chip_part + ']] == 0} {exit 1}" > ' + tmp_dir + '/scripts/ait_part_check.tcl')
    p = subprocess.Popen('vivado -nojournal -nolog -mode batch -source ' + tmp_dir + '/scripts/ait_part_check.tcl', shell=True, stdout=open(os.devnull, 'w'), cwd=tmp_dir + '/scripts')
    retval = p.wait()
    os.system('rm -rf ' + tmp_dir)
    del os.environ['MYVIVADO']
    if (int(retval) == 1):
        msg.error('Your current version of Vivado does not support part ' + chip_part)
