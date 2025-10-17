cmake_minimum_required(VERSION 3.16)
project(leo_pong VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Platform-specific settings
if(WIN32)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

# Source files
file(GLOB_RECURSE SOURCES "src/*.c")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Platform-specific linking
if(WIN32)
    # Windows-specific libraries if needed
elseif(APPLE)
    # macOS-specific frameworks if needed
elseif(UNIX)
    # Linux-specific libraries if needed
endif()

# Install target
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Copy resources
install(DIRECTORY resources/
    DESTINATION share/${PROJECT_NAME}/resources
    FILES_MATCHING PATTERN "*"
)
