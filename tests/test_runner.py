#!/usr/bin/env python3
"""
Test Runner entry point for CI and local verification.
"""

import sys
from test_suite import run_all

if __name__ == "__main__":
    try:
        run_all()
        sys.exit(0)
    except Exception as e:
        print(f"Error during test execution: {e}")
        sys.exit(1)
