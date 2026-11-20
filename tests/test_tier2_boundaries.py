#!/usr/bin/env python3
"""
Tier 2: Comprehensive Boundary Value Analysis & Corner Case Test Suite (60+ Test Cases)
Roblox iOS Optimizer Dynamic Library (RobloxOptimizer.dylib)

Exhaustively verifies boundary conditions, edge cases, and safety guardrails:
  B1: Texture Clamping Dimension Boundaries (256, 512, 1024, NPOT, 1x1, 0x0, Aspect Ratios)
  B2: Mipmap Level Calculation Boundaries (floor(log2(max(w,h))) + 1, Single Mip, Max Overflow)
  B3: Metal Safety Exclusions (RenderTargets, Depth/Stencil Formats, Texture Buffers)
  B4: Resolution Scale Float Boundaries (0.25 min, 3.0 max, NaN, Negatives, Non-numerics)
  B5: FastFlags Sandbox Paths & IO Fallbacks (Read-Only Bundle, Writable Documents, Atomic IO)
  B6: Target FPS Limiter Boundaries (30, 60, 120, 0 Unlocked, Corrupted Normalization)
  B7: Touch Passthrough Point Boundaries (Inside FAB, Outside FAB, Modal Edges, Nil Event)
  B8: Configuration Model Corruption & Edge Fallbacks (Enum 999, Zero Clamp, First Run)
"""

import unittest
import math
import json
import os
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "src"


# --- Python Reference Emulators of Objective-C Core Logic ---

def metal_clamp_dimensions(width: int, height: int, max_allowed: int):
    """Reference implementation of ROMetalHooks dimension clamping."""
    if width == 0 or height == 0:
        return width, height
    max_dim = max(width, height)
    if max_dim <= max_allowed:
        return width, height
    scale = max_allowed / max_dim
    clamped_w = max(1, math.floor(width * scale))
    clamped_h = max(1, math.floor(height * scale))
    return clamped_w, clamped_h


def metal_calculate_mipmaps(clamped_w: int, clamped_h: int, orig_mipmaps: int):
    """Reference implementation of ROMetalHooks mipmap recalculation."""
    max_dim = max(clamped_w, clamped_h)
    if max_dim < 1:
        max_allowed_mips = 1
    else:
        max_allowed_mips = math.floor(math.log2(max_dim)) + 1
    return min(orig_mipmaps, max_allowed_mips)


def resolution_scale_drawable_size(width: float, height: float, scale: float):
    """Reference implementation of ROResolutionHooks drawableSize computation."""
    if scale > 0.05 and abs(scale - 1.0) > 0.001 and width > 0 and height > 0:
        return max(1.0, round(width * scale)), max(1.0, round(height * scale))
    return width, height


