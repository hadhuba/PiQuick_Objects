"""
Objaverse Batch Downloader

This script downloads 3D objects in groups from Objaverse based on a specified list of IDs.
For each group of object IDs:
    - Checks if files are already downloaded to avoid redundant downloads.
    - Downloads missing objects if necessary.
    - Uses multiprocessing to optimize download speed, leveraging available CPU cores.

Parameters:
    --id_file_path: Path to a JSON file containing grouped object IDs.
    --save_path: Directory where downloaded objects will be saved. If not provided, defaults to a path derived from --id_file_path.

Expected Structure of id_file_path JSON:
    The JSON file should be structured with each group containing:
        - A unique group identifier (e.g., "group_1", "group_2").
        - A list with two elements:
            1. A flag (integer) indicating whether to store the files separately (1) or together (0).
               (This element is only used during rendering or grouping.)
            2. A list of unique object IDs (as strings) to download for that group.
            
    Example: src/three_groups.json

Usage:
    python download.py --id_file_path <path_to_ids_json> --save_path <destination_path>
"""

import objaverse
import multiprocessing
import os
import json
import argparse

def search_in_database(folder: str, uids):
    filepaths = []
    ids_to_download = []
    
    if not os.path.exists(folder):
        for uid in uids:
            path_to_id = os.path.join(folder, uid + ".glb")
            filepaths.append(path_to_id)
            ids_to_download = uids
    else:
        downloaded_files = os.listdir(folder)
        downloaded_ids = {file.split('.')[0] for file in downloaded_files}
        for uid in uids:
            path_to_id = os.path.join(folder, uid + ".glb")
            filepaths.append(path_to_id)
            if uid not in downloaded_ids:
                ids_to_download.append(uid)

    return filepaths, ids_to_download
            
def write_group_to_json(group, filepaths, separate):
    id_file_name = os.path.basename(args.id_file_path).split('.')[-2]
    output_json_dir = os.path.join(args.save_path, id_file_name+"_paths")
    os.makedirs(output_json_dir, exist_ok=True)
    
    data = {}
    data[separate]=filepaths

    # json with paths:
    group_json_path = os.path.join(output_json_dir, group+".json")
    with open(group_json_path, "w") as json_file:
        json.dump(data, json_file, indent=2)
    print(f"\nJson file with id paths written for group: {group}\n{group_json_path}\n")

# Argument parsing for input and output file paths
parser = argparse.ArgumentParser()
parser.add_argument("--id_file_path", type=str, required=True)
parser.add_argument("--save_path", type=str)
parser.add_argument("--store_in_save_path",type=int, default=0)
args = parser.parse_args()

# Set default for save_path if not provided
if args.save_path is None:
    args.save_path = os.path.dirname(os.path.abspath(args.id_file_path))
    

# Determine available CPU count for multiprocessing
multiprocessing_cpu_count = multiprocessing.cpu_count()
print(objaverse.__version__)

# Load object IDs from specified JSON file
with open(args.id_file_path, "r") as json_file:
    grouped_ids = json.load(json_file)

# Process each group of IDs
for group, ids in grouped_ids.items():
    uids = ids[1]  # Extract list of object UIDs for this group

    # storing glbs in database
    if not args.store_in_save_path:
        obj_save_path = os.path.join(os.path.dirname(os.path.abspath(__file__).split(os.sep)[-3]), "src", "objects_database")
        os.makedirs(obj_save_path, exist_ok=True)
    # storing glbs in folder given in argument
    else:
        id_file_name = os.path.basename(args.id_file_path).split('.')[-2]
        obj_save_path = os.path.join(args.save_path, id_file_name, group)
        os.makedirs(obj_save_path, exist_ok=True)
        
    # Checking if files are already downloaded
    final_save_path = os.path.join(obj_save_path, "glbs", "000-023")
    print(f"Saving object files to {obj_save_path}")

    filepaths, ids_to_download = search_in_database(final_save_path, uids)
    
    # If all exists
    if not ids_to_download:
        print(f"All files in group '{group}' have already been downloaded.")
    # Start downloading of all files
    elif len(ids_to_download)==len(uids):
        print(f"Downloading all files for group: {group}")
        objaverse._VERSIONED_PATH = obj_save_path
        objaverse.load_objects(
            uids=ids_to_download,
            download_processes=multiprocessing_cpu_count
        )
    else:
        print(f"Downloading remaining files for group: {group}")
        objaverse._VERSIONED_PATH = obj_save_path
        objaverse.load_objects(
            uids=ids_to_download,
            download_processes=multiprocessing_cpu_count
        )

    # write_to_file
    write_group_to_json(group, filepaths, ids[0])
    

print('Download finished.')