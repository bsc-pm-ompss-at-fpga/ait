#!/usr/bin/env python3

import sys
import frontend
from frontend.config import MIN_PYTHON_VERSION

if sys.version_info < MIN_PYTHON_VERSION:
    sys.exit('Python %s.%s or later is required.\n' % MIN_PYTHON_VERSION)


if __name__ == '__main__':
    frontend.ait_main()
