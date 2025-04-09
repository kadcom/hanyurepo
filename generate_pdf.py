#!/usr/bin/env python3
"""
Generate LaTeX vocabulary sheets from an Excel file of TOCFL vocabulary.

Usage: python3 generate_tocfl_sheets.py Vocab8000.xlsx output.tex
"""

import sys
import pandas as pd
import os

def generate_latex_preamble():
    """Generate the LaTeX document preamble."""
    return r'''\documentclass[a4paper,12pt]{ctexart}

% Using ctexart with UTF-8 encoding
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{array}
\usepackage{colortbl}
\usepackage{geometry}
\usepackage{xcolor}
\usepackage{fontspec}

% Page setup with narrower margins
\geometry{
  a4paper,
  margin=1.5cm,
  includehead
}

% Set fonts
\setCJKmainfont{Kaiti TC}  % Use Kaiti TC for main Chinese text
\setCJKsansfont{Kaiti TC}  % Use Kaiti TC for sans-serif Chinese text
\newCJKfontfamily\hanwangfont{HanWangKaiMediumChuIn}

% Custom column format for the practice space and centered hanzi
\newcolumntype{P}[1]{>{\raggedright\arraybackslash}p{#1}}
\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}

% Custom command for large hanzi with proper vertical spacing
\newcommand{\largehanzi}[1]{%
  \vspace{0.2cm}
  {\hanwangfont\fontsize{28pt}{34pt}\selectfont #1}
  \vspace{0.2cm}
}

% Practice row with lines
\newcommand{\practicearea}{%
  \vspace{0.3cm}
  \hrule
  \vspace{0.7cm}
  \hrule
  \vspace{0.3cm}
}

\begin{document}

\begin{center}
{\LARGE\bfseries TOCFL 詞彙練習表} \\
\vspace{0.5cm}
'''

def generate_latex_footer():
    """Generate the LaTeX document footer."""
    return r'''\end{document}'''

def generate_vocab_section(title_zh, title_en, vocab_data):
    """Generate a vocabulary section."""
    latex = f"""% {title_zh} vocabulary
\\section*{{{title_zh} ({title_en})}}
\\begin{{longtable}}{{|C{{5cm}}|P{{10cm}}|}}
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

def generate_tocfl_worksheet(excel_file, output_file, level='準備級一級(Novice 1)'):
    """Generate a TOCFL worksheet for the specified level."""
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
        
    # Start the LaTeX document
    latex = generate_latex_preamble()
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
            # Get English title (placeholder)
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
        
        latex += generate_vocab_section(context, title_en, context_data)
    
    # Finish the document
    latex += generate_latex_footer()
    
    # Write the output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(latex)
    
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 generate_tocfl_sheets.py <excel_file> <output_file> [level]")
        sys.exit(1)
        
    excel_file = sys.argv[1]
    output_file = sys.argv[2]
    level = sys.argv[3] if len(sys.argv) > 3 else '準備級一級(Novice 1)'
    
    print(f"Generating worksheet for {level}...")
    success = generate_tocfl_worksheet(excel_file, output_file, level)
    
    if success:
        print(f"Successfully generated {output_file}")
        print(f"Compile with: xelatex {output_file}")
    else:
        print("Failed to generate worksheet.")
