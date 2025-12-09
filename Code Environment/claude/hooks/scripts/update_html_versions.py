#!/usr/bin/env python3
"""
CDN VERSION UPDATER
───────────────────────────────────────────────────────────────
Increments version parameters in HTML files to force browser
cache invalidation after JavaScript/CSS changes.

Usage:
  python3 .claude/hooks/scripts/update_html_versions.py

Example:
  Before: hero_video.js?v=1.1.27
  After:  hero_video.js?v=1.1.28

Author: Auto-generated
Date: 2025-11-22
Version: 1.0.0
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict

# ───────────────────────────────────────────────────────────────
# CONFIGURATION
# ───────────────────────────────────────────────────────────────

# CDN URL pattern to match
CDN_URL_PATTERN = r'https://pub-85443b585f1e4411ab5cc976c4fb08ca\.r2\.dev/'

# Version parameter pattern (e.g., ?v=1.1.27)
VERSION_PATTERN = r'\?v=(\d+)\.(\d+)\.(\d+)'

# HTML files directory
HTML_DIR = 'src/0_html'

# File extensions to process
HTML_EXTENSIONS = ['.html']


# ───────────────────────────────────────────────────────────────
# VERSION INCREMENTER
# ───────────────────────────────────────────────────────────────

def increment_version(version_string: str) -> str:
    """
    Increment the patch version number.
    
    Args:
        version_string: Version in format "1.1.27"
    
    Returns:
        Incremented version string "1.1.28"
    """
    match = re.match(r'(\d+)\.(\d+)\.(\d+)', version_string)
    if not match:
        return version_string
    
    major, minor, patch = match.groups()
    new_patch = int(patch) + 1
    return f"{major}.{minor}.{new_patch:02d}"


def update_cdn_versions(content: str) -> Tuple[str, int, Dict[str, str]]:
    """
    Update all CDN version parameters in HTML content.
    
    Args:
        content: HTML file content
    
    Returns:
        Tuple of (updated_content, change_count, version_changes)
    """
    change_count = 0
    version_changes = {}
    
    # Pattern to match CDN URLs with version parameters
    pattern = re.compile(
        rf'({CDN_URL_PATTERN}[\w_.-]+\.(?:js|css)){VERSION_PATTERN}'
    )
    
    def replace_version(match):
        nonlocal change_count
        url_base = match.group(1)
        major = match.group(2)
        minor = match.group(3)
        patch = match.group(4)
        
        old_version = f"{major}.{minor}.{patch}"
        new_version = increment_version(old_version)
        
        # Extract filename for logging
        filename = url_base.split('/')[-1]
        version_changes[filename] = (old_version, new_version)
        
        change_count += 1
        return f"{url_base}?v={new_version}"
    
    updated_content = pattern.sub(replace_version, content)
    return updated_content, change_count, version_changes


# ───────────────────────────────────────────────────────────────
# FILE PROCESSOR
# ───────────────────────────────────────────────────────────────

def process_html_file(file_path: Path) -> Tuple[bool, int, Dict[str, str]]:
    """
    Process a single HTML file and update version parameters.
    
    Args:
        file_path: Path to HTML file
    
    Returns:
        Tuple of (success, change_count, version_changes)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        updated_content, change_count, version_changes = update_cdn_versions(content)
        
        if change_count > 0:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(updated_content)
            return True, change_count, version_changes
        
        return True, 0, {}
    
    except Exception as e:
        print(f"✗ Error processing {file_path}: {e}", file=sys.stderr)
        return False, 0, {}


def find_html_files(base_dir: Path) -> List[Path]:
    """
    Find all HTML files in the directory tree.
    
    Args:
        base_dir: Base directory to search
    
    Returns:
        List of HTML file paths
    """
    html_files = []
    for ext in HTML_EXTENSIONS:
        html_files.extend(base_dir.rglob(f'*{ext}'))
    return sorted(html_files)


# ───────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ───────────────────────────────────────────────────────────────

def main():
    """Main execution function."""
    # Find project root (git repository root)
    try:
        import subprocess
        git_root = subprocess.check_output(
            ['git', 'rev-parse', '--show-toplevel'],
            stderr=subprocess.DEVNULL
        ).decode('utf-8').strip()
        project_root = Path(git_root)
    except:
        # Fallback: assume script is in .claude/hooks/scripts/
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent.parent
    
    html_dir = project_root / HTML_DIR
    
    if not html_dir.exists():
        print(f"✗ HTML directory not found: {html_dir}", file=sys.stderr)
        sys.exit(1)
    
    print("⚡ CDN VERSION UPDATER")
    print("───────────────────────────────────────────────────────────────")
    print(f"Project root: {project_root}")
    print(f"HTML directory: {html_dir}")
    print("")
    
    # Find all HTML files
    html_files = find_html_files(html_dir)
    
    if not html_files:
        print("✗ No HTML files found")
        sys.exit(1)
    
    print(f"Found {len(html_files)} HTML file(s)")
    print("")
    
    # Process each file
    total_changes = 0
    files_modified = 0
    all_version_changes = {}
    
    for file_path in html_files:
        rel_path = file_path.relative_to(project_root)
        success, change_count, version_changes = process_html_file(file_path)
        
        if success and change_count > 0:
            files_modified += 1
            total_changes += change_count
            print(f"✓ {rel_path}")
            
            # Merge version changes
            for filename, (old_v, new_v) in version_changes.items():
                if filename not in all_version_changes:
                    all_version_changes[filename] = (old_v, new_v)
            
            # Show changes for this file
            for filename, (old_v, new_v) in version_changes.items():
                print(f"  └─ {filename}: v{old_v} → v{new_v}")
    
    print("")
    print("───────────────────────────────────────────────────────────────")
    
    if files_modified > 0:
        print(f"✓ Updated {files_modified} file(s) with {total_changes} version change(s)")
        print("")
        print("Summary of version changes:")
        for filename, (old_v, new_v) in sorted(all_version_changes.items()):
            print(f"  • {filename}: v{old_v} → v{new_v}")
    else:
        print("✓ No version parameters found to update")
    
    print("")
    print("Next steps:")
    print("  1. Review changes: git diff src/0_html/")
    print("  2. Test locally before deploying")
    print("  3. Deploy updated HTML to Webflow")
    print("───────────────────────────────────────────────────────────────")


if __name__ == '__main__':
    main()
