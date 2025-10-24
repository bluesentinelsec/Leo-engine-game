cmake_minimum_required(VERSION 3.16)
project(leo_pong VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Leo engine dependency
include(FetchContent)
set(LEO_BUILD_SHARED ON CACHE BOOL "Build Leo as shared" FORCE)
set(LEO_BUILD_TESTS OFF CACHE BOOL "Skip tests" FORCE)

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
list(APPEND SOURCES external/getopt/getopt.c)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})
target_include_directories(${PROJECT_NAME} PRIVATE external/getopt)

# Fetch Leo engine and link it
FetchContent_Declare(
        leo
        GIT_REPOSITORY https://github.com/bluesentinelsec/leo-engine
        GIT_TAG main
)
FetchContent_MakeAvailable(leo)


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

if(APPLE)
    # Ensure the bundled app can locate shared libs in its Frameworks directory
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BUILD_RPATH "@executable_path/../Frameworks")
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY INSTALL_RPATH "@executable_path/../Frameworks")
elseif(UNIX)
    # On Linux, load shared libs from alongside the executable
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BUILD_RPATH "\$ORIGIN")
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY INSTALL_RPATH "\$ORIGIN")
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE Leo::Runtime)
if(TARGET SDL3::SDL3-shared)
    target_link_libraries(${PROJECT_NAME} PRIVATE SDL3::SDL3-shared)
endif()

if(TARGET SDL3-shared)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:SDL3-shared>
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
    )
    if(NOT WIN32)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_SONAME_FILE:SDL3-shared>
                $<TARGET_FILE_DIR:${PROJECT_NAME}>/$<TARGET_SONAME_FILE_NAME:SDL3-shared>
        )
    endif()
endif()

if(TARGET Leo::Runtime)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Leo::Runtime>
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
    )
    if(NOT WIN32)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_SONAME_FILE:Leo::Runtime>
                $<TARGET_FILE_DIR:${PROJECT_NAME}>/$<TARGET_SONAME_FILE_NAME:Leo::Runtime>
        )
    endif()
endif()

if(UNIX AND NOT APPLE)
    target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-z,origin")
endif()

# Install target
if(APPLE AND DIST_BUILD)
    install(TARGETS ${PROJECT_NAME}
        BUNDLE DESTINATION .
    )
    install(TARGETS leo
        LIBRARY DESTINATION leo-pong.app/Contents/Frameworks
    )
    if(TARGET SDL3-shared)
        install(TARGETS SDL3-shared
            LIBRARY DESTINATION leo-pong.app/Contents/Frameworks
        )
    endif()
    install(DIRECTORY resources/
        DESTINATION leo-pong.app/Contents/Resources
        FILES_MATCHING PATTERN "*"
    )
else()
    set(_install_runtime_dir "leo-pong")
    install(TARGETS ${PROJECT_NAME}
        RUNTIME DESTINATION ${_install_runtime_dir}
    )
    install(DIRECTORY resources/
        DESTINATION ${_install_runtime_dir}/resources
        FILES_MATCHING PATTERN "*"
    )
    if(TARGET Leo::Runtime)
        install(FILES $<TARGET_FILE:Leo::Runtime>
            DESTINATION ${_install_runtime_dir}
        )
        if(UNIX AND NOT APPLE)
            install(FILES $<TARGET_SONAME_FILE:Leo::Runtime>
                DESTINATION ${_install_runtime_dir}
            )
        endif()
    endif()
    if(TARGET SDL3::SDL3-shared)
        install(FILES $<TARGET_FILE:SDL3::SDL3-shared>
            DESTINATION ${_install_runtime_dir}
        )
        if(UNIX AND NOT APPLE)
            install(FILES $<TARGET_SONAME_FILE:SDL3::SDL3-shared>
                DESTINATION ${_install_runtime_dir}
            )
        endif()
    endif()
    if(WIN32)
        install(CODE [===[
            set(_prefix "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}")
            if(_prefix STREQUAL "")
                set(_prefix "${CMAKE_INSTALL_PREFIX}")
            endif()
            file(TO_CMAKE_PATH "${_prefix}" _prefix)
            set(_candidates
                "${_prefix}/leo-pong"
                "${_prefix}/Program Files/Git/leo-pong"
                "${_prefix}/Program Files/leo_pong"
                "${_prefix}/Program Files (x86)/leo_pong"
            )
            set(_source "")
            foreach(_candidate IN LISTS _candidates)
                if(EXISTS "${_candidate}/leo-pong.exe")
                    set(_source "${_candidate}")
                    break()
                endif()
            endforeach()
            if(_source STREQUAL "")
                file(GLOB_RECURSE _exe_fallback "${_prefix}/leo-pong.exe")
                if(_exe_fallback)
                    list(GET _exe_fallback 0 _tmp_exe)
                    get_filename_component(_source "${_tmp_exe}" DIRECTORY)
                endif()
            endif()

            set(_target_dir "${_prefix}/leo-pong")
            file(MAKE_DIRECTORY "${_target_dir}")

            if(NOT _source STREQUAL "")
                if(NOT _source STREQUAL "${_target_dir}")
                    file(COPY "${_source}/" DESTINATION "${_target_dir}")
                    file(REMOVE_RECURSE "${_source}")
                endif()
            endif()

            set(_bin_candidates
                "${_prefix}/Program Files/Git/bin"
                "${_prefix}/bin"
            )
            foreach(_bin_dir IN LISTS _bin_candidates)
                if(EXISTS "${_bin_dir}")
                    file(GLOB _dlls "${_bin_dir}/*.dll")
                    foreach(_dll IN LISTS _dlls)
                        file(COPY "${_dll}" DESTINATION "${_target_dir}")
                    endforeach()
                    file(REMOVE_RECURSE "${_bin_dir}")
                endif()
            endforeach()

            foreach(_extra "include" "lib" "share" "licenses" "cmake")
                set(_extra_path "${_prefix}/${_extra}")
                if(EXISTS "${_extra_path}")
                    file(REMOVE_RECURSE "${_extra_path}")
                endif()
            endforeach()

            foreach(_maybe "Program Files" "Program Files (x86)")
                set(_maybe_path "${_prefix}/${_maybe}")
                if(EXISTS "${_maybe_path}")
                    file(REMOVE_RECURSE "${_maybe_path}")
                endif()
            endforeach()

            if(EXISTS "${_target_dir}/leo-pong.exe")
                message(STATUS "Windows dist cleanup complete: ${_target_dir}")
            else()
                message(WARNING "Windows dist cleanup: leo-pong.exe not found under ${_target_dir}")
            endif()
        ]===])
    endif()
endif()
