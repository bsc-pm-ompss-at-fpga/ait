import importlib
import json
import os
import shutil

import ait.backend.xilinx.utils.checkers as checkers
import ait.backend.xilinx.utils.parser as parser
from ait.frontend.utils import ait_path, msg


class JSONObject:
    def __init__(self, dict):
        vars(self).update(dict)


def load(args):

    project_path = os.path.normpath(os.path.realpath(args.dir + '/' + args.name + '_ait'))
    project_backend_path = project_path + '/' + args.backend
    ait_backend_path = ait_path + '/backend/' + args.backend

    board = json.load(open(ait_path + '/backend/' + args.backend + '/board/' + args.board + '/basic_info.json'), object_hook=JSONObject)

    # Check backend-related board arguments
    parser.parser.check_board_args(args, board)

    # Check for backend support for the given board
    if not args.disable_board_support_check:
        if args.verbose_info:
            msg.log('Checking vendor support for selected board')

        chip_part = board.chip_part + ('-' + board.es if board.es and not args.ignore_eng_sample else '')

        checkers.check_board_support(chip_part)

    shutil.rmtree(project_backend_path + '/tcl', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/tcl', project_backend_path + '/tcl')

    shutil.rmtree(project_backend_path + '/IPs', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/IPs', project_backend_path + '/IPs')

    shutil.rmtree(project_backend_path + '/board', ignore_errors=True)
    shutil.copytree(ait_backend_path + '/board/' + args.board, project_backend_path + '/board/' + args.board)

    steps = importlib.import_module('ait.backend.xilinx.steps')

    return steps, board