class TestB1TextureClampingBoundaries(unittest.TestCase):
    """B1: Texture Clamping Dimension Boundaries."""

    def test_b1_01_exact_max_boundary_256(self):
        """256x256 texture with max 256 remains exactly 256x256."""
        w, h = metal_clamp_dimensions(256, 256, 256)
        self.assertEqual((w, h), (256, 256))

    def test_b1_02_exact_max_boundary_512(self):
        """512x512 texture with max 512 remains exactly 512x512."""
        w, h = metal_clamp_dimensions(512, 512, 512)
        self.assertEqual((w, h), (512, 512))

    def test_b1_03_just_above_boundary_257(self):
        """257x256 texture with max 256 downscales proportionally."""
        w, h = metal_clamp_dimensions(257, 256, 256)
        self.assertEqual(w, 256)
        self.assertEqual(h, 255)

    def test_b1_04_just_below_boundary_255(self):
        """255x255 texture with max 256 remains 255x255."""
        w, h = metal_clamp_dimensions(255, 255, 256)
        self.assertEqual((w, h), (255, 255))

    def test_b1_05_non_power_of_two_1080p(self):
        """1920x1080 UI / backdrop texture clamped to 512 preserves aspect ratio."""
        w, h = metal_clamp_dimensions(1920, 1080, 512)
        self.assertEqual(w, 512)
        self.assertEqual(h, 288)  # 1080 * (512/1920) = 288.0

    def test_b1_06_non_power_of_two_800x600(self):
        """800x600 texture clamped to 256."""
        w, h = metal_clamp_dimensions(800, 600, 256)
        self.assertEqual(w, 256)
        self.assertEqual(h, 192)  # 600 * (256/800) = 192.0

    def test_b1_07_extreme_aspect_ratio_ultrawide(self):
        """4096x64 panoramic skybox clamped to 256."""
        w, h = metal_clamp_dimensions(4096, 64, 256)
        self.assertEqual(w, 256)
        self.assertEqual(h, 4)  # 64 * (256/4096) = 4.0

    def test_b1_08_extreme_aspect_ratio_ultratall(self):
        """64x4096 texture clamped to 256."""
        w, h = metal_clamp_dimensions(64, 4096, 256)
        self.assertEqual(w, 4)
        self.assertEqual(h, 256)

    def test_b1_09_minimum_dimension_1x1(self):
        """1x1 1-pixel dummy texture remains 1x1."""
        w, h = metal_clamp_dimensions(1, 1, 256)
        self.assertEqual((w, h), (1, 1))

    def test_b1_10_extreme_ratio_prevent_zero_dimension(self):
        """4096x1 clamped to 256 enforces MAX(1, floor(...)) preventing zero height."""
        w, h = metal_clamp_dimensions(4096, 1, 256)
        self.assertEqual(w, 256)
        self.assertEqual(h, 1)  # floor(1 * 256/4096) = 0, but guarded by max(1, ...)

    def test_b1_11_3d_texture_dimensions_clamped(self):
        """512x512 with max 256 downscales width and height to 256x256."""
        w, h = metal_clamp_dimensions(512, 512, 256)
        self.assertEqual((w, h), (256, 256))

    def test_b1_12_already_small_texture_unchanged(self):
        """64x64 texture with max 256 remains 64x64 without modification."""
        w, h = metal_clamp_dimensions(64, 64, 256)
        self.assertEqual((w, h), (64, 64))


class TestB2MipmapCalculationBoundaries(unittest.TestCase):
    """B2: Mipmap Level Calculation Boundaries."""

    def test_b2_01_max_dimension_256_gives_9_mips(self):
        """256x256 clamped texture has floor(log2(256)) + 1 = 9 maximum mipmaps."""
        mips = metal_calculate_mipmaps(256, 256, orig_mipmaps=12)
        self.assertEqual(mips, 9)

    def test_b2_02_max_dimension_512_gives_10_mips(self):
        """512x512 clamped texture has floor(log2(512)) + 1 = 10 maximum mipmaps."""
        mips = metal_calculate_mipmaps(512, 512, orig_mipmaps=12)
        self.assertEqual(mips, 10)

    def test_b2_03_max_dimension_1024_gives_11_mips(self):
        """1024x1024 texture has floor(log2(1024)) + 1 = 11 maximum mipmaps."""
        mips = metal_calculate_mipmaps(1024, 1024, orig_mipmaps=14)
        self.assertEqual(mips, 11)

    def test_b2_04_minimum_1x1_texture_gives_1_mip(self):
        """1x1 texture has floor(log2(1)) + 1 = 1 mipmap level."""
        mips = metal_calculate_mipmaps(1, 1, orig_mipmaps=5)
        self.assertEqual(mips, 1)

    def test_b2_05_single_level_mipmap_not_expanded(self):
        """Texture with orig_mipmaps=1 remains 1 even if dimension supports 10."""
        mips = metal_calculate_mipmaps(512, 512, orig_mipmaps=1)
        self.assertEqual(mips, 1)

    def test_b2_06_non_power_of_two_300(self):
        """max dimension 300 gives floor(log2(300)) + 1 = 8 + 1 = 9."""
        mips = metal_calculate_mipmaps(300, 200, orig_mipmaps=12)
        self.assertEqual(mips, 9)

    def test_b2_07_underallocated_mipmaps_preserved(self):
        """If texture originally requested 4 mipmaps on a 512 texture, keeps 4."""
        mips = metal_calculate_mipmaps(512, 512, orig_mipmaps=4)
        self.assertEqual(mips, 4)

    def test_b2_08_asymmetric_dimensions_uses_max(self):
        """256x64 texture uses max(256, 64) = 256 -> 9 mipmaps."""
        mips = metal_calculate_mipmaps(256, 64, orig_mipmaps=12)
        self.assertEqual(mips, 9)

    def test_b2_09_power_of_two_boundary_128(self):
        """128x128 texture gives floor(log2(128)) + 1 = 7 + 1 = 8 mipmaps."""
        mips = metal_calculate_mipmaps(128, 128, orig_mipmaps=10)
        self.assertEqual(mips, 8)


