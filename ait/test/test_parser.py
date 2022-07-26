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
import unittest
from unittest.mock import ANY, MagicMock, patch

from ait.frontend.parser import ArgParser


class Test_IP_caching(unittest.TestCase):
    def test_disabled_exists(self):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = True
        args.IP_cache_location = '/tmp'

        parser = ArgParser()
        parser.check_flow_args(args)

        self.assertTrue(True)  # Just check no errors are thrown

    def test_disabled_not_exists(self):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = True
        args.IP_cache_location = '/this-path-should-not-exist'

        parser = ArgParser()
        parser.check_flow_args(args)

        self.assertTrue(True)  # Just check no errors are thrown

    def test_enabled_exists(self):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = False
        args.IP_cache_location = '/tmp'

        parser = ArgParser()
        parser.check_flow_args(args)

        self.assertTrue(True)  # Just check no errors are thrown

    @patch('ait.frontend.utils.msg.error')
    def test_enabled_not_exists(self, msg_error):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = False
        args.IP_cache_location = '/this-path-should-not-exist'

        parser = ArgParser()
        parser.is_default = MagicMock(return_value=False)
        parser.check_flow_args(args)

        parser.is_default.assert_called_with('IP_cache_location', args.backend)
        msg_error.assert_called_with(ANY)

    def test_enabled_default(self):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = False
        args.IP_cache_location = '/tmp/ait-test-folder'

        # Check PRE conditions
        if (os.path.exists(args.IP_cache_location)):
            os.removedirs(args.IP_cache_location)
        self.assertFalse(os.path.exists(args.IP_cache_location))

        parser = ArgParser()
        parser.is_default = MagicMock(return_value=True)
        parser.check_flow_args(args)

        # Check POST conditions
        parser.is_default.assert_called_with('IP_cache_location', args.backend)
        self.assertTrue(os.path.exists(args.IP_cache_location))
        os.rmdir(args.IP_cache_location)

    def test_enabled_default_exists(self):
        # Create the args object which could contain any attribute
        args = type('', (), {})()
        args.from_step = 'HLS'
        args.to_step = 'HLS'
        args.backend = 'xilinx'
        args.disable_IP_caching = False
        args.IP_cache_location = '/tmp/ait-test-folder'

        # Check PRE conditions
        if (not os.path.exists(args.IP_cache_location)):
            os.makedirs(args.IP_cache_location)

        parser = ArgParser()
        parser.is_default = MagicMock(return_value=True)
        parser.check_flow_args(args)

        # Check POST conditions
        self.assertTrue(os.path.exists(args.IP_cache_location))
        os.rmdir(args.IP_cache_location)


if __name__ == '__main__':
    unittest.main()
