#!/usr/bin/env bash
# Build the orxpython rewrite on Linux and Android/Termux.
#
# ooRexx may be installed conventionally or used directly from separate source
# and build trees.  The latter is common for ooRexx developers and on Termux.
# Explicit environment variables take precedence over automatic discovery:
#
#   OOREXX_ROOT         installed ooRexx prefix
#   OOREXX_SOURCE_ROOT  source tree containing api/oorexxapi.h
#   OOREXX_BUILD_ROOT   build tree containing lib/ and, normally, bin/rexx
#   PYTHON              Python interpreter whose embedding library is required
#
# The script only selects a discovered tree after checking for the files the
# build actually needs.  It does not depend on a particular Android username or
# absolute Termux path.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${BUILD_DIR:-$script_dir/build}"
python="${PYTHON:-$(command -v python3)}"
oorexx_root="${OOREXX_ROOT:-${REXX_HOME:-}}"
oorexx_source="${OOREXX_SOURCE_ROOT:-}"
oorexx_build="${OOREXX_BUILD_ROOT:-}"

if [[ -z "$oorexx_source" && -f "$HOME/src/ooRexx/api/oorexxapi.h" ]]; then
    oorexx_source="$HOME/src/ooRexx"
fi

has_oorexx_libraries() {
    local candidate=$1
    compgen -G "$candidate/lib/librexx.so*" >/dev/null &&
        compgen -G "$candidate/lib/librexxapi.so*" >/dev/null
}

if [[ -z "$oorexx_build" ]]; then
    for candidate in \
        "$HOME/build/oorexx-xcover-safe" \
        "$HOME/build/oorexx-xcover" \
        "$HOME/build/oorexx"; do
        if [[ -d "$candidate" ]] && has_oorexx_libraries "$candidate"; then
            oorexx_build="$candidate"
            break
        fi
    done
fi

if [[ -z "$oorexx_build" && -d "$HOME/build" ]]; then
    while IFS= read -r candidate; do
        if has_oorexx_libraries "$candidate"; then
            oorexx_build="$candidate"
            break
        fi
    done < <(find "$HOME/build" -mindepth 1 -maxdepth 1 -type d \
                  -name 'oorexx-*' -print | sort)
fi

if [[ -z "$oorexx_root" && -z "$oorexx_source" ]]; then
    echo "error: could not locate ooRexx API headers." >&2
    echo "Set OOREXX_ROOT or OOREXX_SOURCE_ROOT." >&2
    exit 2
fi
if [[ -z "$oorexx_root" && -z "$oorexx_build" ]]; then
    echo "error: could not locate ooRexx libraries." >&2
    echo "Set OOREXX_ROOT or OOREXX_BUILD_ROOT." >&2
    exit 2
fi

cmake_args=(
    -S "$script_dir"
    -B "$build_dir"
    -DPython3_EXECUTABLE="$python"
)
[[ -n "$oorexx_root" ]]   && cmake_args+=(-DOOREXX_ROOT="$oorexx_root")
[[ -n "$oorexx_source" ]] && cmake_args+=(-DOOREXX_SOURCE_ROOT="$oorexx_source")
[[ -n "$oorexx_build" ]]  && cmake_args+=(-DOOREXX_BUILD_ROOT="$oorexx_build")

printf 'Source directory: %s\n' "$script_dir"
printf 'Build directory:  %s\n' "$build_dir"
printf 'ooRexx source:    %s\n' "${oorexx_source:-<installed>}"
printf 'ooRexx build:     %s\n' "${oorexx_build:-<installed>}"
printf 'Python:           %s\n' "$python"

cmake "${cmake_args[@]}"
cmake --build "$build_dir" --parallel

library="$(find "$build_dir" -maxdepth 3 -type f \
    \( -name 'liborxpython.so' -o -name 'liborxpython.dylib' -o -name 'orxpython.dll' \) \
    -print -quit)"
if [[ -z "$library" ]]; then
    echo "error: build completed but the orxpython native library was not found." >&2
    exit 1
fi
printf 'Native library:   %s\n' "$library"
