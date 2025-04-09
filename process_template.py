#!/usr/bin/env python3
"""
Process LaTeX templates for TOCFL worksheets with configurable paper sizes.

This script is used internally by the generator scripts.
"""

def get_template_settings(paper_size='a4'):
    """Return template settings based on paper size."""
    paper_size = paper_size.lower()
    
    # Default settings for A4
    settings = {
        'paper_size': 'a4',
        'margin_size': '1.5cm',
        'font_size': 28,
        'hanzi_width': 5,
        'meaning_width': 10
    }
    
    # Adjust settings based on paper size
    if paper_size == 'b5':
        settings.update({
            'paper_size': 'b5',
            'margin_size': '1.2cm',
            'font_size': 24,
            'hanzi_width': 4,
            'meaning_width': 8
        })
    elif paper_size == 'a5':
        settings.update({
            'paper_size': 'a5',
            'margin_size': '1.0cm',
            'font_size': 20,
            'hanzi_width': 3.5,
            'meaning_width': 7
        })
    elif paper_size == 'letter':
        settings.update({
            'paper_size': 'letter',
            'margin_size': '1.5cm',
            'font_size': 28,
            'hanzi_width': 5,
            'meaning_width': 10
        })
    elif paper_size == 'legal':
        settings.update({
            'paper_size': 'legal',
            'margin_size': '1.5cm',
            'font_size': 28,
            'hanzi_width': 5,
            'meaning_width': 11
        })
    
    return settings

def process_template(template_content, level, paper_size='a4'):
    """Process a template by substituting paper size specific values."""
    settings = get_template_settings(paper_size)
    
    # Replace placeholders with actual values
    processed = template_content
    processed = processed.replace('{PAPER_SIZE}', settings['paper_size'])
    processed = processed.replace('{MARGIN_SIZE}', settings['margin_size'])
    processed = processed.replace('{FONT_SIZE}', str(settings['font_size']))
    processed = processed.replace('{LEVEL_PLACEHOLDER}', f"{{\\Large {level}}}")
    processed = processed.replace('{LEVEL_TITLE}', level)
    
    return processed

def read_template(template_file):
    """Read a template file."""
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading template file: {e}")
        return None

def process_template_file(template_file, level, paper_size='a4'):
    """Process a template file with the specified parameters."""
    template_content = read_template(template_file)
    if template_content:
        return process_template(template_content, level, paper_size)
    return None