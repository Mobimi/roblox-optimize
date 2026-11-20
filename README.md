# Roblox iOS Optimizer Dylib

A clean, crash-resilient Objective-C dynamic library (`RobloxOptimizer.dylib`) and CI/CD workflow designed to optimize performance and completely eliminate memory (Jetsam) crashes for Roblox iOS sideload and TrollStore users.

Unlike legacy Theos tweaks that rely on brittle assembly hooks or hardcoded Roblox memory offsets (which break on every weekly Roblox update), **Roblox iOS Optimizer** interacts strictly with standard Apple public frameworks (`Metal`, `QuartzCore`, `UIKit`) and the official Roblox FastFlags engine.

---

## Key Features

1. **Metal Texture Clamping (Jetsam Anti-Crash)**
   - Intercepts `[MTLDevice newTextureWithDescriptor:]` using runtime method trampolines.
   - Proactively scales down texture dimensions to a configurable maximum (256 or 512), reducing VRAM footprint by up to 85% in heavy maps (e.g. Blox Fruits, Deepwoken).
   - **Crash-Resilient Mipmap Recalculation**: Automatically recalculates `descriptor.mipmapLevelCount` based on clamped dimensions to prevent fatal Metal driver assertion failures.
   - **Safety Guards**: Never modifies render target surfaces or depth/stencil buffers, guaranteeing pristine framebuffer rendering.

2. **Dynamic Resolution Scaling**
   - Intercepts `CAMetalLayer.drawableSize`, `CAMetalLayer.contentsScale`, and `UIView.contentScaleFactor`.
   - Allows users to scale 3D rendering resolution down (e.g., 0.50 for older devices) or up (up to 3.0) while keeping all 2D UIKit overlays and text completely crisp.

3. **Engine FastFlags Injection (`ClientAppSettings.json`)**
   - Automatically generates and writes strictly-typed FastFlags configurations to `Roblox.app/ClientSettings/ClientAppSettings.json` and fallback `Documents/ClientSettings/ClientAppSettings.json`.
   - Features:
     - Disables dynamic shadow rendering (`FIntRenderShadowIntensity: 0`).
     - Bypasses deferred lighting pass (`FFlagDebugDisableDeferredShading: true`).
     - Disables post-processing effects (`DFFlagDisablePostFx: true`).
     - Enforces graphics quality level 1 (`FIntFRMQualityLevelOverride: 1`).
     - Disables global wind simulation loop (`FFlagGlobalWindActive: false`).
     - Configures task scheduler target FPS (`DFIntTaskSchedulerTargetFps: 30 / 60 / Unlocked`).

4. **In-Game UIKit Control Overlay**
   - Dedicated `UIWindow` at `UIWindowLevelAlert + 100` with touch passthrough (`hitTest:withEvent:` returns `nil` outside interactive controls), allowing uninterrupted gameplay.
   - Draggable Floating Action Button (FAB) with tap-vs-drag disambiguation and magnetic snapping to safe area screen edges.
   - Landscape-optimized popup menu with reactive preset switching, numeric scale text field with input validation, and a "Save & Exit" button that cleanly terminates the app (`exit(0)`) to reload graphics settings.

---

## Presets

| Preset | Scale | Texture Clamping | Shadows | Post-FX | Target FPS | Sub-Controls |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Potato Mode** | `0.50` | `ON (256)` | `Disabled` | `Disabled` | `60` | Dimmed & Locked |
| **Balanced Mode** | `1.00` | `ON (512)` | `Disabled` | `Enabled` | `60` | Dimmed & Locked |
| **Manual Mode** | `0.25 - 3.0` | Configurable | Configurable | Configurable | `30 / 60 / Unlocked` | Fully Enabled |

---

## Project Structure

```
roblox-optimize/
├── .github/
│   └── workflows/
│       └── build.yml               # GitHub Actions CI/CD (macos-latest)
├── src/
│   ├── Config/
│   │   ├── ROConfig.h              # Configuration manager & presets header
│   │   └── ROConfig.m              # NSUserDefaults persistence & preset defaults
│   ├── Hooks/
│   │   ├── ROMetalHooks.h          # Metal texture clamping hook header
│   │   ├── ROMetalHooks.m          # Swizzles [MTLDevice newTextureWithDescriptor:]
│   │   ├── ROResolutionHooks.h     # Resolution scaling hook header
│   │   └── ROResolutionHooks.m     # Swizzles CAMetalLayer & MTKView
│   ├── FFlags/
│   │   ├── ROFastFlags.h           # FastFlags generator & injector header
│   │   └── ROFastFlags.m           # ClientAppSettings.json generation & sandbox write
│   ├── UI/
│   │   ├── ROPassThroughWindow.h   # Transparent touch passthrough window header
│   │   ├── ROPassThroughWindow.m   # hitTest:withEvent: implementation
│   │   ├── ROFloatingButton.h      # Draggable floating action button header
│   │   ├── ROFloatingButton.m      # Pan gesture, edge snap, modal trigger
│   │   ├── ROMenuViewController.h  # Modal settings popup header
│   │   └── ROMenuViewController.m  # Preset state machine, controls, Save & Exit
│   └── ROEntry.m                   # __attribute__((constructor)) entrypoint
├── Makefile                        # POSIX Makefile targeting arm64-apple-ios14.0
├── build.sh                        # Standalone bash build script with ldid signing
└── README.md                       # Documentation & usage guide
```

---

## Building from Source

### Prerequisites
- macOS machine with Xcode and Command Line Tools installed.
- `ldid` for pseudo-codesigning (`brew install ldid`).

### Using `make`
```bash
make
```

### Using `build.sh`
```bash
chmod +x build.sh
./build.sh
```

Compiled binary will be generated at `build/RobloxOptimizer.dylib`.

---

## Sideloading & Installation

### Option 1: TrollStore (Recommended)
1. Install Roblox IPA via TrollStore.
2. Inject `RobloxOptimizer.dylib` using [TrollFools](https://github.com/Lessica/TrollFools) or [Azule](https://github.com/Al4ise/Azule).
3. Open Roblox; the floating ⚡ button will appear on launch.

### Option 2: Sideloading (Sideloadly / Scarlet / Esign)
1. In Sideloadly / Scarlet, select the official decrypted Roblox IPA.
2. In the injection / tweak settings, add `RobloxOptimizer.dylib`.
3. Sign and install the IPA to your iOS device.

---

## License
MIT License.
