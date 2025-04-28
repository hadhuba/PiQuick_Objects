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
    python download.py --groups_json <path_to_groups_json> --save_path <destination_path> --store_path <storage_path>
"""

import objaverse
import multiprocessing as mp
import os
import json
import argparse
import sys

from utils.setup_path import add_project_root
add_project_root()

from utils.logging_config import setup_custom_logger
from models.render_model import Group

logger = setup_custom_logger("download_script")

def parse_arguments():
    parser = argparse.ArgumentParser(description="Objaverse Batch Downloader")
    parser.add_argument("--groups_json", type=str, required=True,
                        help="Path or JSON string containing grouped object IDs.")
    parser.add_argument("--save_path", type=str, 
                        help="Directory where JSON files with object paths will be saved. Defaults to the directory of groups_json.")
    parser.add_argument("--store_path", type=str,
                        help="Directory where downloaded objects will be stored. Defaults to '<project_root>/src/objects_database'.")
    return parser.parse_args()

def load_paths_database(db_path):
    """Load the centralized paths database or create if it doesn't exist"""
    paths_db_file = os.path.join(db_path, "paths_for_db.json")
    if os.path.exists(paths_db_file):
        try:
            with open(paths_db_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.warning(f"Error decoding {paths_db_file}, creating new database")
            return {}
        except Exception as e:
            logger.warning(f"Error loading paths database: {e}, creating new database")
            return {}
    else:
        logger.info(f"No paths database found at {paths_db_file}, creating new database")
        return {}

def save_paths_database(db_path, paths_db):
    """Save the centralized paths database"""
    paths_db_file = os.path.join(db_path, "paths_for_db.json")
    os.makedirs(os.path.dirname(paths_db_file), exist_ok=True)
    with open(paths_db_file, 'w') as f:
        json.dump(paths_db, f, indent=2)
    logger.info(f"Updated paths database at {paths_db_file}")

def search_in_database(store_path, ids):
    """Check which IDs need to be downloaded by consulting the paths database"""
    paths_db = load_paths_database(store_path)
    
    # Determine which files already exist in the database
    filepaths = []
    ids_to_download = []
    
    for id in ids:
        if id in paths_db:
            filepaths.append(paths_db[id])
        else:
            # Predict where the file will be stored based on objaverse's structure
            # The final path will be updated after download
            path_to_id = os.path.join(store_path, "glbs", "000-023", id + ".glb")
            filepaths.append(path_to_id)
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
        logger.info(f"Saving object files to {args.store_path}")

        filepaths, ids_to_download = search_in_database(args.store_path, group.object_ids)

        # If all exists
        if not ids_to_download:
            logger.info(f"All files in group '{group.name}' have already been downloaded.")
        else:
            # Start downloading of missing files
            logger.info(f"Downloading {len(ids_to_download)} files for group: {group.name}")
            objaverse._VERSIONED_PATH = args.store_path
            
            # Download objects and get their paths
            downloaded_paths = objaverse.load_objects(
                uids=ids_to_download,
                download_processes=cpu_count
            )
            
            # Update our paths database with the actual paths
            paths_db = load_paths_database(args.store_path)
            paths_db.update(downloaded_paths)
            save_paths_database(args.store_path, paths_db)
            
            # Update filepaths with the actual downloaded paths
            for i, id in enumerate(group.object_ids):
                if id in downloaded_paths:
                    # Replace the predicted path with the actual path
                    idx = group.object_ids.index(id)
                    filepaths[idx] = downloaded_paths[id]

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

    groups = load_groups_from_json(args.groups_json)

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
