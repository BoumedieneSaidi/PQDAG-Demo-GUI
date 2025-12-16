#!/usr/bin/env python3
"""
Config Generator for PQDAG Allocation System
This script generates a runtime config.yaml from the template by replacing dynamic variables.
"""

import os
import sys
from pathlib import Path


def generate_config(workspace_root: str, dataset_name: str, output_path: str = None) -> dict:
    """
    Generate allocation config by replacing template variables.
    
    Args:
        workspace_root: Absolute path to PQDAG GUI project root
        dataset_name: Name of the dataset being processed
        output_path: Optional path to save generated config (default: config_runtime.yaml)
    
    Returns:
        Dictionary containing the configuration
    """
    # Read template
    template_path = Path(workspace_root) / 'backend' / 'allocation' / 'config.yaml'
    
    if not template_path.exists():
        raise FileNotFoundError(f"Config template not found: {template_path}")
    
    with open(template_path, 'r', encoding='utf-8') as f:
        config_content = f.read()
    
    # Replace variables
    config_content = config_content.replace('${WORKSPACE_ROOT}', workspace_root)
    config_content = config_content.replace('${DATASET_NAME}', dataset_name)
    
    # Determine output path
    if output_path is None:
        output_path = Path(workspace_root) / 'backend' / 'allocation' / 'config_runtime.yaml'
    
    # Save generated config
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(config_content)
    
    print(f"✅ Config generated: {output_path}")
    print(f"   Workspace: {workspace_root}")
    print(f"   Dataset: {dataset_name}")
    
    # Parse and return as dict (optional)
    import yaml
    config_dict = yaml.safe_load(config_content)
    
    return config_dict


def get_workspace_root() -> str:
    """
    Auto-detect workspace root by looking for characteristic files.
    """
    current = Path.cwd()
    
    # Look for PQDAG GUI root markers
    markers = ['backend', 'frontend', 'storage', 'README.md']
    
    while current != current.parent:
        if all((current / marker).exists() for marker in markers):
            return str(current.absolute())
        current = current.parent
    
    raise RuntimeError("Could not auto-detect PQDAG GUI workspace root")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python generate_config.py <dataset_name> [workspace_root]")
        print("Example: python generate_config.py watdiv100k")
        print("\nIf workspace_root is not provided, it will be auto-detected.")
        sys.exit(1)
    
    dataset_name = sys.argv[1]
    
    # Get workspace root
    if len(sys.argv) >= 3:
        workspace_root = sys.argv[2]
    else:
        try:
            workspace_root = get_workspace_root()
            print(f"📁 Auto-detected workspace: {workspace_root}")
        except RuntimeError as e:
            print(f"❌ Error: {e}")
            print("Please provide workspace_root as second argument.")
            sys.exit(1)
    
    # Ensure workspace_root is absolute
    workspace_root = str(Path(workspace_root).absolute())
    
    # Generate config
    try:
        config = generate_config(workspace_root, dataset_name)
        print("\n📋 Generated configuration:")
        print(f"   Fragment dir: {config['fragment_files_dir']}")
        print(f"   Affectation: {config['affectation_file']}")
        print(f"   Temp dir: {config['temp_dir']}")
    except Exception as e:
        print(f"❌ Error generating config: {e}")
        sys.exit(1)
