#!/bin/bash
set -e

# Arguments:
#   1: Bazel target label
#   2: Expected deferred lib count
#   3: Output JS file path
#   4: Path to dart executable
#   5...: Additional arguments for dart compile js

target="$1"
expected_count="$2"
out_dir="$(dirname "$3")"
out_js="$(basename "$3")"
dart_exe="$4"
shift 4

# Run dart compile js with the remaining arguments
"$dart_exe" compile js "$@"

actual_count=$(find "$out_dir" -name "${out_js}_*.part.js" -maxdepth 1 | wc -l | sed -e 's/^[ \t]*//')
if [[ "$actual_count" != "$expected_count" ]]; then
  echo "ERROR: Expected $expected_count deferred library outputs, but found $actual_count."
  echo "Set deferred_lib_count=$actual_count on $target."
  exit 1
fi
