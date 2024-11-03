"""
Objaverse Batch Downloader

This script downloads 3D objects in groups from Objaverse based on a specified list of IDs.
For each group of object IDs:
    - Checks if files are already downloaded to avoid redundant downloads.
    - Downloads missing objects if necessary.
    - Uses multiprocessing to optimize download speed, leveraging available CPU cores.
    
Parameters:
    --id_file_path: Path to JSON file containing grouped object IDs.
    --obj_save_path: Destination directory to save downloaded objects.

Expected Structure of id_file_path JSON:
    The JSON file should be organized with each group containing:
        - A unique group identifier (e.g., "group_1", "group_2").
        - A list with two elements:
            1. An integer that indicates wether to render the files separately(1) or together(0).
                (this element is only used during rendering)
            2. A list of unique object IDs (as strings) to download for that group.
            
    Example: src/three_groups.json

Usage:
    python download.py --id_file_path <path_to_ids_json> --obj_save_path <destination_path>
"""

import objaverse
import multiprocessing
import argparse
import os
import json

# Argument parsing for input and output file paths
parser = argparse.ArgumentParser()
parser.add_argument("--id_file_path", type=str, required=True)
parser.add_argument("--obj_save_path", type=str, required=True)
args = parser.parse_args()

# Determine available CPU count for multiprocessing
multiprocessing_cpu_count = multiprocessing.cpu_count()
print(objaverse.__version__)

# Load object IDs from specified JSON file
with open(args.id_file_path, "r") as json_file:
    grouped_ids = json.load(json_file)

# Set base path for Objaverse downloads
objaverse.BASE_PATH = './'

# Process each group of IDs
for group, ids in grouped_ids.items():
    group_save_path = os.path.join(args.obj_save_path, group)
    os.makedirs(group_save_path, exist_ok=True)

    uids = ids[1]  # Extract list of object UIDs for this group

    # Checking if files are already downloaded
    final_save_path = os.path.join(group_save_path, "glbs", "000-023")
    if os.path.exists(final_save_path):
        print(f"{group} path exists; some files may already be downloaded.")
        downloaded_files = os.listdir(final_save_path)
        downloaded_ids = {file.split('.')[0] for file in downloaded_files}  # Extract IDs from filenames
    else:
        print(f"{group} path does not exist; starting new downloads.")
        downloaded_files = []
        downloaded_ids = set()

    # Start downloading files if needed
    if not downloaded_files:
        print(f"Downloading all files for group: {group}")
        objaverse._VERSIONED_PATH = group_save_path
        objaverse.load_objects(
            uids=uids,
            download_processes=multiprocessing_cpu_count
        )
    elif len(downloaded_files) == len(uids):
        print(f"All files in group '{group}' have already been downloaded.")
        continue
    else:
        print(f"Downloading remaining files for group: {group}")
        remaining_uids = [uid for uid in uids if uid not in downloaded_ids]
        objaverse._VERSIONED_PATH = group_save_path
        objaverse.load_objects(
            uids=remaining_uids,
            download_processes=multiprocessing_cpu_count
        )

print('Download finished.')
