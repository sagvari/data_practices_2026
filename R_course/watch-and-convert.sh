#!/bin/bash

set -u

# ----------------------------
# Directories and file paths
# ----------------------------
WATCH_DIR="/Users/bsagvari/Library/CloudStorage/OneDrive-tk.mta.hu/SB_Documents/Munka/Egyetem/Corvinus/Faculty teaching/Data practices 2026/Markdown_files"
OUTPUT_DIR="/Users/bsagvari/Library/CloudStorage/OneDrive-tk.mta.hu/SB_Documents/Munka/Egyetem/Corvinus/Faculty teaching/Data practices 2026/HTML_files"
HEADER_FILE="$OUTPUT_DIR/header.html"
CSS_FILE="$OUTPUT_DIR/style.css"

# ----------------------------
# Basic checks
# ----------------------------
mkdir -p "$OUTPUT_DIR"

if ! command -v pandoc >/dev/null 2>&1; then
    echo "ERROR: pandoc is not installed or not in PATH"
    exit 1
fi

if ! command -v fswatch >/dev/null 2>&1; then
    echo "ERROR: fswatch is not installed or not in PATH"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is not installed or not in PATH"
    exit 1
fi

if [ ! -d "$WATCH_DIR" ]; then
    echo "ERROR: WATCH_DIR does not exist: $WATCH_DIR"
    exit 1
fi

if [ ! -f "$HEADER_FILE" ]; then
    echo "ERROR: header.html not found at $HEADER_FILE"
    exit 1
fi

if [ ! -f "$CSS_FILE" ]; then
    echo "ERROR: style.css not found at $CSS_FILE"
    exit 1
fi

# ----------------------------
# Conversion function
# ----------------------------
convert_files() {
    local converted=0
    local failed=0
    local file
    local filename

    shopt -s nullglob

    for file in "$WATCH_DIR"/*.md; do
        filename=$(basename "$file" .md)
        echo "Converting $filename.md..."

        if pandoc "$file" \
            -o "$OUTPUT_DIR/$filename.html" \
            --standalone \
            --toc \
            --toc-depth=2 \
            --css="style.css" \
            --include-in-header="$HEADER_FILE"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ✓ Converted $filename.md"
            converted=$((converted + 1))
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ✗ Failed: $filename.md"
            failed=$((failed + 1))
        fi
    done

    shopt -u nullglob

    if [ "$converted" -eq 0 ] && [ "$failed" -eq 0 ]; then
        echo "No markdown files found in $WATCH_DIR"
    else
        echo "Conversion summary: $converted succeeded, $failed failed"
    fi
}

# ----------------------------
# Git push function
# ----------------------------
push_to_git() {
    local timestamp
    local git_root
    local html_files

    echo "Pushing to git..."

    cd "$OUTPUT_DIR" || {
        echo "ERROR: Could not cd into $OUTPUT_DIR"
        return 1
    }

    if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        echo "ERROR: Not inside a git repository: $OUTPUT_DIR"
        return 1
    fi

    echo "Git repository root: $git_root"

    shopt -s nullglob
    html_files=( *.html )
    shopt -u nullglob

    if [ ${#html_files[@]} -eq 0 ]; then
        echo "No HTML files to stage in $OUTPUT_DIR"
        return 0
    fi

    git add -- "${html_files[@]}"

    if git diff --cached --quiet; then
        echo "No changes to commit"
        return 0
    fi

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if git commit -m "Auto-update: HTML files converted from markdown [$timestamp]"; then
        if git push origin main; then
            echo "✓ Successfully pushed to git"
        else
            echo "✗ Failed to push to git"
            return 1
        fi
    else
        echo "✗ Commit failed"
        return 1
    fi
}

# ----------------------------
# Main
# ----------------------------
echo "=== Initial conversion of all files ==="
convert_files
push_to_git

echo "=== Watching for changes in $WATCH_DIR ==="

fswatch -o "$WATCH_DIR" | while read -r _; do
    echo "=== Change detected at $(date '+%Y-%m-%d %H:%M:%S') ==="
    convert_files
    push_to_git
done