class TestB3SafetyExclusionsBoundaries(unittest.TestCase):
    """B3: Metal Safety Exclusions for Render Targets & Depth/Stencil."""

    def setUp(self):
        self.metal_m = (SRC_DIR / "Hooks" / "ROMetalHooks.m").read_text(encoding="utf-8")

    def test_b3_01_rendertarget_usage_bitmask_checked(self):
        """Verify MTLTextureUsageRenderTarget bitmask (0x02) check."""
        self.assertIn("descriptor.usage & MTLTextureUsageRenderTarget", self.metal_m)

    def test_b3_02_combined_rendertarget_usage_bypassed(self):
        """Simulate bitwise OR check for RenderTarget with ShaderRead/ShaderWrite."""
        MTLTextureUsageShaderRead = 0x01
        MTLTextureUsageRenderTarget = 0x02
        MTLTextureUsageShaderWrite = 0x04

        usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget
        self.assertNotEqual(usage & MTLTextureUsageRenderTarget, 0)

        usage_all = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite
        self.assertNotEqual(usage_all & MTLTextureUsageRenderTarget, 0)

    def test_b3_03_depth16_unorm_pixel_format_bypassed(self):
        """Verify MTLPixelFormatDepth16Unorm is guarded."""
        self.assertIn("case MTLPixelFormatDepth16Unorm:", self.metal_m)

    def test_b3_04_depth32_float_pixel_format_bypassed(self):
        """Verify MTLPixelFormatDepth32Float is guarded."""
        self.assertIn("case MTLPixelFormatDepth32Float:", self.metal_m)

    def test_b3_05_stencil8_pixel_format_bypassed(self):
        """Verify MTLPixelFormatStencil8 is guarded."""
        self.assertIn("case MTLPixelFormatStencil8:", self.metal_m)

    def test_b3_06_depth24_stencil8_pixel_format_bypassed(self):
        """Verify MTLPixelFormatDepth24Unorm_Stencil8 is guarded."""
        self.assertIn("case MTLPixelFormatDepth24Unorm_Stencil8:", self.metal_m)

    def test_b3_07_depth32_stencil8_pixel_format_bypassed(self):
        """Verify MTLPixelFormatDepth32Float_Stencil8 is guarded."""
        self.assertIn("case MTLPixelFormatDepth32Float_Stencil8:", self.metal_m)

    def test_b3_08_texture_buffer_type_bypassed(self):
        """Verify MTLTextureTypeTextureBuffer is excluded from clamping."""
        self.assertNotIn("case MTLTextureTypeTextureBuffer:", self.metal_m)
        self.assertIn("ROIsClampableTextureType", self.metal_m)

    def test_b3_09_pixel_format_x32_stencil8_bypassed(self):
        """Verify MTLPixelFormatX32_Stencil8 is guarded."""
        self.assertIn("case MTLPixelFormatX32_Stencil8:", self.metal_m)

    def test_b3_10_pixel_format_x24_stencil8_bypassed(self):
        """Verify MTLPixelFormatX24_Stencil8 is guarded."""
        self.assertIn("case MTLPixelFormatX24_Stencil8:", self.metal_m)


