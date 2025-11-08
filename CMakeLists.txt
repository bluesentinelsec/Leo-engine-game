cmake_minimum_required(VERSION 3.16)
project(leo_pong VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Leo engine dependency
include(FetchContent)
if(EMSCRIPTEN)
    set(LEO_BUILD_SHARED OFF CACHE BOOL "Build Leo as static for web" FORCE)
else()
    set(LEO_BUILD_SHARED ON CACHE BOOL "Build Leo as shared" FORCE)
endif()
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
if(EMSCRIPTEN)
    add_executable(${PROJECT_NAME} ${SOURCES})
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".html")
    
    target_link_libraries(${PROJECT_NAME} PRIVATE Leo::Runtime)
    
    # Conditional preload based on what's available
    set(EMSCRIPTEN_PRELOAD_ARGS "")
    if(EXISTS "${CMAKE_SOURCE_DIR}/resources.leopack")
        set(EMSCRIPTEN_PRELOAD_ARGS "--preload-file=${CMAKE_SOURCE_DIR}/resources.leopack@/resources.leopack")
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/resources")
        set(EMSCRIPTEN_PRELOAD_ARGS "--preload-file=${CMAKE_SOURCE_DIR}/resources@/resources")
    endif()
    
    target_link_options(${PROJECT_NAME} PRIVATE
        "-sUSE_SDL=3"
        "-sALLOW_MEMORY_GROWTH=1"
        "-sFORCE_FILESYSTEM"
        "-sASYNCIFY"
        "--shell-file=${CMAKE_SOURCE_DIR}/static/index.html"
        ${EMSCRIPTEN_PRELOAD_ARGS}
    )
else()
    add_executable(${PROJECT_NAME} ${SOURCES})
    target_include_directories(${PROJECT_NAME} PRIVATE external/getopt)
endif()

# Fetch Leo engine and link it
FetchContent_Declare(
        leo
        GIT_REPOSITORY https://github.com/bluesentinelsec/leo-engine
        GIT_TAG main
)
FetchContent_MakeAvailable(leo)

if(NOT EMSCRIPTEN)
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
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE Leo::Runtime)

if(NOT EMSCRIPTEN)
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

    if(NOT (APPLE AND DIST_BUILD))
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${CMAKE_SOURCE_DIR}/resources
                $<TARGET_FILE_DIR:${PROJECT_NAME}>/resources
            COMMENT "Copy game resources next to the executable for runtime access")
    endif()

    if(UNIX AND NOT APPLE)
        target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-z,origin")
    endif()
endif()

# Install target (non-Emscripten only)
if(NOT EMSCRIPTEN)
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
        DESTINATION leo-pong.app/Contents/Resources/resources
        FILES_MATCHING PATTERN "*"
    )

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Resources/resources"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_SOURCE_DIR}/resources
            "$<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Resources/resources"
        COMMENT "Copy game resources into the app bundle")
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
            set(_destdir "$ENV{DESTDIR}")
            if(_destdir STREQUAL "")
                set(_destdir "")
            else()
                file(TO_CMAKE_PATH "${_destdir}" _destdir)
                if(NOT IS_ABSOLUTE "${_destdir}")
                    get_filename_component(_destdir "${CMAKE_CURRENT_BINARY_DIR}/${_destdir}" ABSOLUTE)
                endif()
            endif()

            file(TO_CMAKE_PATH "${CMAKE_INSTALL_PREFIX}" _install_prefix)
            if(_install_prefix MATCHES "^[A-Za-z]:")
                string(SUBSTRING "${_install_prefix}" 2 -1 _install_prefix)
            endif()

            if(_destdir STREQUAL "")
                set(_install_root "${_install_prefix}")
            else()
                set(_install_root "${_destdir}${_install_prefix}")
            endif()
            if(_install_root STREQUAL "")
                if(_destdir STREQUAL "")
                    set(_install_root "${CMAKE_CURRENT_BINARY_DIR}")
                else()
                    set(_install_root "${_destdir}")
                endif()
            endif()

            if(_destdir STREQUAL "")
                set(_dist_root "${_install_root}")
            else()
                set(_dist_root "${_destdir}")
            endif()
            if(_dist_root STREQUAL "")
                set(_dist_root "${CMAKE_CURRENT_BINARY_DIR}/dist")
            endif()

            set(_target_dir "${_dist_root}/leo-pong")
            file(MAKE_DIRECTORY "${_target_dir}")

            set(_candidates
                "${_install_root}/leo-pong"
                "${_install_root}/leo_pong"
                "${_install_root}"
            )
            set(_source "")
            foreach(_candidate IN LISTS _candidates)
                if(EXISTS "${_candidate}/leo-pong.exe")
                    set(_source "${_candidate}")
                    break()
                endif()
            endforeach()
            if(_source STREQUAL "")
                file(GLOB_RECURSE _exe_fallback "${_install_root}/leo-pong.exe")
                if(_exe_fallback)
                    list(GET _exe_fallback 0 _tmp_exe)
                    get_filename_component(_source "${_tmp_exe}" DIRECTORY)
                endif()
            endif()

            if(NOT _source STREQUAL "")
                if(NOT _source STREQUAL "${_target_dir}")
                    file(COPY "${_source}/" DESTINATION "${_target_dir}")
                    if(NOT _source STREQUAL "${_install_root}")
                        file(REMOVE_RECURSE "${_source}")
                    endif()
                endif()
            endif()

            set(_bin_candidates
                "${_install_root}/bin"
                "${_install_root}/../bin"
            )
            if(NOT _dist_root STREQUAL "")
                list(APPEND _bin_candidates "${_dist_root}/bin")
            endif()
            foreach(_bin_dir IN LISTS _bin_candidates)
                if(EXISTS "${_bin_dir}")
                    file(GLOB _dlls "${_bin_dir}/*.dll")
                    foreach(_dll IN LISTS _dlls)
                        file(COPY "${_dll}" DESTINATION "${_target_dir}")
                    endforeach()
                    if(NOT _bin_dir STREQUAL "${_target_dir}")
                        file(REMOVE_RECURSE "${_bin_dir}")
                    endif()
                endif()
            endforeach()

            if(NOT _install_root STREQUAL "" AND NOT _install_root STREQUAL "${_target_dir}")
                file(REMOVE_RECURSE "${_install_root}")
            endif()

            foreach(_extra "include" "lib" "share" "licenses" "cmake")
                set(_extra_path "${_dist_root}/${_extra}")
                if(EXISTS "${_extra_path}")
                    file(REMOVE_RECURSE "${_extra_path}")
                endif()
            endforeach()

            foreach(_maybe "Program Files" "Program Files (x86)")
                set(_maybe_path "${_dist_root}/${_maybe}")
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