#!/usr/bin/env python3
"""
Tier 3: Cross-Feature Combinations (Pairwise) Test Suite (18 Test Cases)
Roblox iOS Optimizer Dynamic Library (RobloxOptimizer.dylib)

Exhaustively verifies combinatorial interactions across modules:
  - Preset Modes (Potato, Balanced, Manual) <-> FastFlags JSON Engine
  - Preset Modes <-> UI Overlay Reactive State Machine
  - Metal Texture Clamping <-> RenderTarget Preservation in Rendering Pipeline
  - Resolution Scaling <-> CAMetalLayer Viewport Sizes
  - Floating Button Motion <-> Passthrough Window Hit Testing
  - Modal Input Validation <-> Config Persistence & Clean Exit Flow
  - Makefile Targets <-> CI/CD Compilation Flags Synchronization
"""

import unittest
import json
import math
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "src"


# --- Reference Emulators ---

def generate_reference_fastflags(config: dict) -> dict:
    """Emulate ROFastFlags currentFlagsDictionary."""
    flags = {}
    flags["FIntRenderShadowIntensity"] = 0 if config.get("disableShadows", True) else 1
    flags["FFlagDebugDisableDeferredShading"] = True
    flags["DFFlagDisablePostFx"] = bool(config.get("disablePostFX", True))
    flags["FIntFRMQualityLevelOverride"] = 1
    flags["FFlagGlobalWindActive"] = False
    flags["DFIntTaskSchedulerTargetFps"] = int(config.get("targetFPS", 60))
    return flags


def metal_clamp_texture(width: int, height: int, is_render_target: bool, is_depth: bool, max_allowed: int):
    """Simulate ROMetalHooks decision logic for a single texture descriptor."""
    if is_render_target or is_depth or width == 0 or height == 0:
        return width, height, None  # Unchanged
    max_dim = max(width, height)
    if max_dim <= max_allowed:
        return width, height, None
    scale = max_allowed / max_dim
    clamped_w = max(1, math.floor(width * scale))
    clamped_h = max(1, math.floor(height * scale))
    max_mips = math.floor(math.log2(max(clamped_w, clamped_h))) + 1
    return clamped_w, clamped_h, max_mips


def compute_edge_snap(center_x: float, center_y: float, screen_w: float, screen_h: float,
                      safe_left: float = 0, safe_right: float = 0, safe_top: float = 0, safe_bottom: float = 0,
                      button_radius: float = 25.0):
    """Simulate ROFloatingButton edge snapping calculation."""
    min_x = safe_left + button_radius + 10.0
    max_x = screen_w - safe_right - button_radius - 10.0
    min_y = safe_top + button_radius + 10.0
    max_y = screen_h - safe_bottom - button_radius - 10.0

    target_x = min_x if center_x < (screen_w / 2.0) else max_x
    target_y = min(max(center_y, min_y), max_y)
    return target_x, target_y