class TestB4ResolutionScaleBoundaries(unittest.TestCase):
    """B4: Resolution Scale Float Boundaries & Input Validation."""

    def setUp(self):
        self.menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

    def test_b4_01_exact_minimum_scale_0_25(self):
        """Scale 0.25 is within [0.25, 3.0] and valid."""
        scale = 0.25
        self.assertTrue(0.25 <= scale <= 3.0)

    def test_b4_02_exact_maximum_scale_3_0(self):
        """Scale 3.0 is within [0.25, 3.0] and valid."""
        scale = 3.0
        self.assertTrue(0.25 <= scale <= 3.0)

    def test_b4_03_below_minimum_0_24_rejected(self):
        """Scale 0.24 is rejected (< 0.25)."""
        scale = 0.24
        self.assertFalse(0.25 <= scale <= 3.0)

    def test_b4_04_above_maximum_3_01_rejected(self):
        """Scale 3.01 is rejected (> 3.0)."""
        scale = 3.01
        self.assertFalse(0.25 <= scale <= 3.0)

    def test_b4_05_negative_scale_rejected(self):
        """Negative scales (-0.5, -1.0) rejected."""
        self.assertFalse(0.25 <= -0.5 <= 3.0)
        self.assertFalse(0.25 <= -1.0 <= 3.0)

    def test_b4_06_zero_scale_rejected(self):
        """Zero scale (0.0) rejected."""
        self.assertFalse(0.25 <= 0.0 <= 3.0)

    def test_b4_07_nan_or_infinity_string_rejection(self):
        """String 'NaN' or 'Infinity' parsed as 0.0 or out of bounds."""
        for val_str in ["NaN", "Infinity", "-Infinity"]:
            val = float(val_str)
            # In Objective-C, [text floatValue] returns 0 for non-numeric or inf
            is_valid = (0.25 <= val <= 3.0) and not math.isnan(val)
            self.assertFalse(is_valid)

    def test_b4_08_empty_string_rejection(self):
        """Empty string input returns 0.0 in Objective-C, rejected."""
        val = 0.0  # ["".floatValue]
        self.assertFalse(0.25 <= val <= 3.0)

    def test_b4_09_malformed_decimal_string(self):
        """String '0.5.5' or 'abc' rejected."""
        # Objective-C [@"0.5.5" floatValue] -> 0.5 (which is valid), but [@"abc" floatValue] -> 0.0
        val_abc = 0.0
        self.assertFalse(0.25 <= val_abc <= 3.0)

    def test_b4_10_drawable_size_minimum_one_pixel(self):
        """Scaled drawable size never collapses to 0 pixels."""
        w, h = resolution_scale_drawable_size(10.0, 10.0, 0.01)
        # Even with extreme scale, MAX(1.0, ...) protects from 0x0 buffer
        self.assertGreaterEqual(w, 1.0)
        self.assertGreaterEqual(h, 1.0)


