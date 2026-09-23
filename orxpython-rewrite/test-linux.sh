#!/usr/bin/env bash
# Run the public ooRexx -> orxpython -> CPython smoke test without installing.
#
# The test deliberately discovers the artifact produced by CMake rather than
# assuming a generator-specific path.  It also supports an ooRexx executable
# from an in-tree development build, which is the usual Termux arrangement.
#
# Overrides:
#   BUILD_DIR           CMake build directory (default: ./build)
#   REXX                ooRexx executable
#   OOREXX_BUILD_ROOT   ooRexx development build tree
#   OOREXX_ROOT         installed ooRexx prefix
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${BUILD_DIR:-$script_dir/build}"
oorexx_build="${OOREXX_BUILD_ROOT:-}"
oorexx_root="${OOREXX_ROOT:-${REXX_HOME:-}}"

library="$(find "$build_dir" -maxdepth 3 -type f \
    \( -name 'liborxpython.so' -o -name 'liborxpython.dylib' -o -name 'orxpython.dll' \) \
    -print -quit 2>/dev/null || true)"
if [[ -z "$library" ]]; then
    echo "error: orxpython has not been built in $build_dir." >&2
    echo "Run ./build-linux.sh first, or set BUILD_DIR to the CMake build directory." >&2
    exit 2
fi
package_dir="$(cd -- "$(dirname -- "$library")" && pwd)"

if [[ -z "$oorexx_build" ]]; then
    for candidate in \
        "$HOME/build/oorexx-xcover-safe" \
        "$HOME/build/oorexx-xcover" \
        "$HOME/build/oorexx"; do
        if [[ -x "$candidate/bin/rexx" ]]; then
            oorexx_build="$candidate"
            break
        fi
    done
fi

if [[ -n "${REXX:-}" ]]; then
    rexx="$REXX"
elif [[ -n "$oorexx_build" && -x "$oorexx_build/bin/rexx" ]]; then
    rexx="$oorexx_build/bin/rexx"
elif [[ -n "$oorexx_root" && -x "$oorexx_root/bin/rexx" ]]; then
    rexx="$oorexx_root/bin/rexx"
elif command -v rexx >/dev/null 2>&1; then
    rexx="$(command -v rexx)"
else
    echo "error: could not locate the ooRexx executable." >&2
    echo "Set REXX or OOREXX_BUILD_ROOT." >&2
    exit 2
fi

runtime_lib_dirs=("$package_dir")
[[ -n "$oorexx_build" && -d "$oorexx_build/lib" ]] && runtime_lib_dirs+=("$oorexx_build/lib")
[[ -n "$oorexx_root" && -d "$oorexx_root/lib" ]] && runtime_lib_dirs+=("$oorexx_root/lib")
runtime_path="$(IFS=:; echo "${runtime_lib_dirs[*]}")"

printf 'ooRexx:          %s\n' "$rexx"
printf 'Native package:  %s\n' "$library"

# Android and Linux both use the ELF loader and LD_LIBRARY_PATH here.
# macOS is not qualified by this script yet.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/smoke.rex"

# Exercise generic Python object semantics through the same native package.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/datetime-smoke.rex"

# Qualify explicit built-in scalar conversion without weakening proxy semantics.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/scalar-smoke.rex"

# Python remains authoritative for exact type and inheritance relationships.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/inheritance-smoke.rex"

# Qualify explicit keyword binding and Python exception translation.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/keyword-smoke.rex"
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/exception-smoke.rex"

# Qualify natural Rexx UNKNOWN syntax over the explicit generic object model.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/unknown-smoke.rex"

# Qualify explicit Rexx-selector -> exact Python-name projection.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/name-projection-smoke.rex"

# Qualify subscription, assignment, len/truth, iteration and slice keys.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/protocol-smoke.rex"

# Qualify Python containment and rich comparison semantics.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/comparison-smoke.rex"

LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" "$rexx" "$script_dir/attribute-smoke.rex"

# Qualify Python class monkey-patching, MethodType instance binding and deletion.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/dynamic-method-smoke.rex"

# Qualify live Python method lookup across inheritance, replacement and deletion.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/dynamic-resolution-smoke.rex"

# Qualify fresh UNKNOWN projection when Python adds/removes a new class member.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/dynamic-projection-smoke.rex"

# Distinguish legitimate Python false values from Python exceptions at the ABI boundary.
LD_LIBRARY_PATH="$runtime_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
PYTHONPATH="$script_dir${PYTHONPATH:+:$PYTHONPATH}" \
    "$rexx" "$script_dir/structured-exception-smoke.rex"