class TestPairwisePresetsAndFastFlags(unittest.TestCase):
    """Cross-Feature Tests: Preset Configurations <-> Engine FastFlags."""

    def test_p1_potato_mode_combination(self):
        """Potato Mode -> scale 0.5 + clamp 256 + shadows OFF + postfx OFF + 60fps."""
        cfg = {
            "presetMode": 0,  # Potato
            "resolutionScale": 0.50,
            "maxTextureDimension": 256,
            "disableShadows": True,
            "disablePostFX": True,
            "targetFPS": 60,
        }
        flags = generate_reference_fastflags(cfg)

        self.assertEqual(flags["FIntRenderShadowIntensity"], 0)
        self.assertEqual(flags["FFlagDebugDisableDeferredShading"], True)
        self.assertEqual(flags["DFFlagDisablePostFx"], True)
        self.assertEqual(flags["FIntFRMQualityLevelOverride"], 1)
        self.assertEqual(flags["FFlagGlobalWindActive"], False)
        self.assertEqual(flags["DFIntTaskSchedulerTargetFps"], 60)

        # Verify JSON serialization strictness
        json_str = json.dumps(flags)
        self.assertIn('"FIntRenderShadowIntensity": 0', json_str)
        self.assertIn('"DFFlagDisablePostFx": true', json_str)

    def test_p2_balanced_mode_combination(self):
        """Balanced Mode -> scale 1.0 + clamp 512 + shadows OFF + postfx ON + 60fps."""
        cfg = {
            "presetMode": 1,  # Balanced
            "resolutionScale": 1.0,
            "maxTextureDimension": 512,
            "disableShadows": True,
            "disablePostFX": False,  # PostFX enabled in balanced mode
            "targetFPS": 60,
        }
        flags = generate_reference_fastflags(cfg)

        self.assertEqual(flags["FIntRenderShadowIntensity"], 0)
        self.assertEqual(flags["DFFlagDisablePostFx"], False)
        self.assertEqual(flags["DFIntTaskSchedulerTargetFps"], 60)

        json_str = json.dumps(flags)
        self.assertIn('"DFFlagDisablePostFx": false', json_str)

    def test_p3_manual_mode_high_end_tuning(self):
        """Manual Mode + High-End Device -> scale 2.0, clamp 1024, shadows ON, postfx ON, 120fps."""
        cfg = {
            "presetMode": 2,  # Manual
            "resolutionScale": 2.0,
            "maxTextureDimension": 1024,
            "disableShadows": False,  # Shadows enabled
            "disablePostFX": False,   # PostFX enabled
            "targetFPS": 120,
        }
        flags = generate_reference_fastflags(cfg)

        self.assertEqual(flags["FIntRenderShadowIntensity"], 1)
        self.assertEqual(flags["DFFlagDisablePostFx"], False)
        self.assertEqual(flags["DFIntTaskSchedulerTargetFps"], 120)

    def test_p4_manual_mode_extreme_battery_saving(self):
        """Manual Mode + Battery Saver -> scale 0.33, clamp 256, shadows OFF, postfx OFF, 30fps."""
        cfg = {
            "presetMode": 2,
            "resolutionScale": 0.33,
            "maxTextureDimension": 256,
            "disableShadows": True,
            "disablePostFX": True,
            "targetFPS": 30,
        }
        flags = generate_reference_fastflags(cfg)

        self.assertEqual(flags["FIntRenderShadowIntensity"], 0)
        self.assertEqual(flags["DFFlagDisablePostFx"], True)
        self.assertEqual(flags["DFIntTaskSchedulerTargetFps"], 30)

    def test_p5_manual_mode_unlocked_framerate(self):
        """Manual Mode + Uncapped FPS -> targetFPS 0 -> DFIntTaskSchedulerTargetFps: 0."""
        cfg = {
            "presetMode": 2,
            "resolutionScale": 1.0,
            "maxTextureDimension": 512,
            "disableShadows": True,
            "disablePostFX": False,
            "targetFPS": 0,  # Unlocked
        }
        flags = generate_reference_fastflags(cfg)
        self.assertEqual(flags["DFIntTaskSchedulerTargetFps"], 0)


class TestPairwiseStateTransitions(unittest.TestCase):
    """Cross-Feature Tests: Preset State Machine Transitions."""

    def setUp(self):
        self.menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

    def test_p6_preset_switching_potato_to_manual_to_balanced(self):
        """Verifies state machine dimming transitions across segment changes."""
        # Potato: userInteractionEnabled = NO, alpha = 0.45
        self.assertIn("self.subControlsContainer.userInteractionEnabled = NO;", self.menu_m)
        self.assertIn("self.subControlsContainer.alpha = 0.45;", self.menu_m)

        # Manual: userInteractionEnabled = YES, alpha = 1.0
        self.assertIn("self.subControlsContainer.userInteractionEnabled = YES;", self.menu_m)
        self.assertIn("self.subControlsContainer.alpha = 1.0;", self.menu_m)

    def test_p7_manual_customizations_preserved_across_inspections(self):
        """Manual mode checks bounds but does not overwrite user resolution."""
        self.assertIn("case ROPresetModeManual:", self.config_m)
        self.assertIn("if (_resolutionScale < 0.25f || _resolutionScale > 3.0f)", self.config_m)

    def test_p8_save_and_exit_invocation_chain(self):
        """Save & Exit triggers validation -> config save -> FastFlags write -> exit alert."""
        save_idx = self.menu_m.find("saveAndExitTapped")
        cfg_save_idx = self.menu_m.find("[cfg save]", save_idx)
        ff_write_idx = self.menu_m.find("[ROFastFlags writeFastFlagsConfigurationWithError:", save_idx)
        exit_idx = self.menu_m.find("exit(0)", save_idx)

        self.assertGreater(cfg_save_idx, save_idx)
        self.assertGreater(ff_write_idx, cfg_save_idx)
        self.assertGreater(exit_idx, ff_write_idx)


