#!/usr/bin/env python3
"""
Generate TOCFL vocabulary worksheets for all levels in the Excel file.

Usage: python3 generate_all_levels.py <excel_file> <output_dir> [template_file]
"""

import sys
import os
import pandas as pd
from generate_tocfl_sheets import generate_tocfl_worksheet

def get_sheet_names(excel_file):
    """Get all sheet names from the Excel file."""
    try:
        xl = pd.ExcelFile(excel_file)
        return xl.sheet_names
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        return []

def generate_all_levels(excel_file, output_dir, template_file=None):
    """Generate worksheets for all levels in the Excel file."""
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Get all sheet names (levels)
    all_levels = get_sheet_names(excel_file)
    
    if not all_levels:
        print("No sheets found in the Excel file.")
        return False
    
    # Define the order of TOCFL levels
    preferred_order = [
        '準備級一級', # Novice 1
        '準備級二級', # Novice 2
        '入門級',    # Level 1
        '基礎級',    # Level 2
        '進階級',    # Level 3
        '高階級',    # Level 4
        '流利級'     # Level 5
    ]
    
    # Sort levels: first the ones in preferred_order, then the rest alphabetically
    levels = []
    
    # First add levels in the preferred order
    for preferred_level in preferred_order:
        for level in all_levels:
            if preferred_level in level:
                levels.append(level)
                all_levels.remove(level)
                break
    
    # Then add any remaining levels
    levels.extend(sorted(all_levels))
    
    # Generate a worksheet for each level
    for level in levels:
        print(f"Generating worksheet for {level}...")
        
        # Create an output filename based on the level
        safe_level_name = level.replace('/', '-').replace('\\', '-').replace(' ', '_')
        output_file = os.path.join(output_dir, f"tocfl_{safe_level_name}.tex")
        
        # Generate the worksheet
        success = generate_tocfl_worksheet(excel_file, output_file, level, template_file)
        
        if success:
            print(f"Successfully generated {output_file}")
        else:
            print(f"Failed to generate worksheet for {level}.")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 generate_all_levels.py <excel_file> <output_dir> [template_file]")
        sys.exit(1)
        
    excel_file = sys.argv[1]
    output_dir = sys.argv[2]
    template_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    print(f"Generating worksheets for all levels...")
    success = generate_all_levels(excel_file, output_dir, template_file)
    
    if success:
        print(f"Finished generating worksheets in {output_dir}")
        print(f"Compile with: xelatex <tex_file>")
    else:
        print("Failed to generate worksheets.")