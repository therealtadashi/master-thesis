#!/usr/bin/env bash
set -euo pipefail

# Determine script and repository root directories
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

# Usage: build.sh <texfile>
# If no argument given, use main.tex in the repo root
if [ "$#" -ge 1 ]; then
  texfile="$1"
else
  texfile="$repo_root/main.tex"
fi

# If a relative path was passed, interpret it relative to the repo root
if [[ "$texfile" != /* ]]; then
  texfile="$repo_root/${texfile}"
fi

cd "$repo_root"
mkdir -p out


# Compute path relative to repo root so files in subfolders work
relpath="${texfile#$repo_root/}"
basename=$(basename "${relpath}")
name="${basename%.*}"

# Run latexmk in repo root, write intermediates to out/
latexmk -pdf -interaction=nonstopmode -synctex=1 -outdir=out "${relpath}"

exit 0
