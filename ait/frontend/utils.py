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
import math
import os
import re
import subprocess
import sys
import time

import setuptools


class JSONDottedDict(dict):
    def __getattr__(*args):
        val = dict.get(*args)
        return JSONDottedDict(val) if type(val) is dict else val
    __setattr__ = dict.__setitem__
    __delattr__ = dict.__delitem__


class Color:
    GREEN = '\033[0;32m'   # Success
    CYAN = '\033[0;36m'    # Info
    YELLOW = '\033[0;33m'  # Warning
    RED = '\033[1;31m'     # Error
    END = '\033[0m'


class Messages:
    def __getHeader(self):
        header = '[AIT] ' if self.verbose else ''
        header += time.strftime('[%Y-%m-%d %H:%M] ', time.localtime()) if self.__printtime else ''
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
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + ' after ' + secondsToHumanReadable(int(time.time() - start_time)) + '. Check ' + self.name + '.ait.log for more information' + Color.END)
        else:
            print(self.__getHeader() + Color.RED + 'ERROR: ' + msg + Color.END)
        sys.exit(1)

    def log(self, msg):
        print(self.__getHeader() + msg)


def decimalToHumanReadable(number, precision=0):
    log_number = math.log2(number)

    # Remove decimal point when 0 decimals of precision
    if precision == 0:
        precision -= 1

    # Using 15 decimals of precision to avoid rounding
    if log_number > 30:
        return '{:.15f}'.format(number / 1024**3)[:-15 + precision] + 'G'
    elif log_number > 20:
        return '{:.15f}'.format(number / 1024**2)[:-15 + precision] + 'M'
    elif log_number > 10:
        return '{:.15f}'.format(number / 1024)[:-15 + precision] + 'K'
    else:
        return '{:.15f}'.format(number)[:-15 + precision]


def decimalFromHumanReadable(number):
    if re.match(r'[a-zA-Z]', number[-1:]):
        if (number[:-1]).replace('.', '', 1).isdigit() and float(number[:-1]) > 0:
            if number[-1:] == "G":
                return int(float(number[:-1]) * 1024**3)
            elif number[-1:] == "M":
                return int(float(number[:-1]) * 1024**2)
            elif number[-1:] == "K":
                return int(float(number[:-1]) * 1024)
            else:
                raise TypeError('invalid unit')
        else:
            raise ValueError('invalid value')

    else:
        if number.isdigit() and int(number) > 0:
            return int(number)
        else:
            raise ValueError('invalid value')


def secondsToHumanReadable(seconds):
    TIME_DURATION_UNITS = (
        ('week', 60 * 60 * 24 * 7),
        ('day', 60 * 60 * 24),
        ('hour', 60 * 60),
        ('min', 60),
        ('sec', 1)
    )

    if seconds == 0:
        return 'inf'
    parts = []
    for unit, div in TIME_DURATION_UNITS:
        amount, seconds = divmod(int(seconds), div)
        if amount > 0:
            parts.append('{} {}{}'.format(amount, unit, '' if amount == 1 else 's'))
    return ', '.join(parts)


def getNumJobs(mem_per_job):
    available_mem = int(subprocess.run("free -b | grep 'Mem:' | awk {'print $7'}", shell=True, capture_output=True, encoding='utf-8').stdout.strip())
    nprocs = int(subprocess.run('nproc', capture_output=True, encoding='utf-8').stdout.strip())

    return max(1, min(int(available_mem / mem_per_job), nprocs))


def json2tcl(data, name, base_level=0, indent_level=None):

    if indent_level is None:
        indent_level = base_level

    def indentString(level):
        string = ''
        for lvl in range(level):
            string += '\t'
        return string

    string = ''
    if isinstance(data, list):
        string += ' '
        for elem in data:
            string += json2tcl(elem, name, base_level, indent_level + 1)
            string += ' '
    elif isinstance(data, dict):
        for key in data.keys():
            string += indentString(indent_level)
            if indent_level == base_level:
                string += 'dict set {} '.format(name)
            string += '"{}" '.format(key)
            if isinstance(data[key], dict):
                string += '{\n'
            elif isinstance(data[key], list):
                string += '{'
            string += json2tcl(data[key], name, base_level, indent_level + 1)
            if isinstance(data[key], dict):
                string += indentString(indent_level)
                string += '}'
            elif isinstance(data[key], list):
                string += '}'
            string += '\n'
    else:
        string += '{{{}}}'.format(data)
    return string


ait_path = os.path.normpath(os.path.dirname(os.path.realpath(__file__)) + '/..')

backends = dict()
for backend_subpkg in setuptools.find_packages(where=ait_path + '/backend', exclude=['*.*']):
    backend = importlib.import_module('ait.backend.%s.info' % (backend_subpkg))
    backends[backend.NAME] = backend.info

msg = Messages()
