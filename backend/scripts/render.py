import subprocess
import multiprocessing
import argparse
import concurrent.futures
import json
import os
import sys
# sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from utils.setup_path import add_project_root
add_project_root()

from models.render_model import Group
# from server.models.render_model import Group
from utils.logging_config import setup_custom_logger
# from server.logger.logging_config import setup_custom_logger
import random
import time
import zipfile
import shutil

import concurrent.futures

logger = setup_custom_logger("render_script")

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument( # groups_json
        "--groups_json",
        required=True,
        type=str,
        help="Path to JSON file containing groups or JSON string with group data"
    )
    parser.add_argument( # save_path
        "--save_path",
        type=str,
        help="Path to save group ids paths json"
    )
    parser.add_argument( # store_path
        "--store_path",
        type=str,
        help="Path to store and/or download glb files"
        # defaults to objects database
    )
    parser.add_argument( # output_dir
        "--output_dir", 
        type=str,
        default="/outputs/.",
        help="Path to save output images"
    )
    parser.add_argument( # num_of_gpus
        "--num_of_gpus",
        type=int,
        default=2,
        help="Number of GPUs to use for rendering"
    )
    parser.add_argument( 
        "--output_file",
        type=str,
    )
    # parser.add_argument(
    #     "--store_in_save_path",
    #     type=int, 
    #     default=0,
    #     help="download.py argument"
    # )
    
    return parser.parse_args()

def load_groups_from_json(json_path_or_data):
    """Load group data from a JSON file or directly from a JSON string"""
    try:
        # First try to parse as direct JSON data
        if json_path_or_data.strip().startswith('{') or json_path_or_data.strip().startswith('['):
            logger.info("Loading groups from JSON string")
            raw_data = json.loads(json_path_or_data)
            return [Group(**group_data) for group_data in raw_data]
        # If that fails, try as a file path
        else:
            with open(json_path_or_data, 'r') as f:
                logger.info(f"Loading groups from JSON file: {json_path_or_data}")
                raw_data = json.load(f)
                return [Group(**group_data) for group_data in raw_data]

    except (json.JSONDecodeError, FileNotFoundError) as e:
        logger.error(f"Error loading groups: {e}")
        sys.exit(1)

def download_groups(args, groups):
    
    # download the objects
    current_dir = os.path.dirname(os.path.abspath(__file__))
    download_py_path = os.path.join(current_dir, "download.py")
    
    if args.save_path is None:
        args.save_path = os.path.dirname(os.path.abspath(args.groups_json))



    if args.store_path is None:
        download_args = [   
        "--groups_json", args.groups_json, 
        "--save_path", args.save_path,
        ]    
    else:
        download_args = [   
        "--groups_json", args.groups_json, 
        "--save_path", args.save_path,
        "--store_path", args.store_path,
        ]
    
    
    subprocess.run(["python3", download_py_path] + download_args, check=True) #,  check=True

    # fetching the paths
    groups_paths = {}
    for group in groups:
        group_name = group.name

        groups_name = os.path.basename(args.groups_json).split('.')[-2]
        output_json_dir = os.path.join(args.save_path, groups_name+"_paths")
        group_json_path = os.path.join(output_json_dir, f"{group_name}.json")
        
        if os.path.exists(group_json_path):
            groups_paths[group_name] = []
            with open(group_json_path, "r") as f:
                data = json.load(f)
            for obj_path in data:          
                groups_paths[group_name].append(obj_path)
        else: 
            logger.error(f"Group JSON file not found: {group_json_path}")
            raise FileNotFoundError(f"Group JSON file not found: {group_json_path}")
        logger.info(f"Group JSON file found: {group_json_path}")
    
    return groups_paths

