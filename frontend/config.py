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
import json

from time import localtime, strftime


class Accelerator:
    def __init__(self, accid, name, num_instances, filename, fullpath):
        self.id = accid  # < Type identifier
        self.name = name  # < Full name
        self.short_name = name.replace('_hls_automatic_mcxx', '')  # < Short name (name without mcxx suffix)
        self.num_instances = int(num_instances)  # < Number of instances
        self.filename = filename  # < Source file (basename with extension)
        self.fullpath = fullpath  # < Full source file path (with extension)


class Color:
    GREEN = '\033[0;32m'   # Success
    CYAN = '\033[0;36m'    # Info
    YELLOW = '\033[0;33m'  # Warning
    RED = '\033[1;31m'     # Error
    END = '\033[0m'


class Messages:
    def __getHeader(self):
        header = '[AIT] ' if self.verbose else ''
        header += strftime('[%Y-%m-%d %H:%M] ', localtime()) if self.__printtime else ''
        return header

    def __init__(self):
        self.name = False
        self.__printtime = False
        self.verbose = False

    def setProjectName(self, name):
        self.name = name

    def setPrintTime(self, mode):
        self.__printtime = mode

    def setVerbose(self, verbose):
        self.verbose = verbose

    def success(self, msg):
        print(self.__getHeader() + Color.GREEN + msg + Color.END)

    def info(self, msg):
        print(self.__getHeader() + Color.CYAN + 'INFO: ' + msg + Color.END)

    def warning(self, msg):
        print(self.__getHeader() + Color.YELLOW + 'WARNING: ' + msg + Color.END)

    def error(self, msg, simple=True):
        if self.name and not simple:
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + '. Check ' + self.name + '.ait.log for more information' + Color.END)
        else:
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + Color.END)
        sys.exit(1)

    def log(self, msg):
        print(self.__getHeader() + msg)


ait_path = os.path.normpath(os.path.dirname(os.path.realpath(__file__)) + '/..')

supported_boards = dict()
generation_steps = dict()
available_hwruntimes = dict()
hwruntime_resources = dict()
extended_hwruntime_resources = dict()
for i in next(os.walk(ait_path + '/backend'))[1]:
    supported_boards[i] = sorted(next(os.walk(ait_path + '/backend/' + i + '/board'))[1])
    generation_steps[i] = [step[3:] for step in sorted(next(os.walk(ait_path + '/backend/' + i + '/scripts'))[1])]
    available_hwruntimes[i] = sorted([hwruntime for hwruntime in next(os.walk(ait_path + '/backend/' + i + '/IPs/hwruntime'))[1]])
    hwruntime_resources[i] = dict()
    for j in next(os.walk(ait_path + '/backend/' + i + '/HLS/src/hwruntime'))[1]:
        if os.path.exists(ait_path + '/backend/' + i + '/HLS/src/hwruntime/' + j + '/' + j + '_resource_utilization.json'):
            hwruntime_resources[i][j] = dict()
            utilization_file = open(ait_path + '/backend/' + i + '/HLS/src/hwruntime/' + j + '/' + j + '_resource_utilization.json', 'r')
            hwruntime_resources[i][j][False] = json.loads(utilization_file.read())
            utilization_file.close()
            if os.path.exists(ait_path + '/backend/' + i + '/HLS/src/hwruntime/' + j + '/extended/extended_' + j + '_resource_utilization.json'):
                utilization_file = open(ait_path + '/backend/' + i + '/HLS/src/hwruntime/' + j + '/extended/extended_' + j + '_resource_utilization.json', 'r')
                hwruntime_resources[i][j][True] = json.loads(utilization_file.read())
                utilization_file.close()

msg = Messages()

MIN_PYTHON_VERSION = (3, 5)
MIN_OD_VERSION = (8, 23)
MIN_WRAPPER_VERSION = 8
MIN_VIVADO_HLS_VERSION = "2018.3"
MIN_VIVADO_VERSION = "2018.3"
BITINFO_VERSION = 8
VERSION_MAJOR = 5
VERSION_COMMIT = 'unknown'
VERSION_MINOR = 1
