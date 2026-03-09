#!/bin/bash

# Directories
WATCH_DIR="/Users/bsagvari/Library/CloudStorage/OneDrive-tk.mta.hu/SB_Documents/Munka/Egyetem/Corvinus/Faculty teaching/Data practices 2026/Markdown_files"
OUTPUT_DIR="/Users/bsagvari/Library/CloudStorage/OneDrive-tk.mta.hu/SB_Documents/Munka/Egyetem/Corvinus/Faculty teaching/Data practices 2026/HTML_files"
HEADER_FILE="$OUTPUT_DIR/header.html"
CSS_FILE="$OUTPUT_DIR/style.css"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if required files exist
if [ ! -f "$HEADER_FILE" ]; then
    echo "ERROR: header.html not found at $HEADER_FILE"
    exit 1
fi

if [ ! -f "$CSS_FILE" ]; then
    echo "ERROR: style.css not found at $CSS_FILE"
    exit 1
fi

# Conversion function
convert_files() {
    for file in "$WATCH_DIR"/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .md)
            echo "Converting $filename.md..."
            
            pandoc "$file" \
                -o "$OUTPUT_DIR/$filename.html" \
                --standalone \
                --toc \
                --toc-depth=2 \
                --css="style.css" \
                --include-in-header="$HEADER_FILE" \
                --fail-if-warnings=false 2>&1
            
            if [ $? -eq 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - ✓ Converted $filename.md"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - ✗ Failed: $filename.md"
            fi
        fi
    done
}

# Git push function
push_to_git() {
    echo "Pushing to git..."
    cd "$OUTPUT_DIR" || return 1
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "ERROR: Not a git repository at $OUTPUT_DIR"
        return 1
    fi
    
    # Add new/modified HTML files
    git add .html
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "No changes to commit"
        return 0
    fi
    
    # Commit with timestamp
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "Auto-update: Any changes + HTML files converted from markdown [$TIMESTAMP]"
    
    # Push to remote
    if git push origin main 2>&1; then
        echo "✓ Successfully pushed to git"
    else
        echo "✗ Failed to push to git"
        return 1
    fi
}


# Initial conversion
echo "=== Initial conversion of all files ==="
convert_files
push_to_git

echo "=== Watching for changes ==="

# Watch for changes
fswatch -l 3 "$WATCH_DIR" | while read f; do
    echo "Change detected..."
    convert_files
done
