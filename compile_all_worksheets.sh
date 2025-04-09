#!/bin/bash
# Compile all TOCFL worksheet LaTeX files to PDFs for a specific paper size
# Requires xelatex to be installed

# Usage: ./compile_all_worksheets.sh <tex_directory> <output_directory> [paper_size]

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: ./compile_all_worksheets.sh <tex_directory> <output_directory> [paper_size]"
    echo "Example: ./compile_all_worksheets.sh latex_files pdf_output b5"
    exit 1
fi

TEX_DIR="$1"
OUTPUT_DIR="$2"
PAPER_SIZE="${3:-a4}"  # Default to a4 if not specified

# Check if xelatex is installed
if ! command -v xelatex &> /dev/null; then
    echo "Error: xelatex is not installed. Please install TeX Live or MiKTeX."
    exit 1
fi

# Check if TEX_DIR exists
if [ ! -d "$TEX_DIR" ]; then
    echo "Error: TeX directory '$TEX_DIR' does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

# Find all LaTeX files for the specified paper size
echo "Compiling LaTeX files for paper size: $PAPER_SIZE"
TEX_FILES=()

# Look for files with the paper size in the filename
for TEX_FILE in "$TEX_DIR"/*"_$PAPER_SIZE"*.tex; do
    if [ -f "$TEX_FILE" ]; then
        TEX_FILES+=("$TEX_FILE")
    fi
done

# If no files found with paper size, look for files without paper size specification
if [ ${#TEX_FILES[@]} -eq 0 ]; then
    echo "No LaTeX files found with paper size $PAPER_SIZE in filename."
    echo "Looking for files without paper size specification..."
    
    for TEX_FILE in "$TEX_DIR"/*.tex; do
        # Skip files that have explicit paper size
        if [[ "$TEX_FILE" == *"_a4"* || "$TEX_FILE" == *"_b5"* || "$TEX_FILE" == *"_a5"* || "$TEX_FILE" == *"_letter"* || "$TEX_FILE" == *"_legal"* ]]; then
            continue
        fi
        
        if [ -f "$TEX_FILE" ]; then
            TEX_FILES+=("$TEX_FILE")
        fi
    done
fi

# Check if we found any files
if [ ${#TEX_FILES[@]} -eq 0 ]; then
    echo "Error: No LaTeX files found."
    exit 1
fi

echo "Found ${#TEX_FILES[@]} LaTeX files to compile."

# Compile each LaTeX file
for TEX_FILE in "${TEX_FILES[@]}"; do
    FILENAME=$(basename "$TEX_FILE" .tex)
    echo "Compiling: $FILENAME.tex"
    
    # Run xelatex in the output directory
    (cd "$OUTPUT_DIR" && xelatex -interaction=nonstopmode "$TEX_FILE")
    
    # Check if the PDF was created successfully
    if [ -f "$OUTPUT_DIR/$FILENAME.pdf" ]; then
        echo "Successfully compiled: $FILENAME.pdf"
    else
        echo "Error: Failed to compile $FILENAME.tex"
    fi
done

echo "Compilation complete. PDFs are in: $OUTPUT_DIR"

# Optional: Create a combined PDF if requested
read -p "Do you want to create a combined PDF? (y/n): " CREATE_COMBINED
if [[ "$CREATE_COMBINED" == "y" || "$CREATE_COMBINED" == "Y" ]]; then
    COVER_PDF=""
    read -p "Enter path to cover PDF (leave empty to skip cover page): " COVER_PDF
    
    COMBINED_PDF="$OUTPUT_DIR/combined_tocfl_$PAPER_SIZE.pdf"
    
    if [ -n "$COVER_PDF" ]; then
        ./compile_pdfs.sh "$COVER_PDF" "$OUTPUT_DIR" "$COMBINED_PDF" "$PAPER_SIZE"
    else
        # Create a temporary cover if none is provided
        echo "\\documentclass[${PAPER_SIZE}paper]{article}
\\usepackage{geometry}
\\geometry{${PAPER_SIZE}paper, margin=1cm}
\\begin{document}
\\begin{center}
\\vspace*{3cm}
{\\huge\\bfseries TOCFL 詞彙練習表}\\\\[1cm]
{\\Large Combined Worksheets}\\\\[0.5cm]
{\\large Paper size: ${PAPER_SIZE}}\\\\[0.5cm]
{\\large \\today}
\\end{center}
\\end{document}" > "$OUTPUT_DIR/temp_cover.tex"
        
        (cd "$OUTPUT_DIR" && pdflatex -interaction=nonstopmode temp_cover.tex)
        ./compile_pdfs.sh "$OUTPUT_DIR/temp_cover.pdf" "$OUTPUT_DIR" "$COMBINED_PDF" "$PAPER_SIZE"
        rm "$OUTPUT_DIR/temp_cover.tex" "$OUTPUT_DIR/temp_cover.pdf" "$OUTPUT_DIR/temp_cover.log" "$OUTPUT_DIR/temp_cover.aux"
    fi
fi

echo "All done!"