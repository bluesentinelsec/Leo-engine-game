cmake_minimum_required(VERSION 3.16)
project(leo_pong VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Distribution build option
option(DIST_BUILD "Build for distribution (macOS app bundle)" OFF)

# Platform-specific settings
if(WIN32)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
elseif(APPLE)
    # Universal binaries for macOS
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
    # Target current LTS (macOS 14 Sonoma)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0")
endif()

# Source files
file(GLOB_RECURSE SOURCES "src/*.c")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Platform-specific executable configuration
if(APPLE AND DIST_BUILD)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/misc/Info.plist
        OUTPUT_NAME "leo-pong"
    )
else()
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "leo-pong"
    )
endif()

# Platform-specific linking
if(WIN32)
    # Windows-specific libraries if needed
elseif(APPLE)
    # macOS-specific frameworks if needed
elseif(UNIX)
    # Linux-specific libraries if needed
endif()

# Install target
if(APPLE AND DIST_BUILD)
    install(TARGETS ${PROJECT_NAME}
        BUNDLE DESTINATION .
    )
    install(DIRECTORY resources/
        DESTINATION leo-pong.app/Contents/Resources
        FILES_MATCHING PATTERN "*"
    )
else()
    install(TARGETS ${PROJECT_NAME}
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
    )
    install(DIRECTORY resources/
        DESTINATION share/${PROJECT_NAME}/resources
        FILES_MATCHING PATTERN "*"
    )
endif()