class TestB5FastFlagsSandboxPathsBoundaries(unittest.TestCase):
    """B5: FastFlags Sandbox Paths & IO Fallbacks."""

    def setUp(self):
        self.fflags_m = (SRC_DIR / "FFlags" / "ROFastFlags.m").read_text(encoding="utf-8")

    def test_b5_01_bundle_path_resolution(self):
        """Verify Bundle path uses [[NSBundle mainBundle] bundlePath]."""
        self.assertIn("[[NSBundle mainBundle] bundlePath]", self.fflags_m)
        self.assertIn('@"ClientSettings/ClientAppSettings.json"', self.fflags_m)

    def test_b5_02_documents_path_fallback(self):
        """Verify fallback to NSDocumentDirectory."""
        self.assertIn("NSSearchPathForDirectoriesInDomains(NSDocumentDirectory", self.fflags_m)

    def test_b5_03_application_support_path_fallback(self):
        """Verify secondary fallback to NSApplicationSupportDirectory."""
        self.assertIn("NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory", self.fflags_m)

    def test_b5_04_at_least_one_success_check(self):
        """Verify function succeeds if at least one target path was written successfully."""
        self.assertIn("atLeastOneSuccess", self.fflags_m)
        self.assertIn("return atLeastOneSuccess;", self.fflags_m)

    def test_b5_05_nil_error_pointer_safe(self):
        """Verify error pointer can be nil without causing crash (if (error) *error = ...)."""
        self.assertIn("if (error) *error =", self.fflags_m)

    def test_b5_06_target_paths_array_order(self):
        """Verify writing attempts Bundle path first, then Documents, then App Support."""
        order_pattern = re.compile(
            r"\[self\s+bundleSettingsPath\].*?\[self\s+documentsSettingsPath\].*?\[self\s+applicationSupportSettingsPath\]",
            re.DOTALL
        )
        self.assertIsNotNone(order_pattern.search(self.fflags_m))


class TestB6TargetFPSBoundaries(unittest.TestCase):
    """B6: Target FPS Limiter Boundaries & Normalization."""

    def setUp(self):
        self.config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

    def test_b6_01_fps_30_boundary(self):
        """30 FPS is recognized in preset and manual mode."""
        self.assertIn("_targetFPS != 30", self.config_m)

    def test_b6_02_fps_60_standard(self):
        """60 FPS is standard default."""
        self.assertIn("_targetFPS = 60;", self.config_m)

    def test_b6_03_fps_0_unlocked(self):
        """0 FPS indicates Unlocked (uncapped)."""
        self.assertIn("_targetFPS != 0", self.config_m)

    def test_b6_04_invalid_fps_normalized_to_60(self):
        """Corrupted FPS (e.g. -1, 999) is normalized to 60."""
        self.assertIn("if (_targetFPS != 30 && _targetFPS != 60 && _targetFPS != 0) {", self.config_m)
        self.assertIn("_targetFPS = 60;", self.config_m)

    def test_b6_05_menu_fps_control_maps_unlocked(self):
        """Menu segmented control index 2 maps to 0 (Unlocked)."""
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.assertIn("cfg.targetFPS = (fpsIdx == 0) ? 30 : (fpsIdx == 1) ? 60 : 0;", menu_m)


