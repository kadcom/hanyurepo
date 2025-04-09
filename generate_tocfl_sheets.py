#!/usr/bin/env python3
"""
Generate LaTeX vocabulary sheets from an Excel file of TOCFL vocabulary.

Usage: python3 generate_tocfl_sheets.py Vocab8000.xlsx output.tex [--level "準備級一級"] [--paper b5] [--template template.tex]
"""

import sys
import pandas as pd
import os
import argparse
from process_template import process_template_file, get_template_settings

def generate_latex_preamble(paper_size='a4'):
    """Generate the LaTeX document preamble with configurable paper size."""
    settings = get_template_settings(paper_size)
    
    return f'''\\documentclass[{settings['paper_size']}paper,12pt]{{ctexart}}

% Using ctexart with UTF-8 encoding
\\usepackage{{booktabs}}
\\usepackage{{longtable}}
\\usepackage{{array}}
\\usepackage{{colortbl}}
\\usepackage{{geometry}}
\\usepackage{{xcolor}}
\\usepackage{{fontspec}}

% Page setup with narrower margins
\\geometry{{
  {settings['paper_size']}paper,
  margin={settings['margin_size']},
  includehead
}}

% Set fonts
\\setCJKmainfont{{Kaiti TC}}  % Use Kaiti TC for main Chinese text
\\setCJKsansfont{{Kaiti TC}}  % Use Kaiti TC for sans-serif Chinese text
\\newCJKfontfamily\\hanwangfont{{HanWangKaiMediumChuIn}}

% Custom column format for the practice space and centered hanzi
\\newcolumntype{{P}}[1]{{>{{\\raggedright\\arraybackslash}}p{{#1}}}}
\\newcolumntype{{C}}[1]{{>{{\\centering\\arraybackslash}}p{{#1}}}}

% Custom command for large hanzi with proper vertical spacing
\\newcommand{{\\largehanzi}}[1]{{%
  \\vspace{{0.2cm}}
  {{\\hanwangfont\\fontsize{{{settings['font_size']}pt}}{{34pt}}\\selectfont #1}}
  \\vspace{{0.2cm}}
}}

% Practice row with lines
\\newcommand{{\\practicearea}}{{%
  \\vspace{{0.3cm}}
  \\hrule
  \\vspace{{0.7cm}}
  \\hrule
  \\vspace{{0.3cm}}
}}

\\begin{{document}}

\\begin{{center}}
{{\\LARGE\\bfseries TOCFL 詞彙練習表}} \\\\
\\vspace{{0.5cm}}
'''

def generate_latex_footer():
    """Generate the LaTeX document footer."""
    return r'''\end{document}'''

def generate_vocab_section(title_zh, title_en, vocab_data, paper_size='a4'):
    """Generate a vocabulary section with configurable column widths based on paper size."""
    # Get appropriate column widths
    settings = get_template_settings(paper_size)
    hanzi_width = settings['hanzi_width']
    meaning_width = settings['meaning_width']
    
    latex = f"""% {title_zh} vocabulary
\\section*{{{title_zh} ({title_en})}}
\\begin{{longtable}}{{|C{{{hanzi_width}cm}}|P{{{meaning_width}cm}}|}}
\\hline
\\rowcolor[gray]{{0.9}}
\\textbf{{漢字 (Hanzi)}} & \\textbf{{意思 (Meaning) \\& 練習 (Practice)}} \\\\
\\hline
"""
    
    for _, row in vocab_data.iterrows():
        hanzi = row.get('詞彙\nVocabulary', '')
        
        # Skip empty entries
        if not hanzi:
            continue
            
        latex += f"\\largehanzi{{{hanzi}}} & \\practicearea \\\\\n\\hline\n"
    
    latex += "\\end{longtable}\n\n"
    return latex

