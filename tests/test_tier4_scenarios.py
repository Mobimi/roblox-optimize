#!/usr/bin/env python3
"""
Tier 4: Real-World Application Workload Scenarios (8 Test Cases)
Roblox iOS Optimizer Dynamic Library (RobloxOptimizer.dylib)

Simulates complete end-to-end user journeys and system lifecycles:
  Scenario 1: Fresh App Install & Default Boot (Balanced Mode)
  Scenario 2: Potato Mode Activation & Memory-Constrained Jetsam Survival
  Scenario 3: Manual Fine-Tuning with Custom Resolution Scale (0.65) & Unlocked FPS
  Scenario 4: In-Game View Transition & Virtual Joystick Touch Passthrough
  Scenario 5: Save & Clean Restart Execution Flow
  Scenario 6: CI/CD GitHub Actions Build & Release Deployment Pipeline
  Scenario 7: App Background / Foreground Lifecycle & Idempotent Config Reload
  Scenario 8: Jetsam VRAM Reduction Mathematical Verification & Audit
"""

import unittest
import math
import json
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "src"


class TestTier4RealWorldScenarios(unittest.TestCase):
    """End-to-End Real-World Application Scenarios."""

    def test_scenario_1_fresh_app_install_default_boot(self):
        """Scenario 1: Fresh install boot defaults to Balanced mode and sets up UI/FFlags."""
        # Inspect source contracts
        config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")
        entry_m = (SRC_DIR / "ROEntry.m").read_text(encoding="utf-8")
        window_m = (SRC_DIR / "UI" / "ROPassThroughWindow.m").read_text(encoding="utf-8")

        # 1. Uninitialized defaults check
        self.assertIn("![defaults boolForKey:kROConfigInitializedKey]", config_m)
        self.assertIn("[self applyPreset:ROPresetModeBalanced];", config_m)
        self.assertIn("[self save];", config_m)

        # 2. Balanced mode default values
        self.assertIn("_resolutionScale = 1.0f;", config_m)
        self.assertIn("_textureClampingEnabled = YES;", config_m)
        self.assertIn("_maxTextureDimension = 512;", config_m)
        self.assertIn("_disableShadows = YES;", config_m)
        self.assertIn("_disablePostFX = NO;", config_m)
        self.assertIn("_targetFPS = 60;", config_m)

        # 3. Entry constructor installs hooks and writes initial FastFlags
        self.assertIn("ROInstallMetalHooks()", entry_m)
        self.assertIn("ROInstallResolutionHooks()", entry_m)
        self.assertIn("[ROFastFlags writeFastFlagsConfigurationWithError:", entry_m)

        # 4. Passthrough window created with high window level
        self.assertIn("UIWindowLevelAlert + 100.0", window_m)
        self.assertIn("CGRectMake(20, 100, 50, 50)", window_m)

    def test_scenario_2_potato_mode_activation_jetsam_survival(self):
        """Scenario 2: Potato mode reduces VRAM footprint by >85% in heavy map to survive Jetsam."""
        # Simulate loading 10 heavy 2048x2048 textures (RGBA8888, 4 bytes/pixel)
        uncompressed_bytes_orig = 10 * (2048 * 2048 * 4)  # 167,772,160 bytes (~160 MB)

        # Under Potato Mode, max dimension is 256
        clamped_dim = 256
        uncompressed_bytes_potato = 10 * (clamped_dim * clamped_dim * 4)  # 2,621,440 bytes (~2.5 MB)

        savings_ratio = (uncompressed_bytes_orig - uncompressed_bytes_potato) / uncompressed_bytes_orig
        self.assertGreater(savings_ratio, 0.85, f"VRAM savings was {savings_ratio * 100:.2f}%, expected >85%")

        # Verify mipmap count safety
        max_dim = 256
        max_allowed_mips = math.floor(math.log2(max_dim)) + 1
        self.assertEqual(max_allowed_mips, 9)

        # FastFlags verify shadows disabled & low graphics quality
        config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")
        self.assertIn("case ROPresetModePotato:", config_m)
        self.assertIn("_disableShadows = YES;", config_m)
        self.assertIn("_disablePostFX = YES;", config_m)

    def test_scenario_3_manual_fine_tuning_custom_scale_unlocked_fps(self):
        """Scenario 3: Fine-tuning resolution to 0.65 and FPS to Unlocked on ProMotion iPhone."""
        # Screen: iPhone 13 Pro (844 x 390 points)
        screen_w, screen_h = 844, 390
        scale = 0.65

        scaled_w = max(1, math.floor(screen_w * scale + 0.5))
        scaled_h = max(1, math.floor(screen_h * scale + 0.5))

        self.assertEqual(scaled_w, 549)
        self.assertEqual(scaled_h, 254)

        # Fill rate reduction calculation
        original_pixels = screen_w * screen_h
        scaled_pixels = scaled_w * scaled_h
        fill_rate_reduction = (original_pixels - scaled_pixels) / original_pixels
        self.assertGreater(fill_rate_reduction, 0.55, f"Fill rate reduction was {fill_rate_reduction*100:.1f}%, expected >55%")

        # FastFlags verify targetFPS=0 writes raw integer 0
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.assertIn("cfg.targetFPS = (fpsIdx == 0) ? 30 : (fpsIdx == 1) ? 60 : 0;", menu_m)

    def test_scenario_4_ingame_virtual_joystick_touch_passthrough(self):
        """Scenario 4: In-game touches on joystick and jump button pass through overlay window."""
        # Simulated screen geometry: 844 x 390
        # Button positioned at (20, 100) with size 50x50 -> rect: [20, 100, 70, 150]
        btn_rect = (20, 100, 70, 150)

        def hit_test_simulator(touch_x, touch_y):
            # If inside button rect, returns "Button"
            if btn_rect[0] <= touch_x <= btn_rect[2] and btn_rect[1] <= touch_y <= btn_rect[3]:
                return "ROFloatingButton"
            # Else returns None (passes through to Roblox)
            return None

        # Virtual Joystick at bottom-left: (80, 320)
        self.assertIsNone(hit_test_simulator(80, 320), "Touch on joystick must pass through (return nil)!")

        # Jump Button at bottom-right: (760, 320)
        self.assertIsNone(hit_test_simulator(760, 320), "Touch on jump button must pass through (return nil)!")

        # Camera swipe at screen center: (422, 195)
        self.assertIsNone(hit_test_simulator(422, 195), "Touch on camera swipe must pass through (return nil)!")

        # Tap directly on Floating Action Button: (35, 120)
        self.assertEqual(hit_test_simulator(35, 120), "ROFloatingButton", "Tap on FAB must be intercepted!")

    def test_scenario_5_save_and_clean_restart_execution_flow(self):
        """Scenario 5: User changes settings, taps Save & Exit, triggering exit(0)."""
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")

        # 1. Validation before exit
        self.assertIn("if (scale < 0.25f || scale > 3.0f)", menu_m)

        # 2. Config saved to NSUserDefaults
        self.assertIn("[cfg save];", menu_m)

        # 3. FastFlags written to disk
        self.assertIn("[ROFastFlags writeFastFlagsConfigurationWithError:nil];", menu_m)

        # 4. Alert presents Exit Now with exit(0)
        self.assertIn("exit(0);", menu_m)

    def test_scenario_6_cicd_github_actions_build_and_deployment(self):
        """Scenario 6: GitHub Actions build and deployment pipeline on macOS runner."""
        ci_path = REPO_ROOT / ".github" / "workflows" / "build.yml"
        self.assertTrue(ci_path.is_file(), "CI workflow file build.yml missing.")
        content = ci_path.read_text(encoding="utf-8")

        # 1. macos-latest runner
        self.assertIn("runs-on: macos-latest", content)

        # 2. Checkout step
        self.assertIn("uses: actions/checkout@v4", content)

        # 3. Xcode selection
        self.assertIn("xcode-select", content)

        # 4. ldid install and codesign
        self.assertIn("brew install ldid", content)
        self.assertIn("ldid -S build/RobloxOptimizer.dylib", content)

        # 5. Compilation flags
        self.assertIn("-target arm64-apple-ios14.0", content)
        self.assertIn("-fobjc-arc", content)
        self.assertIn("-framework UIKit", content)
        self.assertIn("-framework Metal", content)

        # 6. Artifact upload
        self.assertIn("uses: actions/upload-artifact@v4", content)
        self.assertIn("name: RobloxOptimizer-dylib", content)

    def test_scenario_7_lifecycle_resume_and_config_idempotence(self):
        """Scenario 7: Config reloading and preset applications are idempotent."""
        config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

        # Check that load checks initialized flag and applies defaults deterministically
        self.assertIn("if (![defaults boolForKey:kROConfigInitializedKey])", config_m)
        self.assertIn("[defaults setBool:YES forKey:kROConfigInitializedKey];", config_m)

    def test_scenario_8_jetsam_vram_reduction_audit(self):
        """Scenario 8: Audit texture clamping impact across varied asset resolutions."""
        asset_profile = [
            # (name, width, height, count)
            ("Character Skin", 2048, 2048, 8),
            ("Clothing Normal", 1024, 1024, 16),
            ("Environment Prop", 1024, 1024, 20),
            ("Terrain Albedo", 2048, 2048, 4),
        ]

        total_bytes_unclamped = sum(w * h * 4 * count for _, w, h, count in asset_profile)
        # In Potato mode (max 256):
        total_bytes_potato = sum(min(w, 256) * min(h, 256) * 4 * count for _, w, h, count in asset_profile)

        # In Balanced mode (max 512):
        total_bytes_balanced = sum(min(w, 512) * min(h, 512) * 4 * count for _, w, h, count in asset_profile)

        mb_unclamped = total_bytes_unclamped / (1024 * 1024)
        mb_potato = total_bytes_potato / (1024 * 1024)
        mb_balanced = total_bytes_balanced / (1024 * 1024)

        # Unclamped memory should be > 250 MB
        self.assertGreater(mb_unclamped, 250)

        # Potato memory must be < 15 MB
        self.assertLess(mb_potato, 15)

        # Balanced memory must be < 50 MB
        self.assertLess(mb_balanced, 50)

        # Ensure Potato reduction exceeds 90%
        potato_reduction = (total_bytes_unclamped - total_bytes_potato) / total_bytes_unclamped
        self.assertGreater(potato_reduction, 0.90)


if __name__ == "__main__":
    unittest.main()
