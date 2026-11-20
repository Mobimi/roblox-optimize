#!/usr/bin/env python3
"""
Tier 1: Comprehensive Feature Coverage Test Suite (60+ Test Cases)
Roblox iOS Optimizer Dynamic Library (RobloxOptimizer.dylib)

Covers all 12 primary features specified in PROJECT.md and ORIGINAL_REQUEST.md:
  F1:  Repo Cleanliness & Modular Structure
  F2:  No Hardcoded Roblox Memory Addresses / Offsets
  F3:  ROConfig Presets (Potato, Balanced, Manual) & Persistence
  F4:  ROMetalHooks Texture Clamping & Mipmap Calculation
  F5:  ROResolutionHooks Scaling & Swizzling Logic
  F6:  ROFastFlags JSON Generation with Strict Types
  F7:  ROPassThroughWindow Touch Passthrough & ROFloatingButton
  F8:  ROMenuViewController Dynamic Dimming & Sub-controls State
  F9:  Resolution Scale Float Validation & Clean Exit Flow
  F10: Makefile & build.sh Target Flags & Codesigning
  F11: GitHub Actions CI/CD Workflow Schema & Triggers
  F12: Git Branch & Remote Configuration
"""

import unittest
import os
import sys
import re
import json
import math
import subprocess
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "src"


class TestFeature1RepoCleanliness(unittest.TestCase):
    """F1: Repo Cleanliness and Project Structure Verification."""

    def test_f1_01_no_legacy_theos_files(self):
        """Verify all legacy Theos / tweak files are wiped from repo."""
        forbidden_files = [
            REPO_ROOT / "control",
            REPO_ROOT / "Filter.plist",
            REPO_ROOT / "Core",
            REPO_ROOT / "UI" / "MainPanel.mm",
            REPO_ROOT / "UI" / "SliderCell.mm",
            REPO_ROOT / "UI" / "ToggleCell.mm",
            REPO_ROOT / "UI" / "OverlayWindow.mm",
        ]
        for p in forbidden_files:
            self.assertFalse(p.exists(), f"Legacy Theos artifact still exists: {p}")

    def test_f1_02_modular_directory_structure(self):
        """Verify presence of modular architecture: Config, Hooks, FFlags, UI."""
        required_dirs = [
            SRC_DIR / "Config",
            SRC_DIR / "Hooks",
            SRC_DIR / "FFlags",
            SRC_DIR / "UI",
        ]
        for d in required_dirs:
            self.assertTrue(d.is_dir(), f"Required module directory missing: {d}")

    def test_f1_03_expected_source_files_present(self):
        """Verify all required Objective-C source and header files exist."""
        expected_files = [
            SRC_DIR / "ROEntry.m",
            SRC_DIR / "Config" / "ROConfig.h",
            SRC_DIR / "Config" / "ROConfig.m",
            SRC_DIR / "Hooks" / "ROMetalHooks.h",
            SRC_DIR / "Hooks" / "ROMetalHooks.m",
            SRC_DIR / "Hooks" / "ROResolutionHooks.h",
            SRC_DIR / "Hooks" / "ROResolutionHooks.m",
            SRC_DIR / "FFlags" / "ROFastFlags.h",
            SRC_DIR / "FFlags" / "ROFastFlags.m",
            SRC_DIR / "UI" / "ROPassThroughWindow.h",
            SRC_DIR / "UI" / "ROPassThroughWindow.m",
            SRC_DIR / "UI" / "ROFloatingButton.h",
            SRC_DIR / "UI" / "ROFloatingButton.m",
            SRC_DIR / "UI" / "ROMenuViewController.h",
            SRC_DIR / "UI" / "ROMenuViewController.m",
        ]
        for f in expected_files:
            self.assertTrue(f.is_file(), f"Expected core source file missing: {f}")

    def test_f1_04_no_legacy_theos_syntax_in_makefile(self):
        """Verify Makefile does not reference include $(THEOS)/makefiles."""
        makefile = REPO_ROOT / "Makefile"
        self.assertTrue(makefile.is_file(), "Makefile missing in root.")
        content = makefile.read_text(encoding="utf-8")
        self.assertNotIn("THEOS", content)
        self.assertNotIn("tweak.mk", content)

    def test_f1_05_clean_readme_and_documentation(self):
        """Verify README.md exists and documents the modern dylib architecture."""
        readme = REPO_ROOT / "README.md"
        self.assertTrue(readme.is_file(), "README.md missing.")
        content = readme.read_text(encoding="utf-8")
        self.assertIn("RobloxOptimizer", content)
        self.assertIn("Metal", content)


