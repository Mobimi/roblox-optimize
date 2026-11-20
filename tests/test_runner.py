#!/usr/bin/env python3
"""
Automated 4-Tier Test Runner: Roblox iOS Optimizer (RobloxOptimizer.dylib)

Usage:
    python tests/test_runner.py                 # Run all 4 tiers (149 tests)
    python tests/test_runner.py --tier 1        # Run Tier 1 only (Feature Coverage)
    python tests/test_runner.py --tier 2        # Run Tier 2 only (Boundaries & Corners)
    python tests/test_runner.py --tier 3        # Run Tier 3 only (Pairwise Combinations)
    python tests/test_runner.py --tier 4        # Run Tier 4 only (Real-World Scenarios)
    python tests/test_runner.py --verbose       # Show verbose test names
    python tests/test_runner.py --json          # Output summary as JSON
"""

import sys
import os
import time
import argparse
import unittest
import json
from pathlib import Path

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from tests.test_suite import build_suite, TIER_TEST_CLASSES

TIER_NAMES = {
    1: "Tier 1: Feature Coverage (12 Features)",
    2: "Tier 2: Boundary & Corner Cases",
    3: "Tier 3: Cross-Feature Combinations (Pairwise)",
    4: "Tier 4: Real-World Application Workload Scenarios",
}


def run_tier(tier_num: int, verbose: bool = False):
    """Execute a single tier and return test results."""
    suite = build_suite(tier=tier_num)
    stream_out = sys.stdout if verbose else open(os.devnull, "w")
    runner = unittest.TextTestRunner(stream=stream_out, verbosity=2 if verbose else 0)

    start_time = time.perf_counter()
    result = runner.run(suite)
    elapsed = time.perf_counter() - start_time

    if not verbose:
        stream_out.close()

    return {
        "tier": tier_num,
        "name": TIER_NAMES[tier_num],
        "total": result.testsRun,
        "passed": result.testsRun - len(result.failures) - len(result.errors),
        "failures": len(result.failures),
        "errors": len(result.errors),
        "elapsed": elapsed,
        "success": result.wasSuccessful(),
        "failure_details": [str(f[1]) for f in result.failures],
        "error_details": [str(e[1]) for e in result.errors],
    }


def main():
    parser = argparse.ArgumentParser(description="Roblox iOS Optimizer 4-Tier Test Runner")
    parser.add_argument("--tier", type=int, choices=[1, 2, 3, 4], help="Run a specific test tier (1..4)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose test execution output")
    parser.add_argument("--json", action="store_true", help="Output summary in JSON format")
    args = parser.parse_args()

    tiers_to_run = [args.tier] if args.tier else [1, 2, 3, 4]

    if not args.json:
        print("=" * 76)
        print("   ROBLOX IOS OPTIMIZER DYLIB — 4-TIER E2E TEST RUNNER")
        print("=" * 76)
        print(f"Target Working Directory: {REPO_ROOT}")
        print(f"Executing Tiers: {tiers_to_run}")
        print("-" * 76)

    tier_results = []
    grand_total = 0
    grand_passed = 0
    grand_failed = 0
    grand_errors = 0
    total_time = 0.0

    for t in tiers_to_run:
        res = run_tier(t, verbose=args.verbose)
        tier_results.append(res)
        grand_total += res["total"]
        grand_passed += res["passed"]
        grand_failed += res["failures"]
        grand_errors += res["errors"]
        total_time += res["elapsed"]

        if not args.json and not args.verbose:
            status = "PASS" if res["success"] else "FAIL"
            print(f"[{status}] {res['name']:<52} {res['passed']}/{res['total']} passed ({res['elapsed']:.3f}s)")

    all_successful = (grand_failed == 0 and grand_errors == 0)

    if args.json:
        output_data = {
            "all_passed": all_successful,
            "total_tests": grand_total,
            "passed": grand_passed,
            "failures": grand_failed,
            "errors": grand_errors,
            "total_time_seconds": total_time,
            "tiers": tier_results,
        }
        print(json.dumps(output_data, indent=2))
    else:
        print("-" * 76)
        print(f"OVERALL SUMMARY: {grand_passed}/{grand_total} Tests Passed in {total_time:.3f}s")
        if all_successful:
            print(">>> VERDICT: ALL TESTS PASSED [100% SUCCESS RATE] <<<")
        else:
            print(f">>> VERDICT: FAILED ({grand_failed} failures, {grand_errors} errors) <<<")
            for r in tier_results:
                if not r["success"]:
                    print(f"\nFailures in {r['name']}:")
                    for fd in r["failure_details"]:
                        print(fd)
                    for ed in r["error_details"]:
                        print(ed)
        print("=" * 76)

    return 0 if all_successful else 1


if __name__ == "__main__":
    sys.exit(main())
