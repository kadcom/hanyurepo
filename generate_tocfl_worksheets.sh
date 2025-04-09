#!/bin/bash
# Master script to generate TOCFL vocabulary worksheets with configurable paper size
# This script runs the entire workflow from Excel file to compiled PDFs

# Usage: ./generate_tocfl_worksheets.sh <excel_file> [paper_size] [template_file]

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: ./generate_tocfl_worksheets.sh <excel_file> [paper_size] [template_file]"
    echo "Example: ./generate_tocfl_worksheets.sh Vocab8000.xlsx b5 tocfl_template_with_titlepage.tex"
    exit 1
fi

EXCEL_FILE="$1"
PAPER_SIZE="${2:-a4}"  # Default to a4 if not specified
TEMPLATE_FILE="${3:-}"  # Optional template file

# Check if the Excel file exists
if [ ! -f "$EXCEL_FILE" ]; then
    echo "Error: Excel file '$EXCEL_FILE' does not exist."
    exit 1
fi

# Check if the template file exists if specified
if [ -n "$TEMPLATE_FILE" ] && [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file '$TEMPLATE_FILE' does not exist."
    exit 1
fi

# Create directories for output files
TEX_DIR="output_tex_${PAPER_SIZE}"
PDF_DIR="output_pdf_${PAPER_SIZE}"

mkdir -p "$TEX_DIR" "$PDF_DIR"
echo "Created directories: $TEX_DIR and $PDF_DIR"

# Generate LaTeX files for all levels
echo "Generating LaTeX files for all levels with paper size: $PAPER_SIZE"
if [ -n "$TEMPLATE_FILE" ]; then
    python3 generate_all_levels.py "$EXCEL_FILE" "$TEX_DIR" --paper "$PAPER_SIZE" --template "$TEMPLATE_FILE"
else
    python3 generate_all_levels.py "$EXCEL_FILE" "$TEX_DIR" --paper "$PAPER_SIZE"
fi

# Check if LaTeX files were generated
if [ $(find "$TEX_DIR" -name "*.tex" | wc -l) -eq 0 ]; then
    echo "Error: No LaTeX files were generated."
    exit 1
fi

echo "Generated $(find "$TEX_DIR" -name "*.tex" | wc -l) LaTeX files."

# Compile LaTeX files to PDFs
echo "Compiling LaTeX files to PDFs..."
./compile_all_worksheets.sh "$TEX_DIR" "$PDF_DIR" "$PAPER_SIZE"

# Check if PDFs were generated
if [ $(find "$PDF_DIR" -name "*.pdf" | wc -l) -eq 0 ]; then
    echo "Error: No PDFs were generated."
    exit 1
fi

echo "Generated $(find "$PDF_DIR" -name "*.pdf" | wc -l) PDF files."

# Ask if the user wants to create a combined PDF
read -p "Do you want to create a combined PDF? (y/n): " CREATE_COMBINED
if [[ "$CREATE_COMBINED" == "y" || "$CREATE_COMBINED" == "Y" ]]; then
    COVER_PDF=""
    read -p "Enter path to cover PDF (leave empty to generate a simple cover): " COVER_PDF
    
    COMBINED_PDF="combined_tocfl_${PAPER_SIZE}.pdf"
    
    if [ -n "$COVER_PDF" ] && [ -f "$COVER_PDF" ]; then
        echo "Using cover PDF: $COVER_PDF"
        ./compile_pdfs.sh "$COVER_PDF" "$PDF_DIR" "$COMBINED_PDF" "$PAPER_SIZE"
    else
        # Create a temporary cover if none is provided
        echo "Generating a simple cover page..."
        TEMP_COVER="$TEX_DIR/temp_cover.tex"
        
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
\\end{document}" > "$TEMP_COVER"
        
        (cd "$PDF_DIR" && pdflatex -interaction=nonstopmode "$TEMP_COVER")
        
        TEMP_COVER_PDF="$PDF_DIR/temp_cover.pdf"
        if [ -f "$TEMP_COVER_PDF" ]; then
            echo "Using generated cover page."
            ./compile_pdfs.sh "$TEMP_COVER_PDF" "$PDF_DIR" "$COMBINED_PDF" "$PAPER_SIZE"
            
            # Clean up temporary files
            rm -f "$TEMP_COVER" "$TEMP_COVER_PDF" "$PDF_DIR/temp_cover.log" "$PDF_DIR/temp_cover.aux"
        else
            echo "Error: Failed to generate cover page. Creating combined PDF without cover."
            ./compile_pdfs.sh "$PDF_DIR/$(ls -1 "$PDF_DIR"/*.pdf | head -1)" "$PDF_DIR" "$COMBINED_PDF" "$PAPER_SIZE"
        fi
    fi
    
    # Check if the combined PDF was created
    if [ -f "$COMBINED_PDF" ]; then
        echo "Successfully created combined PDF: $COMBINED_PDF"
    else
        echo "Error: Failed to create combined PDF."
    fi
fi

echo "All done! Output files:"
echo "- LaTeX files: $TEX_DIR"
echo "- PDF files: $PDF_DIR"
if [ -f "$COMBINED_PDF" ]; then
    echo "- Combined PDF: $COMBINED_PDF"
fi