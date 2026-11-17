#!/bin/sh
# Fail when a tracked file still carries a merge conflict marker: the file is
# a merge someone stopped in the middle of, and nothing else reads it.
#
# Usage: check-merge-markers.sh [root]   (default: this repository's root)
set -eu
root=${1:-$(git rev-parse --show-toplevel)}
# ======= alone is a markdown setext underline, so it counts only beside an opening marker.
opened=$(git -C "$root" grep -IlE '^(<<<<<<< )' -- . || true)
offenders=$opened
if [ -n "$opened" ]; then
    # A while-read loop, not `xargs -r`: that flag is a GNU extension and absent on macOS.
    offenders=$(printf '%s\n' "$opened" | while IFS= read -r file; do
        [ -n "$file" ] || continue
        git -C "$root" grep -qE '^(=======$|>>>>>>> )' -- "$file" 2>/dev/null && printf '%s\n' "$file"
    done)
    [ -n "$offenders" ] || offenders=$opened
fi
if [ -n "$offenders" ]; then
    echo "merge conflict markers committed in:" >&2
    printf '%s\n' "$offenders" | sed "s#^#  #" >&2
    exit 1
fi
