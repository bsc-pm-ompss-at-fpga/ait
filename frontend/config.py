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
import sys
import math
import json

from time import localtime, strftime, time


class Accelerator:
    def __init__(self, acc_config):
        for attribute in acc_config:
            setattr(self, attribute, acc_config[attribute])


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

    def error(self, msg, start_time=None, simple=True):
        if self.name and not simple:
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + ' after ' + str(int(time() - start_time)) + 's. Check ' + self.name + '.ait.log for more information' + Color.END)
        else:
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + Color.END)
        sys.exit(1)

    def log(self, msg):
        print(self.__getHeader() + msg)


class utils:
    def decimalToHumanReadable(number, precision=0):
        log_number = math.log2(number)

        # Remove decimal point when 0 decimals of precision
        if precision == 0:
            precision -= 1

        # Using 15 decimals of precision to avoid rounding
        if log_number > 30:
            return "{:.15f}".format(number / 1024**3)[:-15 + precision] + 'G'
        elif log_number > 20:
            return "{:.15f}".format(number / 1024**2)[:-15 + precision] + 'M'
        elif log_number > 10:
            return "{:.15f}".format(number / 1024)[:-15 + precision] + 'K'
        else:
            return "{:.15f}".format(number)[:-15 + precision]

    def decimalFromHumanReadable(number):
        if str(number)[-1:] == "G":
            return int(float(number[:-1]) * 1024**3)
        elif str(number)[-1:] == "M":
            return int(float(number[:-1]) * 1024**2)
        elif str(number)[-1:] == "K":
            return int(float(number[:-1]) * 1024)
        else:
            return int(number)


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
MIN_WRAPPER_VERSION = 8
MIN_VIVADO_HLS_VERSION = "2018.3"
MIN_VIVADO_VERSION = "2018.3"
BITINFO_VERSION = 9
VERSION_MAJOR = 5
VERSION_MINOR = 10
VERSION_COMMIT = 'unknown'
