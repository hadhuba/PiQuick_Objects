#!/usr/bin/env python3
import argparse
import json
import os
import random
from typing import List, Dict, Any

import objaverse


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create a JSON file with object groups based on Objaverse UIDs"
    )
    parser.add_argument(
        "--group_names", 
        type=str, 
        required=True,
        help="Comma-separated list of group names"
    )
    parser.add_argument(
        "--number_of_glbs", 
        type=str, 
        required=True,
        help="Comma-separated list of number of GLBs per group"
    )
    parser.add_argument(
        "--save_path", 
        type=str, 
        required=True,
        help="Directory path where the JSON file should be saved"
    )
    parser.add_argument(
        "--name", 
        type=str, 
        default="groups",
        help="Name for the JSON file (without extension)"
    )
    return parser.parse_args()


def validate_inputs(group_names: List[str], glbs_per_group: List[int]) -> bool:
    """Validate that there are the same number of group names as numbers of GLBs."""
    if len(group_names) != len(glbs_per_group):
        print(f"Error: Number of group names ({len(group_names)}) does not match "
              f"number of GLB counts ({len(glbs_per_group)})")
        return False
    return True


def create_object_groups(
    group_names: List[str], 
    glbs_per_group: List[int],
    all_uids: List[str]
) -> List[Dict[str, Any]]:
    """Create object groups with randomly assigned UIDs."""
    # Shuffle the UIDs
    random.shuffle(all_uids)
    
    result = []
    used_uids = set()
    uid_index = 0
    
    for i, (name, count) in enumerate(zip(group_names, glbs_per_group)):
        group = {"name": name}
        object_ids = []
        
        # Get unique UIDs for this group
        for _ in range(count):
            # Find a UID that hasn't been used yet
            while uid_index < len(all_uids) and all_uids[uid_index] in used_uids:
                uid_index += 1
            
            if uid_index >= len(all_uids):
                print(f"Warning: Ran out of unique UIDs! Group '{name}' has only {len(object_ids)} objects instead of {count}")
                break
            
            uid = all_uids[uid_index]
            object_ids.append(uid)
            used_uids.add(uid)
            uid_index += 1
        
        group["object_ids"] = object_ids
        
        result.append(group)
    
    return result


def main():
    """Main function to create and save the JSON file."""
    args = parse_arguments()
    
    # Parse group names and GLB counts
    group_names = [name.strip() for name in args.group_names.split(",")]
    try:
        glbs_per_group = [int(count.strip()) for count in args.number_of_glbs.split(",")]
    except ValueError:
        print("Error: number_of_glbs must contain comma-separated integers")
        return 1
    
    # Validate inputs
    if not validate_inputs(group_names, glbs_per_group):
        return 1
    
    # Make sure save directory exists
    os.makedirs(args.save_path, exist_ok=True)
    output_path = os.path.join(args.save_path, f"{args.name}.json")
    
    print("Loading UIDs from Objaverse...")
    all_uids = objaverse.load_uids()
    print(f"Loaded {len(all_uids)} UIDs")
    
    # Create object groups
    print("Creating object groups...")
    object_groups = create_object_groups(group_names, glbs_per_group, all_uids)
    
    # Save to JSON file
    print(f"Saving groups to {output_path}")
    with open(output_path, "w") as f:
        json.dump(object_groups, f, indent=2)
    
    print(f"Successfully created {len(object_groups)} groups with unique object IDs")
    return 0


if __name__ == "__main__":
    exit(main())