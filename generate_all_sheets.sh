#!/bin/bash
# Script to extract all TOCFL sheets to LaTeX and compile to PDF

# Check if the Python script and Excel file are present
if [[ ! -f "generate_pdf.py" ]]; then
    echo "Error: generate_pdf.py not found!"
    exit 1
fi

if [[ ! -f "Vocab8000.xlsx" ]]; then
    echo "Error: Vocab8000.xlsx not found!"
    exit 1
fi

# Create output directory
mkdir -p output

# Get list of sheets from Excel file
echo "Detecting sheets in Vocab8000.xlsx..."
SHEETS=$(python3 -c "
import pandas as pd
try:
    xls = pd.ExcelFile('Vocab8000.xlsx')
    # Filter out non-TOCFL sheets
    relevant_sheets = [s for s in xls.sheet_names if '級' in s]
    print('\n'.join(relevant_sheets))
except Exception as e:
    print(f'Error: {e}')
    exit(1)
")

# Check if we got any sheets
if [[ -z "$SHEETS" ]]; then
    echo "Error: No TOCFL level sheets found in Excel file"
    exit 1
fi

# Process each sheet
echo "Found the following TOCFL level sheets:"
echo "$SHEETS"
echo ""

for sheet in $SHEETS; do
    # Create safe filename (replace special characters)
    safe_name=$(echo "$sheet" | sed 's/[\/\(\)]/_/g')
    output_tex="output/${safe_name}.tex"
    output_pdf="output/${safe_name}.pdf"
    
    echo "Processing sheet: $sheet"
    echo "  - Generating LaTeX..."
    python3 generate_pdf.py Vocab8000.xlsx "$output_tex" "$sheet"
    
    if [[ $? -ne 0 ]]; then
        echo "  - Error generating LaTeX for $sheet"
        continue
    fi
    
    echo "  - Compiling PDF with XeLaTeX..."
    # Change to output directory for compilation
    (cd output && xelatex -interaction=nonstopmode "${safe_name}.tex")
    
    if [[ $? -ne 0 ]]; then
        echo "  - Error compiling PDF for $sheet"
        continue
    fi
    
    echo "  - Successfully created $output_pdf"
    echo ""
done

# Clean up auxiliary files
echo "Cleaning up auxiliary files..."
rm -f output/*.aux output/*.log output/*.out

echo "All processing complete!"
echo "PDF files are available in the output directory:"
ls -lh output/*.pdf

# Optional: combine all PDFs into one
if command -v pdftk &> /dev/null; then
    echo ""
    echo "Combining all PDFs into a single file..."
    pdftk output/*.pdf cat output output/TOCFL_All_Levels.pdf
    echo "Combined PDF created: output/TOCFL_All_Levels.pdf"
elif command -v pdfunite &> /dev/null; then
    echo ""
    echo "Combining all PDFs into a single file..."
    pdfunite output/*.pdf output/TOCFL_All_Levels.pdf
    echo "Combined PDF created: output/TOCFL_All_Levels.pdf"
fi
