import json
import argparse
import os
from pathlib import Path
from typing import List, Dict, Any
"""
This script defines utility functions for managing render settings and creating groups with default configurations. It includes:

get_default_settings(): Returns a dictionary of default rendering settings, 
such as the number of images, resolution, and augmentation options.
create_groups_with_settings(input_groups): 
Accepts a list of groups (each containing a name and object IDs) 
and applies the default render settings to each group, returning a new list of groups with these settings.
"""
def parse_args():
    parser = argparse.ArgumentParser(description="Create render groups JSON file from object IDs")
    parser.add_argument(
        "--path_to_groups",
        type=str,
        required=True,
        help="Path to JSON file containing object IDs and group names"
    )
    parser.add_argument(
        "--save_path",
        type=str,
        required=True,
        help="Path to save the output groups JSON file"
    )
    parser.add_argument(
        "--name",
        type=str,
        required=True,
        help="Name of the output JSON file (without extension)"
    )
    return parser.parse_args()

def get_default_settings():
    """Return default render settings from RenderSettings class"""
    return {
        "num_images": 12,
        "azimuth_aug": True,
        "elevation_aug": False,
        "resolution": 256,
        "mode_multi": True,
        "mode_front_view": False,
        "mode_four_view": False,
        "only_northern_hemisphere": True,
    }

def create_groups_with_settings(input_groups: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Create groups with default render settings applied"""
    result_groups = []
    
    for group in input_groups:
        result_group = {
            "name": group["name"],
            "object_ids": group["object_ids"],
            "settings": get_default_settings()
        }
        result_groups.append(result_group)
    
    return result_groups

def main():
    args = parse_args()
    
    # Create save directory if it doesn't exist
    save_dir = Path(args.save_path)
    save_dir.mkdir(parents=True, exist_ok=True)
    
    # Read input groups JSON
    with open(args.path_to_groups, 'r') as f:
        input_groups = json.load(f)
    
    # Create groups with render settings
    result_groups = create_groups_with_settings(input_groups)
    
    # Save output JSON
    output_path = save_dir / f"{args.name}.json"
    with open(output_path, 'w') as f:
        json.dump(result_groups, f, indent=2)
    
    print(f"Created groups file with render settings at: {output_path}")

if __name__ == "__main__":
    main()