# Makefile wrapper for CMake build

BUILD_DIR_DEBUG = build-debug
BUILD_DIR_RELEASE = build-release
CMAKE = cmake
MAKE = make

.PHONY: all debug release clean clean-debug clean-release run run-debug run-release install dist fmt help

all: release

debug:
	@mkdir -p $(BUILD_DIR_DEBUG)
	@cd $(BUILD_DIR_DEBUG) && $(CMAKE) -DCMAKE_BUILD_TYPE=Debug .. && $(CMAKE) --build . --config Debug

release:
	@mkdir -p $(BUILD_DIR_RELEASE)
	@cd $(BUILD_DIR_RELEASE) && $(CMAKE) -DCMAKE_BUILD_TYPE=Release .. && $(CMAKE) --build . --config Release

build: release

clean: clean-debug clean-release
	@rm -rf dist

clean-debug:
	@rm -rf $(BUILD_DIR_DEBUG)

clean-release:
	@rm -rf $(BUILD_DIR_RELEASE)

run: run-release

run-debug: debug
	@./$(BUILD_DIR_DEBUG)/leo-pong

run-release: release
	@./$(BUILD_DIR_RELEASE)/leo-pong

install: release
	@rm -rf dist
	@mkdir -p dist
	@cd $(BUILD_DIR_RELEASE) && DESTDIR=../dist $(CMAKE) --build . --target install --config Release
ifeq ($(shell uname),Darwin)
	@echo "Creating macOS app bundle..."
	@mv dist/usr/local/leo-pong.app dist/
	@rm -rf dist/usr
else ifeq ($(OS),Windows_NT)
	@echo "Creating Windows ZIP distribution..."
	@mv "dist/Program Files (x86)/leo_pong/bin/leo-pong.exe" dist/
	@cp -r "dist/Program Files (x86)/leo_pong/share/leo_pong/resources" dist/ 2>/dev/null || true
	@rm -rf "dist/Program Files (x86)"
	@cd dist && powershell -Command "Compress-Archive -Path leo-pong.exe,resources -DestinationPath leo-pong-windows.zip"
	@rm dist/leo-pong.exe
	@rm -rf dist/resources
endif

dist: install

fmt:
	@clang-format -i src/*.c src/*.h

help:
	@echo "Available targets:"
	@echo "  debug       - Build debug version"
	@echo "  release     - Build release version"
	@echo "  build       - Build release version (default)"
	@echo "  clean       - Clean all build files"
	@echo "  clean-debug - Clean debug build files"
	@echo "  clean-release - Clean release build files"
	@echo "  run         - Build and run release version"
	@echo "  run-debug   - Build and run debug version"
	@echo "  run-release - Build and run release version"
	@echo "  install     - Create release build in dist/ folder"
	@echo "  dist        - Same as install"
	@echo "  fmt         - Format source code with clang-format"
	@echo "  help        - Show this help"
