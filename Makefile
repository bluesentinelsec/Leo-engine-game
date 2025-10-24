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
	@rm -rf dist $(BUILD_DIR_RELEASE)-dist

clean-debug:
	@rm -rf $(BUILD_DIR_DEBUG)

clean-release:
	@rm -rf $(BUILD_DIR_RELEASE)

run: run-release

run-debug: debug
	@./$(BUILD_DIR_DEBUG)/leo-pong

run-release: release
	@./$(BUILD_DIR_RELEASE)/leo-pong

install: 
	@rm -rf dist
	@mkdir -p dist
	@mkdir -p $(BUILD_DIR_RELEASE)-dist
	@cd $(BUILD_DIR_RELEASE)-dist && $(CMAKE) -DCMAKE_BUILD_TYPE=Release -DDIST_BUILD=ON -DCMAKE_INSTALL_PREFIX=/ .. && $(CMAKE) --build . --config Release
	@cd $(BUILD_DIR_RELEASE)-dist && DESTDIR=../dist $(CMAKE) --build . --target install --config Release
ifeq ($(shell uname),Darwin)
	@echo "Creating macOS app bundle..."
	@if [ -d dist/usr/local/leo-pong.app ]; then \
		mv dist/usr/local/leo-pong.app dist/; \
		rm -rf dist/usr; \
	fi
else ifeq ($(OS),Windows_NT)
	@echo "Creating Windows ZIP distribution..."
	@powershell -NoProfile -Command "\
		$root = Get-Location; \
		$dist = Join-Path $root 'dist'; \
		$expected = Join-Path $dist 'leo-pong'; \
		$programFiles = Join-Path $dist 'Program Files'; \
		$programFilesX86 = Join-Path $dist 'Program Files (x86)'; \
		$gitRoot = Join-Path $programFiles 'Git'; \
		$candidates = @($expected, Join-Path $gitRoot 'leo-pong', Join-Path $programFiles 'leo_pong', Join-Path $programFilesX86 'leo_pong'); \
		foreach ($candidate in $candidates) { \
			if (Test-Path $candidate) { \
				if ($candidate -ne $expected) { \
					if (Test-Path $expected) { Remove-Item -Recurse -Force $expected; } \
					Move-Item -Path $candidate -Destination $expected -Force; \
				} \
				break; \
			} \
		} \
		foreach ($cleanup in @($gitRoot, $programFiles, $programFilesX86)) { \
			if (($cleanup -ne $expected) -and (Test-Path $cleanup)) { \
				Remove-Item -Recurse -Force $cleanup; \
			} \
		} \
		if (Test-Path $expected) { \
			$zip = Join-Path $dist 'leo-pong-windows-amd64-dist.zip'; \
			if (Test-Path $zip) { Remove-Item $zip; } \
			Compress-Archive -Path $expected -DestinationPath $zip -Force; \
		} else { \
			Write-Host 'Windows dist: expected directory not found (leo-pong)'; \
		} \
	"
endif
	@rm -rf dist/include dist/lib dist/share dist/usr

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