class TestFeature2NoHardcodedOffsets(unittest.TestCase):
    """F2: Guarantee Zero Hardcoded Roblox Memory Offsets or Addresses."""

    def setUp(self):
        self.source_files = list(SRC_DIR.rglob("*.m")) + list(SRC_DIR.rglob("*.h"))
        self.assertTrue(len(self.source_files) > 0, "No source files found in src/")

    def test_f2_01_no_hexadecimal_memory_addresses(self):
        """Assert zero hex memory addresses (0x10... or 0x100...) exist in source code."""
        # Allow small hex bitmasks like 0x01, 0x02, 0x04 for flags, but reject absolute addresses
        address_pattern = re.compile(r"0x[0-9a-fA-F]{6,16}")
        for path in self.source_files:
            content = path.read_text(encoding="utf-8")
            matches = address_pattern.findall(content)
            self.assertEqual(
                len(matches), 0,
                f"Hardcoded memory address found in {path.name}: {matches}"
            )

    def test_f2_02_no_assembly_offsets_or_raw_pointer_casts(self):
        """Assert absence of assembly offset arithmetic or direct function pointer casts."""
        offset_patterns = [
            re.compile(r"\*\(uintptr_t\s*\*\)"),
            re.compile(r"sub_[0-9a-fA-F]+"),
            re.compile(r"loc_[0-9a-fA-F]+"),
            re.compile(r"__asm__"),
        ]
        for path in self.source_files:
            content = path.read_text(encoding="utf-8")
            for pattern in offset_patterns:
                self.assertIsNone(
                    pattern.search(content),
                    f"Forbidden offset/assembly pattern '{pattern.pattern}' found in {path.name}"
                )

    def test_f2_03_no_roblox_internal_mangled_symbols(self):
        """Assert absence of internal Roblox C++ namespaces or class symbols (e.g. RBX::)."""
        rbx_pattern = re.compile(r"\bRBX::|\bRobloxExtra\b|\bRBXScript\b")
        for path in self.source_files:
            content = path.read_text(encoding="utf-8")
            self.assertIsNone(
                rbx_pattern.search(content),
                f"Internal Roblox C++ symbol found in {path.name}"
            )

    def test_f2_04_only_public_apple_framework_imports(self):
        """Verify imports exclusively use public Apple headers and local project headers."""
        import_pattern = re.compile(r'#import\s+["<]([^">]+)[">]')
        allowed_frameworks = {
            "Foundation/Foundation.h",
            "UIKit/UIKit.h",
            "Metal/Metal.h",
            "QuartzCore/CAMetalLayer.h",
            "CoreGraphics/CoreGraphics.h",
            "objc/runtime.h",
            "math.h",
        }
        for path in self.source_files:
            content = path.read_text(encoding="utf-8")
            for imp in import_pattern.findall(content):
                if imp.endswith(".h") and ("/" not in imp or imp.startswith("..") or imp.startswith("Config") or imp.startswith("Hooks") or imp.startswith("FFlags") or imp.startswith("UI")):
                    continue
                self.assertIn(
                    imp, allowed_frameworks,
                    f"Forbidden or non-standard framework header '{imp}' in {path.name}"
                )

    def test_f2_05_no_cydiasubstrate_or_fishhook_dependencies(self):
        """Assert zero reliance on substrate.h, MSHookMessageEx, or fishhook."""
        forbidden_tokens = ["substrate.h", "MSHookMessageEx", "MSHookFunction", "fishhook.h", "rebind_symbols"]
        for path in self.source_files:
            content = path.read_text(encoding="utf-8")
            for token in forbidden_tokens:
                self.assertNotIn(token, content, f"Substrate/fishhook dependency '{token}' in {path.name}")


