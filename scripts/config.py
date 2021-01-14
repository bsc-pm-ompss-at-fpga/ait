#!/usr/bin/env python3
#
# ------------------------------------------------------------------------ #
#     (C) Copyright 2017-2020 Barcelona Supercomputing Center              #
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
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    END = '\033[0m'


class Messages:
    def __getHeader(self):
        return strftime('[%Y-%m-%d %H:%M] ', localtime()) if self.__printtime else ''

    def __init__(self):
        self.name = False
        self.__printtime = False

    def setProjectName(self, name):
        self.name = name

    def setPrintTime(self, mode):
        self.__printtime = mode

    def error(self, msg, simple=False):
        if self.name and not simple:
            print(self.__getHeader() + Color.RED + msg + '. Check ' + self.name + '.ait.log for more information' + Color.END)
        else:
            print(self.__getHeader() + Color.RED + msg + Color.END)
        sys.exit(1)

    def info(self, msg):
        print(self.__getHeader() + Color.YELLOW + msg + Color.END)

    def warning(self, msg):
        print(self.__getHeader() + Color.YELLOW + msg + Color.END)

    def success(self, msg):
        print(self.__getHeader() + Color.GREEN + msg + Color.END)

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
BITINFO_VERSION = 6
VERSION_MAJOR = 3
VERSION_MINOR = 17
VERSION_COMMIT = 'unknown'
