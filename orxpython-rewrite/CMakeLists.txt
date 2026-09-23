# Build the orxpython rewrite as an ooRexx native package embedding CPython.
#
# ooRexx can be supplied either as an installed prefix (include/ + lib/) or as
# a source/build pair.  The latter is the normal Termux development layout:
#   OOREXX_SOURCE_ROOT=$HOME/src/ooRexx
#   OOREXX_BUILD_ROOT=$HOME/build/oorexx-xcover-safe
# Android uses ooRexx's Unix platform API headers, so both api/ and
# api/platform/unix are added when building directly from the source tree.
cmake_minimum_required(VERSION 3.18)
project(orxpython LANGUAGES CXX)

find_package(Python3 3.10 REQUIRED COMPONENTS Interpreter Development.Embed)

set(OOREXX_ROOT "$ENV{REXX_HOME}" CACHE PATH "Installed ooRexx prefix")
set(OOREXX_SOURCE_ROOT "" CACHE PATH "ooRexx source tree containing api/oorexxapi.h")
set(OOREXX_BUILD_ROOT "" CACHE PATH "ooRexx build tree containing lib/librexx*.so")

# Header discovery deliberately supports both installed and in-tree ooRexx.
find_path(OOREXX_INCLUDE_DIR oorexxapi.h
    HINTS
        "${OOREXX_SOURCE_ROOT}/api"
        "${OOREXX_ROOT}/include"
        "${OOREXX_ROOT}/api"
    PATHS /usr/local/include /usr/include
    REQUIRED)

# oorexxapi.h includes platform-specific definitions.  Installed packages put
# those where the compiler can already see them; source-tree builds need the
# Unix platform directory explicitly.  Android/Termux uses this Unix API layer.
set(OOREXX_INCLUDE_DIRS "${OOREXX_INCLUDE_DIR}")
if(EXISTS "${OOREXX_SOURCE_ROOT}/api/platform/unix/rexxapitypes.h")
    list(APPEND OOREXX_INCLUDE_DIRS "${OOREXX_SOURCE_ROOT}/api/platform/unix")
endif()

find_library(OOREXX_REXX_LIBRARY NAMES rexx
    HINTS "${OOREXX_BUILD_ROOT}/lib" "${OOREXX_ROOT}/lib"
    PATHS /usr/local/lib /usr/lib
    REQUIRED)
find_library(OOREXX_API_LIBRARY NAMES rexxapi
    HINTS "${OOREXX_BUILD_ROOT}/lib" "${OOREXX_ROOT}/lib"
    PATHS /usr/local/lib /usr/lib
    REQUIRED)

message(STATUS "ooRexx API headers: ${OOREXX_INCLUDE_DIRS}")
message(STATUS "ooRexx runtime library: ${OOREXX_REXX_LIBRARY}")
message(STATUS "ooRexx API library: ${OOREXX_API_LIBRARY}")
message(STATUS "Python embed library: ${Python3_LIBRARIES}")

add_library(orxpython SHARED orxpython.cpp)
target_compile_features(orxpython PRIVATE cxx_std_17)
target_include_directories(orxpython PRIVATE ${OOREXX_INCLUDE_DIRS})
target_link_libraries(orxpython PRIVATE
    Python3::Python
    "${OOREXX_REXX_LIBRARY}"
    "${OOREXX_API_LIBRARY}")