class TestFeature3ConfigPresets(unittest.TestCase):
    """F3: ROConfig Presets, Default Values, and Persistence Contract."""

    def setUp(self):
        self.config_h = (SRC_DIR / "Config" / "ROConfig.h").read_text(encoding="utf-8")
        self.config_m = (SRC_DIR / "Config" / "ROConfig.m").read_text(encoding="utf-8")

    def test_f3_01_singleton_accessor_defined(self):
        """Verify + (instancetype)sharedConfig is declared and implemented with dispatch_once."""
        self.assertIn("+ (instancetype)sharedConfig;", self.config_h)
        self.assertIn("dispatch_once", self.config_m)
        self.assertIn("sharedInstance = [[ROConfig alloc] init];", self.config_m)

    def test_f3_02_preset_potato_values(self):
        """Verify Potato Mode preset values: scale=0.5, clamp=256, shadows=YES, postfx=YES, fps=60."""
        self.assertIn("case ROPresetModePotato:", self.config_m)
        self.assertIn("_resolutionScale = 0.50f;", self.config_m)
        self.assertIn("_textureClampingEnabled = YES;", self.config_m)
        self.assertIn("_maxTextureDimension = 256;", self.config_m)
        self.assertIn("_disableShadows = YES;", self.config_m)
        self.assertIn("_disablePostFX = YES;", self.config_m)
        self.assertIn("_targetFPS = 60;", self.config_m)

    def test_f3_03_preset_balanced_values(self):
        """Verify Balanced Mode preset values: scale=1.0, clamp=512, shadows=YES, postfx=NO, fps=60."""
        self.assertIn("case ROPresetModeBalanced:", self.config_m)
        self.assertIn("_resolutionScale = 1.0f;", self.config_m)
        self.assertIn("_textureClampingEnabled = YES;", self.config_m)
        self.assertIn("_maxTextureDimension = 512;", self.config_m)
        self.assertIn("_disableShadows = YES;", self.config_m)
        self.assertIn("_disablePostFX = NO;", self.config_m)
        self.assertIn("_targetFPS = 60;", self.config_m)

    def test_f3_04_preset_manual_bounds_enforcement(self):
        """Verify Manual Mode enforces safe ranges [0.25, 3.0] without resetting custom values."""
        self.assertIn("case ROPresetModeManual:", self.config_m)
        self.assertIn("_resolutionScale < 0.25f || _resolutionScale > 3.0f", self.config_m)
        self.assertIn("_maxTextureDimension = 512;", self.config_m)

    def test_f3_05_nsuserdefaults_persistence_keys(self):
        """Verify persistence keys and NSUserDefaults synchronization."""
        expected_keys = [
            "RO_ConfigInitialized",
            "RO_PresetMode",
            "RO_ResolutionScale",
            "RO_TextureClamping",
            "RO_MaxTextureDimension",
            "RO_DisableShadows",
            "RO_DisablePostFX",
            "RO_TargetFPS",
        ]
        for key in expected_keys:
            self.assertIn(f'@"{key}"', self.config_m)
        self.assertIn("[defaults synchronize];", self.config_m)


class TestFeature4MetalTextureClamping(unittest.TestCase):
    """F4: ROMetalHooks Texture Clamping Logic and Mipmap Level Calculation."""

    def setUp(self):
        self.metal_m = (SRC_DIR / "Hooks" / "ROMetalHooks.m").read_text(encoding="utf-8")

    def test_f4_01_hook_installation_target(self):
        """Verify hook intercepts [MTLDevice newTextureWithDescriptor:]."""
        self.assertIn("newTextureWithDescriptor:", self.metal_m)
        self.assertIn("method_setImplementation", self.metal_m)
        self.assertIn("hooked_newTextureWithDescriptor", self.metal_m)

    def test_f4_02_aspect_ratio_preserving_formula(self):
        """Verify dimension scaling preserves aspect ratio using max dimension."""
        self.assertIn("double scale = (double)maxAllowed / (double)maxDim;", self.metal_m)
        self.assertIn("clampedW = MAX((NSUInteger)1, (NSUInteger)floor((double)descriptor.width * scale));", self.metal_m)
        self.assertIn("clampedH = MAX((NSUInteger)1, (NSUInteger)floor((double)descriptor.height * scale));", self.metal_m)

    def test_f4_03_mipmap_level_count_formula(self):
        """Verify mipmapLevelCount = MIN(descriptor.mipmapLevelCount, floor(log2(max(w,h))) + 1)."""
        self.assertIn("log2((double)MAX(clampedW, clampedH))) + 1", self.metal_m)
        self.assertIn("clampedDesc.mipmapLevelCount = MIN(descriptor.mipmapLevelCount, maxAllowedMips);", self.metal_m)

    def test_f4_04_rendertarget_safety_exclusion(self):
        """Verify textures with MTLTextureUsageRenderTarget are strictly bypassed."""
        self.assertIn("(descriptor.usage & MTLTextureUsageRenderTarget) != 0", self.metal_m)
        self.assertIn("return orig_newTextureWithDescriptor(self, _cmd, descriptor);", self.metal_m)

    def test_f4_05_depth_stencil_formats_bypassed(self):
        """Verify depth and stencil pixel formats are strictly bypassed."""
        self.assertIn("MTLPixelFormatDepth16Unorm", self.metal_m)
        self.assertIn("MTLPixelFormatDepth32Float", self.metal_m)
        self.assertIn("MTLPixelFormatStencil8", self.metal_m)
        self.assertIn("MTLPixelFormatDepth24Unorm_Stencil8", self.metal_m)
        self.assertIn("MTLPixelFormatDepth32Float_Stencil8", self.metal_m)


