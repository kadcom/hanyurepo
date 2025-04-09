#!/bin/bash
# Combine PDF files into a single PDF with a custom cover page
# Uses pdfunite from poppler-utils
# Now supports paper size differentiation in file names

# Usage: ./compile_pdfs.sh <cover_pdf> <pdf_directory> <output_pdf> [paper_size]

# Check if pdfunite is installed
if ! command -v pdfunite &> /dev/null; then
    echo "Error: pdfunite is not installed. Please install poppler-utils:"
    echo "  Ubuntu/Debian: sudo apt-get install poppler-utils"
    echo "  macOS: brew install poppler"
    echo "  Fedora: sudo dnf install poppler-utils"
    exit 1
fi

# Check if correct number of arguments provided
if [ $# -lt 3 ]; then
    echo "Usage: ./compile_pdfs.sh <cover_pdf> <pdf_directory> <output_pdf> [paper_size]"
    echo "Example: ./compile_pdfs.sh cover.pdf output_directory combined_tocfl.pdf b5"
    exit 1
fi

COVER_PDF="$1"
PDF_DIR="$2"
OUTPUT_PDF="$3"
PAPER_SIZE="${4:-a4}"  # Default to a4 if not specified

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

# Function to find PDFs matching a level pattern and paper size
find_level_pdfs() {
    local LEVEL="$1"
    local INDEX="$2"
    local PAPER="$3"
    local COUNT=0
    
    # Find PDFs containing the level name and paper size
    for PDF_FILE in "$PDF_DIR"/*"$LEVEL"*"_$PAPER"*.pdf; do
        if [ -f "$PDF_FILE" ]; then
            COUNT=$((COUNT+1))
            # Use padding to ensure correct sorting
            cp "$PDF_FILE" "$TEMP_DIR/$(printf "%02d_%02d_%s" "$INDEX" "$COUNT" "$(basename "$PDF_FILE")")"
            echo "Added level $LEVEL ($PAPER): $(basename "$PDF_FILE")"
        fi
    done
    
    # Also look for variations without "級" suffix for the specified paper size
    if [[ "$LEVEL" == *"級"* ]]; then
        local SHORT_LEVEL="${LEVEL%級}"
        for PDF_FILE in "$PDF_DIR"/*"$SHORT_LEVEL"*"_$PAPER"*.pdf; do
            # Skip files we've already processed
            if [[ "$PDF_FILE" == *"$LEVEL"* ]]; then
                continue
            fi
            
            if [ -f "$PDF_FILE" ]; then
                COUNT=$((COUNT+1))
                cp "$PDF_FILE" "$TEMP_DIR/$(printf "%02d_%02d_%s" "$INDEX" "$COUNT" "$(basename "$PDF_FILE")")"
                echo "Added level $SHORT_LEVEL ($PAPER): $(basename "$PDF_FILE")"
            fi
        done
    fi
    
    # If no files found with paper size, look for files without paper size specification as fallback
    if [ $COUNT -eq 0 ]; then
        for PDF_FILE in "$PDF_DIR"/*"$LEVEL"*.pdf; do
            # Skip files that have explicit paper size
            if [[ "$PDF_FILE" == *"_a4"* || "$PDF_FILE" == *"_b5"* || "$PDF_FILE" == *"_a5"* || "$PDF_FILE" == *"_letter"* || "$PDF_FILE" == *"_legal"* ]]; then
                continue
            fi
            
            if [ -f "$PDF_FILE" ]; then
                COUNT=$((COUNT+1))
                cp "$PDF_FILE" "$TEMP_DIR/$(printf "%02d_%02d_%s" "$INDEX" "$COUNT" "$(basename "$PDF_FILE")")"
                echo "Added level $LEVEL (no paper size specified): $(basename "$PDF_FILE")"
            fi
        done
        }
    fi
}

# Copy PDFs in the specified order for the specified paper size
for i in "${!LEVELS[@]}"; do
    find_level_pdfs "${LEVELS[$i]}" "$((i+1))" "$PAPER_SIZE"
done

# Find any remaining PDFs that don't match the specified levels but match the paper size
echo "Looking for additional PDFs with paper size $PAPER_SIZE..."
for PDF_FILE in "$PDF_DIR"/*"_$PAPER_SIZE"*.pdf; do
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

# If no files with specified paper size were found, look for any PDFs without paper size specification
if [ $(find "$TEMP_DIR" -name "*.pdf" | wc -l) -le 1 ]; then
    echo "No PDFs found with paper size $PAPER_SIZE, looking for PDFs without paper size specification..."
    for PDF_FILE in "$PDF_DIR"/*.pdf; do
        # Skip files that have explicit paper size
        if [[ "$PDF_FILE" == *"_a4"* || "$PDF_FILE" == *"_b5"* || "$PDF_FILE" == *"_a5"* || "$PDF_FILE" == *"_letter"* || "$PDF_FILE" == *"_legal"* ]]; then
            continue
        fi
        
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
                echo "Added additional PDF (no paper size specified): $BASENAME"
            fi
        fi
    done
fi

# List all PDFs in the temporary directory in order
echo "PDFs to be combined (in order):"
ls -1 "$TEMP_DIR"/*.pdf | sort

# Check if there are PDFs to combine (besides the cover)
if [ $(find "$TEMP_DIR" -name "*.pdf" | wc -l) -le 1 ]; then
    echo "Error: No matching PDFs found to combine."
    rm -rf "$TEMP_DIR"
    exit 1
fi

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