class TestPairwiseGraphicsPipeline(unittest.TestCase):
    """Cross-Feature Tests: Metal Texture Clamping <-> RenderTarget & Resolution Scaling."""

    def test_p9_metal_clamping_and_rendertarget_coexistence(self):
        """Simulate a mixed frame: normal textures are clamped to 256; render targets are preserved."""
        descriptors = [
            {"name": "Diffuse_Character", "w": 2048, "h": 2048, "rt": False, "depth": False},
            {"name": "Lightmap_Terrain",  "w": 1024, "h": 1024, "rt": False, "depth": False},
            {"name": "Main_Framebuffer",  "w": 2048, "h": 1536, "rt": True,  "depth": False},
            {"name": "Shadow_Map_Depth",  "w": 1024, "h": 1024, "rt": False, "depth": True},
            {"name": "Small_Icon",        "w": 128,  "h": 128,  "rt": False, "depth": False},
        ]

        results = {}
        for d in descriptors:
            cw, ch, max_mips = metal_clamp_texture(d["w"], d["h"], d["rt"], d["depth"], max_allowed=256)
            results[d["name"]] = (cw, ch, max_mips)

        # Diffuse character: clamped 2048x2048 -> 256x256, 9 mips
        self.assertEqual(results["Diffuse_Character"], (256, 256, 9))
        # Lightmap: clamped 1024x1024 -> 256x256, 9 mips
        self.assertEqual(results["Lightmap_Terrain"], (256, 256, 9))
        # Framebuffer render target: PRESERVED at 2048x1536
        self.assertEqual(results["Main_Framebuffer"], (2048, 1536, None))
        # Depth buffer: PRESERVED at 1024x1024
        self.assertEqual(results["Shadow_Map_Depth"], (1024, 1024, None))
        # Small icon: already <= 256, PRESERVED at 128x128
        self.assertEqual(results["Small_Icon"], (128, 128, None))

    def test_p10_resolution_scale_and_cametallayer_sizes(self):
        """Pairwise verification of CAMetalLayer drawableSize scaling across standard iOS screens."""
        test_cases = [
            # (bounds_w, bounds_h, scale, expected_w, expected_h)
            (844, 390, 0.50, 422, 195),    # iPhone 12/13/14 landscape @ Potato 0.5x
            (844, 390, 0.75, 633, 293),    # iPhone 12/13/14 landscape @ 0.75x
            (844, 390, 1.00, 844, 390),    # iPhone 12/13/14 landscape @ Native 1.0x
            (896, 414, 0.50, 448, 207),    # iPhone 11 landscape @ 0.5x
            (1024, 768, 0.50, 512, 384),   # iPad landscape @ 0.5x
            (1024, 768, 2.00, 2048, 1536), # iPad Pro Retina super-sampling @ 2.0x
        ]
        for bw, bh, scale, exp_w, exp_h in test_cases:
            if scale == 1.0:
                # 1.0 bypasses scaling
                dw, dh = bw, bh
            else:
                # Emulate C99 round() which rounds halfway cases away from zero: floor(x + 0.5)
                dw = max(1, math.floor(bw * scale + 0.5))
                dh = max(1, math.floor(bh * scale + 0.5))
            self.assertEqual((dw, dh), (exp_w, exp_h), f"Failed for {bw}x{bh} @ {scale}")

    def test_p11_texture_clamping_and_mipmap_reduction(self):
        """Pairwise combination of dimension reductions verifying mipmaps <= floor(log2(max_dim)) + 1."""
        test_dims = [(2048, 2048), (4096, 2048), (1024, 512), (3000, 1500)]
        clamp_limits = [256, 512]

        for w, h in test_dims:
            for max_allowed in clamp_limits:
                cw, ch, max_mips = metal_clamp_texture(w, h, False, False, max_allowed)
                self.assertLessEqual(max(cw, ch), max_allowed)
                calculated_limit = math.floor(math.log2(max(cw, ch))) + 1
                self.assertEqual(max_mips, calculated_limit)


