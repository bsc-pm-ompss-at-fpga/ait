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

import importlib
import json

import ait.backend.xilinx.utils.checkers as checkers
import ait.backend.xilinx.utils.parser as parser
from ait.frontend.utils import ait_path, msg


class JSONObject:
    def __init__(self, dict):
        vars(self).update(dict)


def load(args):
    board = json.load(open(ait_path + '/backend/' + args.backend + '/board/' + args.board + '/basic_info.json'), object_hook=JSONObject)

    # Check backend-related board arguments
    parser.parser.check_board_args(args, board)

    # Check for backend support for the given board
    if not args.disable_board_support_check:
        if args.verbose_info:
            msg.log('Checking vendor support for selected board')
        chip_part = board.chip_part + ('-' + board.es if board.es and not args.ignore_eng_sample else '')
        checkers.check_board_support(chip_part)

    # Import backend steps
    steps = importlib.import_module('ait.backend.xilinx.steps')

    return steps, board
