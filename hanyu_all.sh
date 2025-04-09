#!/bin/bash
# Simple script to compile all TeX files in a directory

# Default directory is current directory if not specified
TEX_DIR=${1:-.}

# Check if the directory exists
if [[ ! -d "$TEX_DIR" ]]; then
    echo "Error: Directory '$TEX_DIR' not found!"
    exit 1
fi

# Find all .tex files in the directory
TEX_FILES=$(find "$TEX_DIR" -name "*.tex" -type f)

# Check if any .tex files were found
if [[ -z "$TEX_FILES" ]]; then
    echo "No .tex files found in '$TEX_DIR'."
    exit 0
fi

# Count the number of files
FILE_COUNT=$(echo "$TEX_FILES" | wc -l)
echo "Found $FILE_COUNT TeX files in '$TEX_DIR'."
echo ""

# Process each .tex file
COUNTER=0
for tex_file in $TEX_FILES; do
    COUNTER=$((COUNTER + 1))
    file_name=$(basename "$tex_file")
    dir_name=$(dirname "$tex_file")
    
    echo "[$COUNTER/$FILE_COUNT] Compiling: $file_name"
    
    # Change to the directory containing the .tex file and compile
    (cd "$dir_name" && xelatex -interaction=nonstopmode "$file_name")
    
    if [[ $? -eq 0 ]]; then
        echo "✓ Successfully compiled: $file_name"
    else
        echo "✗ Error compiling: $file_name"
    fi
    echo ""
done

echo "Compilation completed!"
echo ""

# List PDF files
echo "Generated PDF files:"
find "$TEX_DIR" -name "*.pdf" -type f -newer "$TEX_FILES" | sort