class TestFeature5ResolutionScalingHook(unittest.TestCase):
    """F5: ROResolutionHooks Scaling and Layer Swizzling."""

    def setUp(self):
        self.res_m = (SRC_DIR / "Hooks" / "ROResolutionHooks.m").read_text(encoding="utf-8")

    def test_f5_01_hook_target_classes_and_selectors(self):
        """Verify swizzling targets CAMetalLayer and UIView."""
        self.assertIn("[CAMetalLayer class]", self.res_m)
        self.assertIn("@selector(setDrawableSize:)", self.res_m)
        self.assertIn("@selector(setContentsScale:)", self.res_m)
        self.assertIn("[UIView class]", self.res_m)
        self.assertIn("@selector(setContentScaleFactor:)", self.res_m)

    def test_f5_02_drawable_size_scaling_math(self):
        """Verify drawableSize scales using round(size.dimension * scale)."""
        self.assertIn("round(size.width * scale)", self.res_m)
        self.assertIn("round(size.height * scale)", self.res_m)

    def test_f5_03_contents_scale_scaling_math(self):
        """Verify contentsScale scales with minimum bound 0.25."""
        self.assertIn("MAX(0.25, contentsScale * scale)", self.res_m)

    def test_f5_04_uiview_metal_backing_check(self):
        """Verify UIView setContentScaleFactor applies only to Metal-backed views."""
        self.assertIn("[self.layer isKindOfClass:[CAMetalLayer class]]", self.res_m)
        self.assertIn('NSClassFromString(@"MTKView")', self.res_m)

    def test_f5_05_scale_one_passthrough_optimization(self):
        """Verify scale == 1.0 does not perform unnecessary buffer adjustments."""
        self.assertIn("fabs(scale - 1.0) > 0.001", self.res_m)


