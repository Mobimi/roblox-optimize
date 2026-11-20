TARGET = RobloxOptimizer.dylib
BUILD_DIR = build
CC ?= xcrun -sdk iphoneos clang
LDID ?= ldid

SDK_PATH ?= $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ARCH = arm64
TARGET_TRIPLE = arm64-apple-ios14.0

CFLAGS = -target $(TARGET_TRIPLE) \
         -arch $(ARCH) \
         -dynamiclib \
         -fobjc-arc \
         -O2 \
         -Wall \
         -Wextra \
         -install_name @rpath/$(TARGET) \
         -Isrc

ifneq ($(SDK_PATH),)
CFLAGS += -isysroot $(SDK_PATH)
endif

LDFLAGS = -framework Foundation \
          -framework UIKit \
          -framework Metal \
          -framework QuartzCore

SRCS = src/ROEntry.m \
       src/Config/ROConfig.m \
       src/Hooks/ROMetalHooks.m \
       src/Hooks/ROResolutionHooks.m \
       src/FFlags/ROFastFlags.m \
       src/UI/ROPassThroughWindow.m \
       src/UI/ROFloatingButton.m \
       src/UI/ROMenuViewController.m

.PHONY: all clean sign

all: $(BUILD_DIR)/$(TARGET) sign

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(TARGET): $(SRCS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS)

sign: $(BUILD_DIR)/$(TARGET)
	@if command -v $(LDID) >/dev/null 2>&1; then \
		$(LDID) -S $(BUILD_DIR)/$(TARGET); \
		echo "Ad-hoc codesign complete: $(BUILD_DIR)/$(TARGET)"; \
	else \
		echo "Warning: ldid not found. Output binary is unsigned."; \
	fi

clean:
	rm -rf $(BUILD_DIR)