def generate_tocfl_worksheet(excel_file, output_file, level='準備級一級(Novice 1)', template_file=None, paper_size='a4'):
    """Generate a TOCFL worksheet for the specified level with configurable paper size."""
    # Read the Excel file
    try:
        df = pd.read_excel(excel_file, sheet_name=level)
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        return False
    
    # Get unique contexts
    if '任務領域\nContext' in df.columns:
        contexts = df['任務領域\nContext'].unique()
    else:
        # For sheets without contexts, create a single section
        contexts = ['詞彙']
    
    # Use template if provided
    if template_file and os.path.exists(template_file):
        processed_template = process_template_file(template_file, level, paper_size)
        if processed_template:
            # Generate content for each context
            latex_content = ""
            settings = get_template_settings(paper_size)
            
            for context in contexts:
                if context == '詞彙':
                    # For sheets without contexts
                    context_data = df
                    title_en = "Vocabulary"
                else:
                    # Filter by context
                    context_data = df[df['任務領域\nContext'] == context]
                    # Get English title
                    context_translations = {
                        '個人資料': 'Personal Information',
                        '工作': 'Work',
                        '教育': 'Education',
                        '房屋與家庭、環境': 'Housing, Family \\& Environment',
                        '日常生活': 'Daily Life',
                        '閒暇時間、娛樂': 'Leisure Time \\& Entertainment',
                        '與他人的關係': 'Relationships with Others',
                        '旅行': 'Travel',
                        '購物': 'Shopping',
                        '飲食': 'Food \\& Drink',
                        '健康及身體照護': 'Health \\& Body Care',
                        '其他': 'Others'
                    }
                    title_en = context_translations.get(context, context)
                
                # Generate section with adjusted column widths
                latex_content += generate_vocab_section(context, title_en, context_data, paper_size)
            
            # Replace content placeholder
            latex = processed_template.replace('{CONTENT_PLACEHOLDER}', latex_content)
        else:
            print(f"Failed to process template file: {template_file}")
            return False
    else:
        # Start the LaTeX document using the preamble function
        latex = generate_latex_preamble(paper_size)
        latex += f"{{\\Large {level}}}\n\\end{{center}}\n\n"
        
        # Generate sections for each context
        for context in contexts:
            if context == '詞彙':
                # For sheets without contexts
                context_data = df
                title_en = "Vocabulary"
            else:
                # Filter by context
                context_data = df[df['任務領域\nContext'] == context]
                # Get English title
                context_translations = {
                    '個人資料': 'Personal Information',
                    '工作': 'Work',
                    '教育': 'Education',
                    '房屋與家庭、環境': 'Housing, Family \\& Environment',
                    '日常生活': 'Daily Life',
                    '閒暇時間、娛樂': 'Leisure Time \\& Entertainment',
                    '與他人的關係': 'Relationships with Others',
                    '旅行': 'Travel',
                    '購物': 'Shopping',
                    '飲食': 'Food \\& Drink',
                    '健康及身體照護': 'Health \\& Body Care',
                    '其他': 'Others'
                }
                title_en = context_translations.get(context, context)
            
            latex += generate_vocab_section(context, title_en, context_data, paper_size)
        
        # Finish the document
        latex += generate_latex_footer()
    
    # Write the output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(latex)
    
    return True

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Generate TOCFL vocabulary worksheets.')
    parser.add_argument('excel_file', help='Input Excel file with vocabulary data')
    parser.add_argument('output_file', help='Output LaTeX file')
    parser.add_argument('--level', default='準備級一級(Novice 1)', help='TOCFL level to generate')
    parser.add_argument('--paper', default='a4', choices=['a4', 'b5', 'a5', 'letter', 'legal'], 
                        help='Paper size (default: a4)')
    parser.add_argument('--template', help='Template file to use (optional)')
    
    # Parse arguments
    args = parser.parse_args()
    
    print(f"Generating worksheet for {args.level} on {args.paper} paper...")
    success = generate_tocfl_worksheet(
        args.excel_file, 
        args.output_file, 
        args.level, 
        args.template, 
        args.paper
    )
    
    if success:
        print(f"Successfully generated {args.output_file}")
        print(f"Compile with: xelatex {args.output_file}")
    else:
        print("Failed to generate worksheet.")

if __name__ == "__main__":
    main()