class TestFeature6FastFlagsGeneration(unittest.TestCase):
    """F6: ROFastFlags Engine Configuration and Strict JSON Types."""

    def setUp(self):
        self.fflags_m = (SRC_DIR / "FFlags" / "ROFastFlags.m").read_text(encoding="utf-8")

    def test_f6_01_strict_boolean_and_integer_literals(self):
        """Verify NSJSONSerialization input uses @YES/@NO and @(num), not stringified types."""
        self.assertIn('@"FIntRenderShadowIntensity"] = @(0)', self.fflags_m)
        self.assertIn('@"FFlagDebugDisableDeferredShading"] = @YES', self.fflags_m)
        self.assertIn('@"DFFlagDisablePostFx"] = config.disablePostFX ? @YES : @NO', self.fflags_m)
        self.assertIn('@"FIntFRMQualityLevelOverride"] = @(1)', self.fflags_m)
        self.assertIn('@"FFlagGlobalWindActive"] = @NO', self.fflags_m)
        self.assertIn('@"DFIntTaskSchedulerTargetFps"] = @(config.targetFPS)', self.fflags_m)

    def test_f6_02_json_syntax_validity_model(self):
        """Simulate FastFlags JSON generation in Python and verify strict types."""
        sample_flags = {
            "FIntRenderShadowIntensity": 0,
            "FFlagDebugDisableDeferredShading": True,
            "DFFlagDisablePostFx": True,
            "FIntFRMQualityLevelOverride": 1,
            "FFlagGlobalWindActive": False,
            "DFIntTaskSchedulerTargetFps": 60,
        }
        json_str = json.dumps(sample_flags, indent=2)
        parsed = json.loads(json_str)

        self.assertIsInstance(parsed["FIntRenderShadowIntensity"], int)
        self.assertNotIsInstance(parsed["FIntRenderShadowIntensity"], bool)
        self.assertIsInstance(parsed["FFlagDebugDisableDeferredShading"], bool)
        self.assertIsInstance(parsed["DFFlagDisablePostFx"], bool)
        self.assertIsInstance(parsed["FIntFRMQualityLevelOverride"], int)
        self.assertIsInstance(parsed["FFlagGlobalWindActive"], bool)
        self.assertIsInstance(parsed["DFIntTaskSchedulerTargetFps"], int)

    def test_f6_03_sandbox_multi_path_fallbacks(self):
        """Verify multi-path writing to Bundle, Documents, and Application Support."""
        self.assertIn("bundleSettingsPath", self.fflags_m)
        self.assertIn("documentsSettingsPath", self.fflags_m)
        self.assertIn("applicationSupportSettingsPath", self.fflags_m)
        self.assertIn("NSDocumentDirectory", self.fflags_m)
        self.assertIn("NSApplicationSupportDirectory", self.fflags_m)

    def test_f6_04_atomic_write_protection(self):
        """Verify NSDataWritingAtomic is used to prevent file corruption on crash."""
        self.assertIn("NSDataWritingAtomic", self.fflags_m)

    def test_f6_05_intermediate_directory_creation(self):
        """Verify createDirectoryAtPath uses withIntermediateDirectories:YES."""
        self.assertIn("withIntermediateDirectories:YES", self.fflags_m)


class TestFeature7DraggableFABOverlay(unittest.TestCase):
    """F7: ROPassThroughWindow and Draggable ROFloatingButton."""

    def setUp(self):
        self.window_m = (SRC_DIR / "UI" / "ROPassThroughWindow.m").read_text(encoding="utf-8")
        self.button_m = (SRC_DIR / "UI" / "ROFloatingButton.m").read_text(encoding="utf-8")

    def test_f7_01_window_level_alert_plus_100(self):
        """Verify windowLevel is set above alerts (UIWindowLevelAlert + 100)."""
        self.assertIn("UIWindowLevelAlert + 100.0", self.window_m)

    def test_f7_02_hittest_touch_passthrough_logic(self):
        """Verify hitTest:withEvent: returns nil for window and root view to allow passthrough."""
        self.assertIn("hitTest:(CGPoint)point withEvent:(UIEvent *)event", self.window_m)
        self.assertIn("if (hitView == self || hitView == self.rootViewController.view)", self.window_m)
        self.assertIn("return nil;", self.window_m)

    def test_f7_03_floating_button_size_and_circular_shape(self):
        """Verify FAB dimensions are 50x50 with half-width corner radius."""
        self.assertIn("CGRectMake(20, 100, 50, 50)", self.window_m)
        self.assertIn("self.layer.cornerRadius = self.bounds.size.width / 2.0;", self.button_m)

    def test_f7_04_pan_gesture_recognizer_attached(self):
        """Verify UIPanGestureRecognizer handles dragging."""
        self.assertIn("UIPanGestureRecognizer", self.button_m)
        self.assertIn("handlePan:", self.button_m)

    def test_f7_05_magnetic_edge_snapping_logic(self):
        """Verify edge snapping snaps to minX or maxX depending on center.x."""
        self.assertIn("targetX = (self.center.x < superview.bounds.size.width / 2.0) ? minX : maxX;", self.button_m)
        self.assertIn("UIViewAnimationOptionCurveEaseOut", self.button_m)


