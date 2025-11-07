cmake_minimum_required(VERSION 3.18.4)

# =========================
# Project
# =========================
set(PROJECT_NAME "leo-pong")

project(${PROJECT_NAME}
        VERSION 0.1.0
        DESCRIPTION "Leo Engine Lua Game"
        HOMEPAGE_URL "https://github.com/bluesentinelsec/leo-engine-game"
        LANGUAGES C
)

set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# =========================
# Runtime search paths (skip for Emscripten)
# =========================
if (NOT EMSCRIPTEN)
    if (APPLE)
        set(_RPATH_LIST "@loader_path/../Frameworks")
    elseif (UNIX)
        set(_RPATH_LIST "\$ORIGIN" "\$ORIGIN/lib")
    endif ()

    if (UNIX AND NOT APPLE)
        set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
        set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
    endif ()

    set(CMAKE_BUILD_RPATH "${_RPATH_LIST}")
    set(CMAKE_INSTALL_RPATH "${_RPATH_LIST}")
endif ()

# =========================
# Options
# =========================
set(LEO_RESOURCES_DIR "resources" CACHE STRING "Fallback resources dir")
set(LEO_RESOURCES_PACK "resources.leopack" CACHE STRING "Optional .leopack file")

# =========================
# Engine (FetchContent for web, local for native)
# =========================
if (EMSCRIPTEN)
    # Use FetchContent for web builds
    include(FetchContent)
    set(LEO_BUILD_SHARED OFF CACHE BOOL "Build Leo as static for web" FORCE)
    set(LEO_BUILD_TESTS OFF CACHE BOOL "Skip tests" FORCE)
    set(LEO_VENDOR_SDL ON CACHE BOOL "Use vendored SDL3" FORCE)

    FetchContent_Declare(
            leo
            GIT_REPOSITORY https://github.com/bluesentinelsec/leo-engine
            GIT_TAG main
    )
    FetchContent_MakeAvailable(leo)
else()
    # Use local Leo Engine for native builds
    find_package(Leo REQUIRED PATHS ../leo-engine/build)
endif()

# =========================
# Sources
# =========================
set(SOURCE_FILES
        src/main.c
)

# =========================
# Executable
# =========================
if (EMSCRIPTEN)
    add_executable(${PROJECT_NAME} ${SOURCE_FILES})
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".html")

    target_link_libraries(${PROJECT_NAME} PRIVATE Leo::Runtime)

    # Conditional preload based on what's available (prefer .leopack for Release)
    set(EMSCRIPTEN_PRELOAD_ARGS "")
    if(CMAKE_BUILD_TYPE STREQUAL "Release" AND EXISTS "${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_PACK}")
        set(EMSCRIPTEN_PRELOAD_ARGS "--preload-file=${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_PACK}@/${LEO_RESOURCES_PACK}")
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_DIR}")
        set(EMSCRIPTEN_PRELOAD_ARGS "--preload-file=${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_DIR}@/${LEO_RESOURCES_DIR}")
    endif()

    target_link_options(${PROJECT_NAME} PRIVATE
        "-sUSE_SDL=3"
        "-sALLOW_MEMORY_GROWTH=1"
        "-sFORCE_FILESYSTEM"
        "-sASYNCIFY"
        "-O3"
        "-sGL_ENABLE_GET_PROC_ADDRESS=1"
        ${EMSCRIPTEN_PRELOAD_ARGS}
    )

else()
    add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SOURCE_FILES})
    target_link_libraries(${PROJECT_NAME} PRIVATE Leo::Runtime)
    
    # Link math library for Unix (non-Apple, non-Emscripten) to fix cos/sin linker errors
    if (UNIX AND NOT APPLE)
        target_link_libraries(${PROJECT_NAME} PRIVATE m)
    endif()

    set(RUNTIME_DIR "$<TARGET_FILE_DIR:${PROJECT_NAME}>")

    # ---- Windows/MSVC delay-load ----
    if (WIN32 AND MSVC)
        target_link_options(${PROJECT_NAME} PRIVATE
                /DELAYLOAD:SDL3.dll
                /DELAYLOAD:leo.dll)
        target_link_libraries(${PROJECT_NAME} PRIVATE delayimp)
        target_compile_definitions(${PROJECT_NAME} PRIVATE LEO_WIN_DELAYLOAD=1)
    endif ()

    if (WIN32 AND MSVC)
        if (CMAKE_BUILD_TYPE STREQUAL "Release")
            set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)
        endif()
    endif()

    set_target_properties(${PROJECT_NAME} PROPERTIES
            BUILD_WITH_INSTALL_RPATH TRUE
            MACOSX_RPATH TRUE
    )

    # =========================
    # Helper scripts
    # =========================
    set(_PACK_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/_package_copy_resources.cmake")
    file(WRITE "${_PACK_SCRIPT}" [=[
        cmake_minimum_required(VERSION 3.25)
        # For Release builds: prefer .leopack, fallback to directory
        # For Debug builds: prefer directory, fallback to .leopack
        if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
            if(DEFINED INPUT_PACK AND EXISTS "${INPUT_PACK}")
                get_filename_component(_pack_name "${INPUT_PACK}" NAME)
                execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${INPUT_PACK}" "${DEST_DIR}/${_pack_name}")
            elseif(DEFINED INPUT_DIR AND IS_DIRECTORY "${INPUT_DIR}")
                if(NOT DEFINED RES_DIR_NAME OR RES_DIR_NAME STREQUAL "")
                    set(RES_DIR_NAME "resources")
                endif()
                execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_directory
                    "${INPUT_DIR}" "${DEST_DIR}/${RES_DIR_NAME}")
            endif()
        else()
            # Debug builds: prefer directory first
            if(DEFINED INPUT_DIR AND IS_DIRECTORY "${INPUT_DIR}")
                if(NOT DEFINED RES_DIR_NAME OR RES_DIR_NAME STREQUAL "")
                    set(RES_DIR_NAME "resources")
                endif()
                execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_directory
                    "${INPUT_DIR}" "${DEST_DIR}/${RES_DIR_NAME}")
            elseif(DEFINED INPUT_PACK AND EXISTS "${INPUT_PACK}")
                get_filename_component(_pack_name "${INPUT_PACK}" NAME)
                execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${INPUT_PACK}" "${DEST_DIR}/${_pack_name}")
            endif()
        endif()
    ]=])

    # =========================
    # Copy resources to build folder
    # =========================
    if (NOT APPLE)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND}
                -D INPUT_PACK=${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_PACK}
                -D INPUT_DIR=${CMAKE_SOURCE_DIR}/${LEO_RESOURCES_DIR}
                -D DEST_DIR=${RUNTIME_DIR}
                -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                -P ${_PACK_SCRIPT}
                COMMENT "Copy resources.leopack or resources/ to build dir"
        )
    endif ()

    # =========================
    # Convenience: run from build tree
    # =========================
    add_custom_target(run
            COMMAND "$<TARGET_FILE:${PROJECT_NAME}>"
            WORKING_DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            DEPENDS ${PROJECT_NAME}
            COMMENT "Run from build tree"
    )
endif ()
