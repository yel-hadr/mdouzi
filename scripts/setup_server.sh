#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
exec "${SCRIPT_DIR}/setup.sh" "$@"