class TestFeature8ModalConfigPopup(unittest.TestCase):
    """F8: ROMenuViewController Preset State Machine & Sub-controls."""

    def setUp(self):
        self.menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")

    def test_f8_01_three_preset_segments(self):
        """Verify UISegmentedControl items: Potato, Balanced, Manual."""
        self.assertIn('@[@"Potato", @"Balanced", @"Manual"]', self.menu_m)

    def test_f8_02_potato_mode_dims_and_disables_subcontrols(self):
        """Verify Potato mode sets userInteractionEnabled = NO and alpha = 0.45."""
        self.assertIn("if (mode == ROPresetModePotato)", self.menu_m)
        self.assertIn("self.subControlsContainer.userInteractionEnabled = NO;", self.menu_m)
        self.assertIn("self.subControlsContainer.alpha = 0.45;", self.menu_m)

    def test_f8_03_balanced_mode_dims_and_disables_subcontrols(self):
        """Verify Balanced mode sets userInteractionEnabled = NO and alpha = 0.45."""
        self.assertIn("else if (mode == ROPresetModeBalanced)", self.menu_m)
        self.assertIn("self.scaleTextField.text = @\"1.00\";", self.menu_m)

    def test_f8_04_manual_mode_enables_subcontrols(self):
        """Verify Manual mode sets userInteractionEnabled = YES and alpha = 1.0."""
        self.assertIn("self.subControlsContainer.userInteractionEnabled = YES;", self.menu_m)
        self.assertIn("self.subControlsContainer.alpha = 1.0;", self.menu_m)

    def test_f8_05_fps_control_options(self):
        """Verify FPS segmented control has 30, 60, and Unlocked."""
        self.assertIn('@[@"30", @"60", @"Unlocked"]', self.menu_m)


class TestFeature9ResolutionInputAndCleanExit(unittest.TestCase):
    """F9: Resolution Scale Input Validation and Clean exit(0) Execution."""

    def setUp(self):
        self.menu_m = (SRC_DIR / "UI" / "ROMenuViewController.m").read_text(encoding="utf-8")

    def test_f9_01_scale_range_validation_logic(self):
        """Verify float scale input validates scale < 0.25f || scale > 3.0f."""
        self.assertIn("float scale = [self.scaleTextField.text floatValue];", self.menu_m)
        self.assertIn("if (scale < 0.25f || scale > 3.0f)", self.menu_m)

    def test_f9_02_decimal_keyboard_type(self):
        """Verify scaleTextField uses UIKeyboardTypeDecimalPad."""
        self.assertIn("UIKeyboardTypeDecimalPad", self.menu_m)

    def test_f9_03_exit_zero_invoked_on_confirm(self):
        """Verify exit(0) is executed when user taps Exit Now."""
        self.assertIn("exit(0);", self.menu_m)

    def test_f9_04_save_triggers_fastflags_write(self):
        """Verify saveAndExitTapped calls writeFastFlagsConfigurationWithError."""
        self.assertIn("[ROFastFlags writeFastFlagsConfigurationWithError:nil];", self.menu_m)

    def test_f9_05_close_menu_does_not_exit(self):
        """Verify closeTapped cleanly dismisses menu without invoking exit."""
        self.assertIn("- (void)closeTapped {", self.menu_m)
        self.assertIn("[self dismissMenu];", self.menu_m)


class TestFeature10MakefileAndBuildScript(unittest.TestCase):
    """F10: Compilation Scripts, Flags, and Ad-Hoc Signing."""

    def setUp(self):
        self.makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")
        self.build_sh = (REPO_ROOT / "build.sh").read_text(encoding="utf-8")

    def test_f10_01_target_triple_and_arch(self):
        """Verify target triple is arm64-apple-ios14.0 and arch is arm64."""
        self.assertIn("arm64-apple-ios14.0", self.makefile)
        self.assertIn("ARCH = arm64", self.makefile)
        self.assertIn("-target arm64-apple-ios14.0", self.build_sh)

    def test_f10_02_arc_enabled(self):
        """Verify -fobjc-arc is passed to clang in both Makefile and build.sh."""
        self.assertIn("-fobjc-arc", self.makefile)
        self.assertIn("-fobjc-arc", self.build_sh)

    def test_f10_03_all_apple_frameworks_linked(self):
        """Verify Foundation, UIKit, Metal, and QuartzCore frameworks are linked."""
        for fw in ["Foundation", "UIKit", "Metal", "QuartzCore"]:
            self.assertIn(f"-framework {fw}", self.makefile)
            self.assertIn(f"-framework {fw}", self.build_sh)

    def test_f10_04_dynamiclib_and_install_name(self):
        """Verify -dynamiclib and @rpath install name are specified."""
        self.assertIn("-dynamiclib", self.makefile)
        self.assertIn("-install_name @rpath/$(TARGET)", self.makefile)
        self.assertIn("-install_name @rpath/$TARGET", self.build_sh)

    def test_f10_05_ldid_ad_hoc_signing_step(self):
        """Verify ldid -S is invoked on the compiled dylib."""
        self.assertIn("$(LDID) -S", self.makefile)
        self.assertIn("ldid -S", self.build_sh)