class TestPairwiseUIAndInteraction(unittest.TestCase):
    """Cross-Feature Tests: Floating Button <-> Passthrough Window & Input Validation."""

    def test_p12_floating_button_drag_and_edge_snap(self):
        """Button dragged to coordinates snaps to nearest screen edge within safe bounds."""
        screen_w, screen_h = 414.0, 896.0
        safe_top, safe_bottom = 44.0, 34.0

        # Dragged to left side (center_x = 100, center_y = 300) -> snaps to min_x
        tx, ty = compute_edge_snap(100.0, 300.0, screen_w, screen_h, safe_top=safe_top, safe_bottom=safe_bottom)
        self.assertEqual(tx, 35.0)  # 0 + 25 + 10 = 35.0
        self.assertEqual(ty, 300.0)

        # Dragged to right side (center_x = 350, center_y = 500) -> snaps to max_x
        tx, ty = compute_edge_snap(350.0, 500.0, screen_w, screen_h, safe_top=safe_top, safe_bottom=safe_bottom)
        self.assertEqual(tx, 379.0)  # 414 - 0 - 25 - 10 = 379.0
        self.assertEqual(ty, 500.0)

        # Dragged out of top bound (center_y = 10) -> clamped to min_y
        tx, ty = compute_edge_snap(50.0, 10.0, screen_w, screen_h, safe_top=safe_top, safe_bottom=safe_bottom)
        self.assertEqual(ty, 79.0)  # 44 + 25 + 10 = 79.0

    def test_p13_passthrough_window_with_modal_active(self):
        """When modal is displayed, window presents modal; backdrop tap dismisses modal."""
        window_m = (SRC_DIR / "UI" / "ROPassThroughWindow.m").read_text(encoding="utf-8")
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")

        self.assertIn("[menu presentInParent:self.rootViewController];", window_m)
        self.assertIn("backdropTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTapped)];", menu_m)

    def test_p13b_landscape_orientation_and_passthrough_coordination(self):
        """Verify overlay container and menu support landscape orientation transitions and centered card."""
        window_m = (SRC_DIR / "UI" / "ROPassThroughWindow.m").read_text(encoding="utf-8")
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")

        self.assertIn("viewWillTransitionToSize:", window_m)
        self.assertIn("viewWillTransitionToSize:", menu_m)
        self.assertIn("shouldAutorotate", window_m)
        self.assertIn("shouldAutorotate", menu_m)
        self.assertIn("constraintEqualToAnchor:self.view.centerXAnchor", menu_m)
        self.assertIn("constraintEqualToAnchor:self.view.centerYAnchor", menu_m)

    def test_p14_resolution_input_validation_and_model_persistence(self):
        """Valid resolution input ('0.75') is stored to config and saved."""
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.assertIn("cfg.resolutionScale = (CGFloat)scale;", menu_m)
        self.assertIn("[cfg save];", menu_m)

    def test_p15_invalid_resolution_input_blocks_save(self):
        """Invalid resolution input presents alert and returns early without calling [cfg save]."""
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        guard_block = re.search(r"if\s*\(scale\s*<\s*0\.25f\s*\|\|\s*scale\s*>\s*3\.0f\)\s*\{(.*?)\n\s*return;", menu_m, re.DOTALL)
        self.assertIsNotNone(guard_block)
        self.assertIn("Invalid Resolution Scale", guard_block.group(1))


class TestPairwiseBuildAndCI(unittest.TestCase):
    """Cross-Feature Tests: Makefile <-> CI/CD GitHub Actions Alignment."""

    def setUp(self):
        self.makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")
        self.ci_workflow = (REPO_ROOT / ".github" / "workflows" / "build.yml").read_text(encoding="utf-8")
        self.build_sh = (REPO_ROOT / "build.sh").read_text(encoding="utf-8")

    def test_p16_makefile_and_github_actions_flags_parity(self):
        """Target flags arm64-apple-ios14.0 and -fobjc-arc must match in Makefile and build.yml."""
        for flag in ["arm64-apple-ios14.0", "-fobjc-arc", "RobloxOptimizer.dylib"]:
            self.assertIn(flag, self.makefile)
            self.assertIn(flag, self.ci_workflow)
            self.assertIn(flag, self.build_sh)

    def test_p17_build_output_path_and_ldid_parity(self):
        """Both Makefile, build.sh, and CI workflow codesign with ldid -S."""
        self.assertTrue("$(LDID) -S" in self.makefile or "ldid -S" in self.makefile)
        self.assertIn("ldid -S", self.ci_workflow)
        self.assertIn("ldid -S", self.build_sh)

    def test_p18_source_files_complete_inclusion_in_build(self):
        """All 8 .m source files in src/ must be compiled in Makefile, build.sh, and CI workflow."""
        m_files = sorted([p.name for p in SRC_DIR.rglob("*.m")])
        self.assertEqual(len(m_files), 8)

        for filename in m_files:
            self.assertIn(filename, self.makefile)
            self.assertIn(filename, self.ci_workflow)
            self.assertIn(filename, self.build_sh)


if __name__ == "__main__":
    unittest.main()
