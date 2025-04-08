
"""
Objaverse Batch Downloader

This script downloads 3D objects in groups from Objaverse based on a specified list of IDs.
For each group of object IDs:
    - Checks if files are already downloaded to avoid redundant downloads.
    - Downloads missing objects if necessary.
    - Uses multiprocessing to optimize download speed, leveraging available CPU cores.
    - Saves the file paths of downloaded objects in a JSON file for each group.

Parameters:
    --[REQUIRED] groups_json: Path to a JSON file containing grouped object IDs and settings.
    --save_path: Directory where JSON files with object paths will be saved. Defaults to the directory of the input JSON file if not provided.
    --store_path: Directory where downloaded objects will be stored. Defaults to a local database path (src/objects_database).

Expected Structure of groups_json:
    The JSON file should be structured based on the `Group` data model from `server/models/render_model`, containing:
        - A unique group name (e.g., "group_1", "group_2").
        - A list of object IDs (as strings) to download for that group.
        - Rendering settings (optional) for the objects in that group.

Usage:
    python download_copy.py --groups_json <path_to_groups_json> --save_path <destination_path> --store_path <storage_path>
"""

import objaverse
import multiprocessing as mp
import os
import json
import argparse
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from models.render_model import Group
# from server.models.render_model import Group
from logger.logging_config import setup_custom_logger
# from server.logger.logging_config import setup_custom_logger

logger = setup_custom_logger("download_script")

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--groups_json", type=str, required=True)
    parser.add_argument("--save_path", type=str)
    parser.add_argument("--store_path", type=str)
    return parser.parse_args()

def search_in_database(storeFolder: str, ids):
    filepaths = []
    ids_to_download = []
    
    if not os.path.exists(storeFolder):
        for id in ids:
            path_to_id = os.path.join(storeFolder, id + ".glb")
            filepaths.append(path_to_id)
            ids_to_download = ids
    else:
        downloaded_files = os.listdir(storeFolder)
        downloaded_ids = {file.split('.')[0] for file in downloaded_files}
        for id in ids:
            path_to_id = os.path.join(storeFolder, id + ".glb")
            filepaths.append(path_to_id)
            if id not in downloaded_ids:
                ids_to_download.append(id)

    return filepaths, ids_to_download
            
def write_group_to_json(group, filepaths, save_path, groups_json):
    groups_name = os.path.basename(groups_json).split('.')[-2]
    output_json_dir = os.path.join(save_path, groups_name+"_paths")
    os.makedirs(output_json_dir, exist_ok=True)
    
    data = filepaths

    # json with paths:
    group_json_path = os.path.join(output_json_dir, f"{group}.json")
    with open(group_json_path, "w") as json_file:
        json.dump(data, json_file, indent=2)
    logger.info(f"Json file with id paths written for group: {group} {group_json_path}\n")


def process_groups(groups, args, cpu_count):
    for group in groups:
        # Checking if files are already downloaded
        final_save_path = os.path.join(args.store_path, "glbs", "000-023")
        logger.info(f"Saving object files to {args.store_path}")

        filepaths, ids_to_download = search_in_database(final_save_path, group.object_ids)

        # If all exists
        if not ids_to_download:
            logger.info(f"All files in group '{group.name}' have already been downloaded.")
        # Start downloading of all files
        elif len(ids_to_download) == len(group.object_ids):
            logger.info(f"Downloading all files for group: {group.name}")
            objaverse._VERSIONED_PATH = args.store_path
            objaverse.load_objects(
                uids=ids_to_download,
                download_processes=cpu_count
            )
        # Start downloading of remaining files
        else:
            logger.info(f"Downloading remaining files for group: {group.name}")
            objaverse._VERSIONED_PATH = args.store_path
            objaverse.load_objects(
                uids=ids_to_download,
                download_processes=cpu_count
            )

        # Write to file
        write_group_to_json(group.name, filepaths, args.save_path, args.groups_json)

def load_groups_from_json(json_path_or_data):
    """Load group data from a JSON file or directly from a JSON string"""
    try:
        # First try to parse as direct JSON data
        if json_path_or_data.strip().startswith('{') or json_path_or_data.strip().startswith('['):
            logger.info("Loading groups from JSON string\n")
            raw_data = json.loads(json_path_or_data)
            return [Group(**group_data) for group_data in raw_data]
        # If that fails, try as a file path
        else:
            with open(json_path_or_data, 'r') as f:
                logger.info(f"Loading groups from JSON file: {json_path_or_data}\n")
                raw_data = json.load(f)
                return [Group(**group_data) for group_data in raw_data]

    except (json.JSONDecodeError, FileNotFoundError) as e:
        logger.error(f"Error loading groups: {e}")
        sys.exit(1)


def main():
    logger.info("%s\n",objaverse.__version__)

    # Argument parsing for input and output file paths
    args = parse_arguments()

    # if not args.groups_json or not os.path.isfile(args.groups_json):
    #     logger.error(f"The specified groups_json file '{args.groups_json}' does not exist.")
    #     raise FileNotFoundError(f"The specified groups_json file '{args.groups_json}' does not exist.")

    # # Load object IDs from specified JSON file, convert to Group objects
    # with open(args.groups_json, "r") as json_file:
    #     raw_data = json.load(json_file)

    groups =load_groups_from_json(args.groups_json) #[Group(**group_data) for group_data in raw_data]

    # Set default for save_path if not provided
    if args.save_path is None:
        args.save_path = os.path.dirname(os.path.abspath(args.groups_json))

    # Set default for store_path if not provided
    if not args.store_path:
        args.store_path = os.path.join(os.path.dirname(os.path.abspath(__file__).split(os.sep)[-3]), "src", "objects_database")
    os.makedirs(args.store_path, exist_ok=True)

    # Determine available CPU count for multiprocessing
    cpu_count = mp.cpu_count()

    # Process each group of IDs
    process_groups(groups, args, cpu_count)

    logger.success('Download finished gracefully.')

if __name__ == "__main__":
    main()
