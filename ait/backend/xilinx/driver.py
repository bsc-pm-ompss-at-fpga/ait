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
