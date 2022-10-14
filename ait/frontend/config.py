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

MIN_PYTHON_VERSION = (3, 7)
MIN_WRAPPER_VERSION = 8
BITINFO_VERSION = 9
VERSION_MAJOR = 6
VERSION_MINOR = 1
VERSION_PATCH = 0

# NOTE: The variable will be overwritten during installation, do not manually modify.
VERSION_COMMIT = ''

SHORT_VERSION = str('.'.join([str(VERSION_MAJOR), str(VERSION_MINOR), str(VERSION_PATCH)]))  # Short numerical version
LONG_VERSION = str(SHORT_VERSION + ' (' + ', '.join(filter(None, [VERSION_COMMIT, 'bitinfo: ' + str(BITINFO_VERSION)])) + ')')  # Long version including commit hash/release tag and bitinfo version
