#!/usr/bin/env python3
"""
Master Test Suite Aggregator: Roblox iOS Optimizer (RobloxOptimizer.dylib)
Aggregates all 4 Tiers:
  Tier 1: Feature Coverage (60 tests)
  Tier 2: Boundary & Corner Cases (63 tests)
  Tier 3: Cross-Feature Combinations (18 tests)
  Tier 4: Real-World Application Workloads (8 tests)
Total: 149 Automated Tests
"""

import sys
import unittest
from pathlib import Path

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

# Import all tier test modules
try:
    from tests.test_tier1_features import (
        TestFeature1RepoCleanliness,
        TestFeature2NoHardcodedOffsets,
        TestFeature3ConfigPresets,
        TestFeature4MetalTextureClamping,
        TestFeature5ResolutionScalingHook,
        TestFeature6FastFlagsGeneration,
        TestFeature7DraggableFABOverlay,
        TestFeature8ModalConfigPopup,
        TestFeature9ResolutionInputAndCleanExit,
        TestFeature10MakefileAndBuildScript,
        TestFeature11GitHubActionsWorkflow,
        TestFeature12GitRemoteAndBranch,
    )
    from tests.test_tier2_boundaries import (
        TestB1TextureClampingBoundaries,
        TestB2MipmapCalculationBoundaries,
        TestB3SafetyExclusionsBoundaries,
        TestB4ResolutionScaleBoundaries,
        TestB5FastFlagsSandboxPathsBoundaries,
        TestB6TargetFPSBoundaries,
        TestB7TouchPassthroughBoundaries,
        TestB8PresetModelCorruptionBoundaries,
    )
    from tests.test_tier3_pairwise import (
        TestPairwisePresetsAndFastFlags,
        TestPairwiseStateTransitions,
        TestPairwiseGraphicsPipeline,
        TestPairwiseUIAndInteraction,
        TestPairwiseBuildAndCI,
    )
    from tests.test_tier4_scenarios import (
        TestTier4RealWorldScenarios,
    )
except ImportError:
    from test_tier1_features import (
        TestFeature1RepoCleanliness,
        TestFeature2NoHardcodedOffsets,
        TestFeature3ConfigPresets,
        TestFeature4MetalTextureClamping,
        TestFeature5ResolutionScalingHook,
        TestFeature6FastFlagsGeneration,
        TestFeature7DraggableFABOverlay,
        TestFeature8ModalConfigPopup,
        TestFeature9ResolutionInputAndCleanExit,
        TestFeature10MakefileAndBuildScript,
        TestFeature11GitHubActionsWorkflow,
        TestFeature12GitRemoteAndBranch,
    )
    from test_tier2_boundaries import (
        TestB1TextureClampingBoundaries,
        TestB2MipmapCalculationBoundaries,
        TestB3SafetyExclusionsBoundaries,
        TestB4ResolutionScaleBoundaries,
        TestB5FastFlagsSandboxPathsBoundaries,
        TestB6TargetFPSBoundaries,
        TestB7TouchPassthroughBoundaries,
        TestB8PresetModelCorruptionBoundaries,
    )
    from test_tier3_pairwise import (
        TestPairwisePresetsAndFastFlags,
        TestPairwiseStateTransitions,
        TestPairwiseGraphicsPipeline,
        TestPairwiseUIAndInteraction,
        TestPairwiseBuildAndCI,
    )
    from test_tier4_scenarios import (
        TestTier4RealWorldScenarios,
    )


TIER_TEST_CLASSES = {
    1: [
        TestFeature1RepoCleanliness,
        TestFeature2NoHardcodedOffsets,
        TestFeature3ConfigPresets,
        TestFeature4MetalTextureClamping,
        TestFeature5ResolutionScalingHook,
        TestFeature6FastFlagsGeneration,
        TestFeature7DraggableFABOverlay,
        TestFeature8ModalConfigPopup,
        TestFeature9ResolutionInputAndCleanExit,
        TestFeature10MakefileAndBuildScript,
        TestFeature11GitHubActionsWorkflow,
        TestFeature12GitRemoteAndBranch,
    ],
    2: [
        TestB1TextureClampingBoundaries,
        TestB2MipmapCalculationBoundaries,
        TestB3SafetyExclusionsBoundaries,
        TestB4ResolutionScaleBoundaries,
        TestB5FastFlagsSandboxPathsBoundaries,
        TestB6TargetFPSBoundaries,
        TestB7TouchPassthroughBoundaries,
        TestB8PresetModelCorruptionBoundaries,
    ],
    3: [
        TestPairwisePresetsAndFastFlags,
        TestPairwiseStateTransitions,
        TestPairwiseGraphicsPipeline,
        TestPairwiseUIAndInteraction,
        TestPairwiseBuildAndCI,
    ],
    4: [
        TestTier4RealWorldScenarios,
    ],
}


def build_suite(tier: int = None) -> unittest.TestSuite:
    """Build a TestSuite for a specific tier (1..4) or all tiers if tier is None."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    if tier is not None:
        if tier not in TIER_TEST_CLASSES:
            raise ValueError(f"Invalid tier {tier}. Valid options are 1, 2, 3, 4.")
        classes = TIER_TEST_CLASSES[tier]
        for cls in classes:
            suite.addTests(loader.loadTestsFromTestCase(cls))
    else:
        for t in sorted(TIER_TEST_CLASSES.keys()):
            for cls in TIER_TEST_CLASSES[t]:
                suite.addTests(loader.loadTestsFromTestCase(cls))

    return suite


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(build_suite())
    exit(0 if result.wasSuccessful() else 1)