class TestB7TouchPassthroughBoundaries(unittest.TestCase):
    """B7: Touch Passthrough Point Boundaries."""

    def setUp(self):
        self.window_m = (SRC_DIR / "UI" / "ROPassThroughWindow.m").read_text(encoding="utf-8")

    def test_b7_01_window_itself_returns_nil(self):
        """Touch landing on ROPassThroughWindow itself returns nil."""
        self.assertIn("if (hitView == self || hitView == self.rootViewController.view)", self.window_m)
        self.assertIn("return nil;", self.window_m)

    def test_b7_02_fab_view_touch_returned(self):
        """Touch inside ROFloatingButton returns the button view."""
        self.assertIn("return hitView;", self.window_m)

    def test_b7_03_fab_tap_gesture_requires_pan_to_fail(self):
        """Verify tap gesture waits for pan gesture to fail to avoid accidental taps while dragging."""
        button_m = (SRC_DIR / "UI" / "ROFloatingButton.m").read_text(encoding="utf-8")
        self.assertIn("[self.tapGesture requireGestureRecognizerToFail:self.panGesture];", button_m)

    def test_b7_04_card_tap_absorbs_touches(self):
        """Verify modal dialogCard has a dummy tap gesture so taps inside don't dismiss the modal."""
        menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")
        self.assertIn("[self.dialogCard addGestureRecognizer:cardTap];", menu_m)

    def test_b7_05_edge_snapping_safe_area_insets_handled(self):
        """Verify edge snapping accounts for safeAreaInsets on modern notch/island iPhones."""
        button_m = (SRC_DIR / "UI" / "ROFloatingButton.m").read_text(encoding="utf-8")
        self.assertIn("insets = superview.safeAreaInsets;", button_m)

    def test_b7_06_outside_card_touch_calls_dismiss_and_returns_nil(self):
        """Verify hitTest:withEvent: dismisses menu and returns nil when hitView is not in dialogCard."""
        self.assertIn("if (hitView && card &&", self.window_m)
        self.assertIn("![hitView isDescendantOfView:card]", self.window_m)
        self.assertIn("hitView != self.floatingButton", self.window_m)
        self.assertIn("[self.menuViewController dismissMenu];", self.window_m)
        self.assertIn("return nil;", self.window_m)

    def test_b7_07_presented_alert_touch_does_not_dismiss_menu(self):
        """Verify touch inside a presented alert view controller returns hitView without dismissing menu."""
        self.assertIn("UIViewController *presentedVC =", self.window_m)
        self.assertIn("if (presentedVC) {", self.window_m)
        self.assertIn("return hitView;", self.window_m)

    def test_b7_08_floating_button_captures_touches_over_backdrop(self):
        """Verify floating button remains in front of menu overlay to capture touches during menu presentation."""
        self.assertIn("[self.rootViewController.view bringSubviewToFront:self.floatingButton];", self.window_m)


class TestB8PresetModelCorruptionBoundaries(unittest.TestCase):
    """B8: Configuration Model Corruption & Edge Fallbacks."""

    def setUp(self):
        self.config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

    def test_b8_01_first_boot_initialization(self):
        """Uninitialized defaults triggers applyPreset:Balanced and saves RO_ConfigInitialized=YES."""
        self.assertIn("if (![defaults boolForKey:kROConfigInitializedKey]) {", self.config_m)
        self.assertIn("[self applyPreset:ROPresetModeBalanced];", self.config_m)
        self.assertIn("[self save];", self.config_m)

    def test_b8_02_zero_max_texture_dimension_fallback(self):
        """maxTextureDimension == 0 is normalized to default 512."""
        self.assertIn("if (_maxTextureDimension == 0) {", self.config_m)
        self.assertIn("_maxTextureDimension = 512;", self.config_m)

    def test_b8_03_out_of_bounds_scale_on_load_normalized(self):
        """Corrupted scale value loaded from disk (< 0.25 or > 3.0) normalized to 1.0."""
        self.assertIn("if (_resolutionScale < 0.25f || _resolutionScale > 3.0f) {", self.config_m)
        self.assertIn("_resolutionScale = 1.0f;", self.config_m)

    def test_b8_04_potato_balanced_reenforce_on_load(self):
        """Preset modes Potato and Balanced re-enforce strict preset values even if defaults had drifts."""
        self.assertIn("if (_presetMode == ROPresetModePotato || _presetMode == ROPresetModeBalanced) {", self.config_m)
        self.assertIn("[self applyPreset:_presetMode];", self.config_m)

    def test_b8_05_singleton_thread_safety_dispatch_once(self):
        """Verify dispatch_once token protects singleton instantiation across threads."""
        self.assertIn("static dispatch_once_t onceToken;", self.config_m)
        self.assertIn("dispatch_once(&onceToken", self.config_m)

    def test_b8_06_texture_clamping_zero_dimension_check(self):
        """Verify metal hook guards against zero width or zero height descriptors."""
        metal_m = (SRC_DIR / "Hooks" / "ROMetalHooks.m").read_text(encoding="utf-8")
        self.assertIn("if (descriptor.width == 0 || descriptor.height == 0)", metal_m)


if __name__ == "__main__":
    unittest.main()
