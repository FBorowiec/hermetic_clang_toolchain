#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"

# check if linking command
if [[ "$*" == *"-o"* ]] && [[ "$*" == *".o"* ]]; then
	# use clang for linking with lld
	exec "$SCRIPT_DIR/bin/clang" -fuse-ld=lld "$@"
else
	# regular compilation
	exec "$SCRIPT_DIR/bin/clang" "$@"
fi
