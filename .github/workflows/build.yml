ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:16.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GameOptimizer

GameOptimizer_FILES = \
	Core/Constructor.mm \
	Core/MetalHooks.mm \
	Core/RenderScale.mm \
	Core/MSAA_FXAA.mm \
	Core/ShadowPass.mm \
	Core/Framebuffer.mm \
	Core/MetalFX.mm \
	Core/FPSCap.mm \
	Core/ThreadBoost.mm \
	Core/Settings.mm \
	UI/OverlayWindow.mm \
	UI/MainPanel.mm \
	UI/SliderCell.mm \
	UI/ToggleCell.mm

GameOptimizer_FRAMEWORKS = \
	UIKit \
	Metal \
	QuartzCore \
	Foundation \
	MetalFX \
	MetalKit

GameOptimizer_PRIVATE_FRAMEWORKS = \
	IOKit

GameOptimizer_CFLAGS = \
	-fobjc-arc \
	-O2 \
	-DIOS_TARGET=1 \
	-Wall \
	-fno-modules \
	-fno-cxx-modules \
	-fno-implicit-modules \
	-fno-implicit-module-maps \
	-ICore

GameOptimizer_LDFLAGS = \
	-lc++ \
	-framework CoreGraphics

GameOptimizer_USE_SUBSTRATE = 0

include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
