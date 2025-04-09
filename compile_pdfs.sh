#!/bin/bash
# Combine PDF files into a single PDF with a custom cover page
# Uses pdfunite from poppler-utils

# Usage: ./combine_pdfs.sh <cover_pdf> <pdf_directory> <output_pdf>

# Check if pdfunite is installed
if ! command -v pdfunite &> /dev/null; then
    echo "Error: pdfunite is not installed. Please install poppler-utils:"
    echo "  Ubuntu/Debian: sudo apt-get install poppler-utils"
    echo "  macOS: brew install poppler"
    echo "  Fedora: sudo dnf install poppler-utils"
    exit 1
fi

# Check if correct number of arguments provided
if [ $# -ne 3 ]; then
    echo "Usage: ./combine_pdfs.sh <cover_pdf> <pdf_directory> <output_pdf>"
    echo "Example: ./combine_pdfs.sh cover.pdf output_directory combined_tocfl.pdf"
    exit 1
fi

COVER_PDF="$1"
PDF_DIR="$2"
OUTPUT_PDF="$3"

# Check if cover PDF exists
if [ ! -f "$COVER_PDF" ]; then
    echo "Error: Cover PDF '$COVER_PDF' does not exist."
    exit 1
fi

# Check if PDF directory exists
if [ ! -d "$PDF_DIR" ]; then
    echo "Error: PDF directory '$PDF_DIR' does not exist."
    exit 1
fi

# Define the order of TOCFL levels for sorting
LEVELS=(
    "準備級一級" # Novice 1
    "準備級二級" # Novice 2
    "入門級" # Level 1
    "基礎級" # Level 2
    "進階級" # Level 3
    "高階級" # Level 4
    "流利級" # Level 5
)

# Create a temporary directory to store the sorted PDFs
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# First, copy the cover PDF
cp "$COVER_PDF" "$TEMP_DIR/00_cover.pdf"
echo "Added cover: $COVER_PDF"

# Function to find PDFs matching a level pattern
find_level_pdfs() {
    local LEVEL="$1"
    local INDEX="$2"
    local COUNT=0
    
    # Find PDFs containing the level name
    for PDF_FILE in "$PDF_DIR"/*"$LEVEL"*.pdf; do
        if [ -f "$PDF_FILE" ]; then
            COUNT=$((COUNT+1))
            # Use padding to ensure correct sorting
            cp "$PDF_FILE" "$TEMP_DIR/$(printf "%02d_%02d_%s" "$INDEX" "$COUNT" "$(basename "$PDF_FILE")")"
            echo "Added level $LEVEL: $(basename "$PDF_FILE")"
        fi
    done
    
    # Also look for variations without "級" suffix
    if [[ "$LEVEL" == *"級"* ]]; then
        local SHORT_LEVEL="${LEVEL%級}"
        for PDF_FILE in "$PDF_DIR"/*"$SHORT_LEVEL"*.pdf; do
            # Skip files we've already processed
            if [[ "$PDF_FILE" == *"$LEVEL"* ]]; then
                continue
            fi
            
            if [ -f "$PDF_FILE" ]; then
                COUNT=$((COUNT+1))
                cp "$PDF_FILE" "$TEMP_DIR/$(printf "%02d_%02d_%s" "$INDEX" "$COUNT" "$(basename "$PDF_FILE")")"
                echo "Added level $SHORT_LEVEL: $(basename "$PDF_FILE")"
            fi
        done
    fi
}

# Copy PDFs in the specified order
for i in "${!LEVELS[@]}"; do
    find_level_pdfs "${LEVELS[$i]}" "$((i+1))"
done

# Find any remaining PDFs that don't match the specified levels
echo "Looking for additional PDFs..."
for PDF_FILE in "$PDF_DIR"/*.pdf; do
    if [ -f "$PDF_FILE" ]; then
        # Check if we've already copied this file
        BASENAME=$(basename "$PDF_FILE")
        ALREADY_COPIED=0
        
        for COPIED_FILE in "$TEMP_DIR"/*; do
            if [[ "$(basename "$COPIED_FILE")" == *"$BASENAME"* ]]; then
                ALREADY_COPIED=1
                break
            fi
        done
        
        if [ $ALREADY_COPIED -eq 0 ]; then
            cp "$PDF_FILE" "$TEMP_DIR/99_additional_$BASENAME"
            echo "Added additional PDF: $BASENAME"
        fi
    fi
done

# List all PDFs in the temporary directory in order
echo "PDFs to be combined (in order):"
ls -1 "$TEMP_DIR"/*.pdf | sort

# Combine all PDFs using pdfunite
echo "Combining PDFs..."
pdfunite "$TEMP_DIR"/*.pdf "$OUTPUT_PDF"

# Check if the output PDF was created successfully
if [ -f "$OUTPUT_PDF" ]; then
    echo "Successfully created combined PDF: $OUTPUT_PDF"
else
    echo "Error: Failed to create combined PDF."
    exit 1
fi

# Clean up the temporary directory
rm -rf "$TEMP_DIR"
echo "Cleaned up temporary files."