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

# Optional second argument / env var to control PDF copy behavior:
# - pass second arg "--out-only" to keep final PDF only in out/
# - pass "--pdf-root" to copy PDF to repo root (default behavior)
# - or set environment variable BUILD_PDF_DEST=out|root
COPY_PDF=false
if [ "$#" -ge 2 ]; then
  case "$2" in
    --out-only) COPY_PDF=false ;;
    --pdf-root) COPY_PDF=true ;;
    *) ;;
  esac
fi
if [ "${BUILD_PDF_DEST:-}" = "out" ]; then
  COPY_PDF=false
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

# First run: create intermediates in out/
latexmk -pdf -interaction=nonstopmode -synctex=1 -outdir=out "${relpath}"

# If makeglossaries is available, run it against the files in out/
if command -v makeglossaries >/dev/null 2>&1; then
  if [ -f "out/${name}.aux" ]; then
    # copy generated .ist into repo root so makeindex can find it
    IST_BACKUP=""
    COPIED_IST=false
    if [ -f "out/${name}.ist" ]; then
      # if a .ist already exists in repo root, move it to out/ as a backup
      if [ -f "${repo_root}/${name}.ist" ]; then
        IST_BACKUP="out/${name}.ist.prebuild.$$"
        mv "${repo_root}/${name}.ist" "${repo_root}/${IST_BACKUP}"
      fi
      cp "out/${name}.ist" "${repo_root}/${name}.ist"
      COPIED_IST=true
    fi
    makeglossaries "out/${name}" || true
    # cleanup: always remove the .ist from repo root so it only lives in out/
    if [ -f "${repo_root}/${name}.ist" ]; then
      rm -f "${repo_root}/${name}.ist" || true
    fi
  fi
fi

# Second run: finalize document (resolve glossaries/bib)
latexmk -pdf -interaction=nonstopmode -synctex=1 -outdir=out "${relpath}"

# Copy the final PDF to project root (no-op if already there)
if [ "$COPY_PDF" = true ]; then
  cp "out/${name}.pdf" "${repo_root}/${name}.pdf"
fi

# If we're not copying PDFs to the repo root, remove any existing root copy to avoid confusion
if [ "$COPY_PDF" != true ]; then
  if [ -f "${repo_root}/${name}.pdf" ]; then
    rm -f "${repo_root}/${name}.pdf" || true
  fi
fi

exit 0