def execute_command(objects_paths, save_file_name, output_dir, gpu_id, separate_render, group_settings):
    output_dir_name = save_file_name
    
    azimuth = 0
    if group_settings.azimuth_aug:
        azimuth = round(random.uniform(0, 1), 2)
        output_dir_name += f'_az{azimuth:.2f}'
    
    elevation = 0
    if group_settings.elevation_aug:
        elevation = random.randint(5, 30)
        output_dir_name += f'_el{elevation}'
        
    # output dir + name of group + elevation/azimuth
    output_dir_path = os.path.join(output_dir, output_dir_name)
    
    # Set up environment for headless rendering
    # Use xvfb-run if available to create a virtual framebuffer
    try:
        # Test if xvfb-run is available
        subprocess.run(["which", "xvfb-run"], check=True, capture_output=True)
        xvfb_prefix = "xvfb-run -a "
        display_env = ""
        logger.info("Using xvfb-run for virtual display")
    except subprocess.CalledProcessError:
        # If xvfb-run is not available, try with DISPLAY=:99
        xvfb_prefix = ""
        display_env = "export DISPLAY=:99 && "
        logger.info("xvfb-run not found, using DISPLAY=:99")
    
    gpu_options = f"CUDA_VISIBLE_DEVICES={gpu_id}"
    
    # Build the command
    command = f'{gpu_options} {display_env}{xvfb_prefix}scripts/blender-3.2.2-linux-x64/blender \
            --background --python scripts/blender_render.py --\
            --objects_paths {",".join(objects_paths)}\
            --separate {1 if separate_render else 0}\
            --output_dir {output_dir_path}\
            --gpu_id {gpu_id}\
            --num_images {group_settings.num_images}\
            --azimuth {azimuth}\
            --elevation {elevation}\
            --resolution {group_settings.resolution}\
            --mode_multi {1 if group_settings.mode_multi else 0}\
            --mode_static {1 if group_settings.mode_static else 0}\
            --mode_front {1 if group_settings.mode_front_view else 0}\
            --mode_four_view {1 if group_settings.mode_four_view else 0}\
            --only_northern_hemisphere {1 if group_settings.only_northern_hemisphere else 0}'
    
    logger.info(f"Running command: {command}")
    
    # Run the command
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    logger.info(result.stdout.decode())
    
    if result.returncode != 0:
        logger.error(f"Command failed with return code {result.returncode}")
        logger.error(result.stderr.decode())
    else:
        logger.info(f"Successfully rendered to {output_dir_path}")

def zip_subfolders(output_dir: str, output_file: str):
    """
    Wraps all subfolders of the specified directory into a zip file.

    Args:
        output_dir (str): The directory containing subfolders to zip.
        output_file (str): The path to the output zip file.

    Returns:
        None
    """
    with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                # Add files to the zip, preserving folder structure
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, output_dir)
                zipf.write(file_path, arcname)
    
def main():
    args = parse_arguments()
    
    if not args.groups_json or not os.path.isfile(args.groups_json):
        logger.error(f"The specified groups_json file '{args.groups_json}' does not exist.")
        raise FileNotFoundError(f"The specified groups_json file '{args.groups_json}' does not exist.")

    # Loading groups
    groups = load_groups_from_json(args.groups_json)
    group_paths = download_groups(args, groups)
    logger.info(f"Downloaded groups: {group_paths}")
    

    os.makedirs(args.output_dir, exist_ok=True)
    
    gpu_count = args.num_of_gpus
    render_tasks = []
    
    gpu_id = 0
    for group in (groups):
        if group.settings.separately:
            for i, path in enumerate(group_paths[group.name]):
                obj_id = group.object_ids[i]
                logger.debug(f"Object ID: {obj_id}")
                obj_id = obj_id[:5]
                logger.debug(f"Object path: {path}")
                render_tasks.append(([path], group.name+obj_id, args.output_dir, gpu_id % gpu_count, group.settings.separately, group.settings))
                gpu_id+=1
        else:
            logger.debug(f"Group name: {group.name}, is rendered together")
            render_tasks.append((group_paths[group.name], group.name, args.output_dir, gpu_id % gpu_count, group.settings.separately, group.settings))
            gpu_id+=1
        
        
    with multiprocessing.Pool(processes=gpu_count) as pool:
        pool.starmap(execute_command, render_tasks)
        
    logger.success("Rendering process completed.")

    # Delete the folder named "groups_paths" next to the args.groups_json file
    groups_paths_dir = os.path.join(os.path.dirname(args.groups_json), "groups_paths")
    if os.path.exists(groups_paths_dir) and os.path.isdir(groups_paths_dir):
        try:
            shutil.rmtree(groups_paths_dir)
            logger.info(f"Deleted remporary folder containing .glb paths: {groups_paths_dir}")
        except Exception as e:
            logger.info(f"Failed to delete folder {groups_paths_dir}: {e}")
    zip_subfolders(args.output_dir, args.output_file)
    logger.info(f"Zipped output files to {args.output_file}")


if __name__ == "__main__":
    main()    