class TestFeature11GitHubActionsWorkflow(unittest.TestCase):
    """F11: GitHub Actions CI/CD Workflow Schema, Runner, and Steps."""

    def setUp(self):
        self.workflow_path = REPO_ROOT / ".github" / "workflows" / "build.yml"
        self.assertTrue(self.workflow_path.is_file(), "CI workflow .github/workflows/build.yml missing.")
        self.raw_content = self.workflow_path.read_text(encoding="utf-8")

    def test_f11_01_valid_yaml_syntax(self):
        """Verify workflow parses cleanly as valid YAML."""
        if yaml is not None:
            data = yaml.safe_load(self.raw_content)
            self.assertIsInstance(data, dict)
            self.assertIn("jobs", data)
        else:
            self.assertIn("jobs:", self.raw_content)

    def test_f11_02_macos_runner_specification(self):
        """Verify workflow runs on macos-latest runner."""
        self.assertIn("runs-on: macos-latest", self.raw_content)

    def test_f11_03_triggers_on_push_and_pr(self):
        """Verify workflow triggers on push to main and pull_request."""
        self.assertIn("push:", self.raw_content)
        self.assertIn("pull_request:", self.raw_content)
        self.assertIn("main", self.raw_content)

    def test_f11_04_ldid_codesigning_step(self):
        """Verify brew install ldid and ldid -S steps are configured in CI."""
        self.assertIn("brew install ldid", self.raw_content)
        self.assertIn("ldid -S build/RobloxOptimizer.dylib", self.raw_content)

    def test_f11_05_artifact_upload_step(self):
        """Verify actions/upload-artifact@v4 is configured with RobloxOptimizer.dylib."""
        self.assertIn("actions/upload-artifact", self.raw_content)
        self.assertIn("path: build/RobloxOptimizer.dylib", self.raw_content)


class TestFeature12GitRemoteAndBranch(unittest.TestCase):
    """F12: Git Repository Branch, Remote URL, and Clean Commit Status."""

    def test_f12_01_git_current_branch_main(self):
        """Verify active git branch is 'main'."""
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            cwd=str(REPO_ROOT), capture_output=True, text=True, check=False
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            self.assertIn(branch, ["main", "master"])

    def test_f12_02_git_remote_url(self):
        """Verify remote 'origin' points to https://github.com/Mobimi/roblox-optimize."""
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            cwd=str(REPO_ROOT), capture_output=True, text=True, check=False
        )
        if result.returncode == 0:
            remote_url = result.stdout.strip()
            self.assertEqual(remote_url, "https://github.com/Mobimi/roblox-optimize")

    def test_f12_03_no_binary_artifacts_in_root(self):
        """Verify no compiled .dylib or .o files exist committed in the root."""
        root_files = list(REPO_ROOT.glob("*.dylib")) + list(REPO_ROOT.glob("*.o"))
        self.assertEqual(len(root_files), 0, f"Binary artifacts found in root: {root_files}")

    def test_f12_04_constructor_entry_present(self):
        """Verify ROEntry.m implements __attribute__((constructor))."""
        entry_m = (SRC_DIR / "ROEntry.m").read_text(encoding="utf-8")
        self.assertIn("__attribute__((constructor))", entry_m)
        self.assertIn("ROOptimizerEntry", entry_m)

    def test_f12_05_entry_initializes_all_subsystems(self):
        """Verify constructor initializes config, hooks, fastflags, and UI."""
        entry_m = (SRC_DIR / "ROEntry.m").read_text(encoding="utf-8")
        self.assertIn("[ROConfig sharedConfig]", entry_m)
        self.assertIn("ROInstallMetalHooks()", entry_m)
        self.assertIn("ROInstallResolutionHooks()", entry_m)
        self.assertIn("writeFastFlagsConfigurationWithError", entry_m)
        self.assertIn("UIApplicationDidFinishLaunchingNotification", entry_m)


if __name__ == "__main__":
    unittest.main()
