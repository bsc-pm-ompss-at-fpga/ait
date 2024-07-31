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

NAME = 'xilinx'

MIN_VITIS_HLS_VERSION = '2021.1'
MIN_VIVADO_VERSION = '2021.1'
MIN_PETALINUX_VERSION = '2021.1'


def get_supported_boards():
    boards = sorted(next(os.walk(os.path.dirname(__file__) + '/board'))[1])
    boards.remove('common')
    return boards


info = dict()
info['boards'] = get_supported_boards()
info['steps'] = ['HLS', 'design', 'synthesis', 'implementation', 'bitstream', 'boot']
info['initial_step'] = 'HLS'
info['final_step'] = 'bitstream'
