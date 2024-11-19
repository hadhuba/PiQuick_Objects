import subprocess
import multiprocessing
import argparse
import concurrent.futures
import json
import os
import sys
import random
import time
import logging

import concurrent.futures

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument( #--id_file_path
        "--id_file_path", 
        type=str, 
        default="src/three_groups.json",
        help="Path to json file containing groups of ids to download and render, objects in a group to be rendered in one scene")
    parser.add_argument( #--save_path
        "--save_path", 
        type=str, 
        default="src/object_database/",
        help="Path to store and/or download glb files, and/or find json with object paths. < download.py argument >")
    parser.add_argument( #--store_in_save_path
        "--store_in_save_path",
        type=int, 
        default=0,
        help="download.py argument")
    parser.add_argument( #--num_of_gpus
        "--num_of_gpus",
        type=int,
        default=2)
    parser.add_argument( #--output_dir 
        "--output_dir", 
        type=str, 
        # default="./outputs/",
        help="Path to save output images",)
    parser.add_argument( #--num_images
        "--num_images",
        type=int, 
        default=16,
        help="number of images to take")
    parser.add_argument( #--engine
        "--engine", 
        type=str, 
        default="CYCLES", 
        choices=["CYCLES", "BLENDER_EEVEE"],
        help="")
    parser.add_argument( #--only_northern_hemisphere
        "--only_northern_hemisphere",
        type=int,
        help="Only render the northern hemisphere of the object.",
        default=0)
    parser.add_argument("--azimuth_aug",  type=int, default=0)
    parser.add_argument("--elevation_aug", type=int, default=0,)
    parser.add_argument("--resolution", default=256)
    parser.add_argument("--mode_multi",  type=int, default=0)
    parser.add_argument("--mode_static", type=int, default=0)
    parser.add_argument("--mode_front_view",  type=int, default=0)
    parser.add_argument("--mode_four_view", type=int, default=0)
  
    """parser.add_argument(
        "--scale", 
        type=float, 
        default=0.8)
    
    parser.add_argument( #--camera_dist ## lehet nem kell
        "--camera_dist",
        type=int,
        default=1.2)
    parser.add_argument( #--camera_movement ## lehet máshogy kell
        "--camera_movement",
        type=str, 
        default=None,
        help="file path to camera coordinates json")"""
    
    return parser.parse_args()

def download_groups(args):
    # downloading and/or locating the glb files 

    # run download.py
    current_dir = os.path.dirname(os.path.abspath(__file__))
    download_py_path = os.path.join(current_dir, "download.py")
    download_args = [   "--id_file_path", args.id_file_path, 
                        "--save_path", args.save_path, 
                        "--store_in_save_path", str(args.store_in_save_path)]
    subprocess.run(["python3", download_py_path] + download_args)

    
    id_file_name = os.path.basename(args.id_file_path).split('.')[-2]
    output_json_dir = os.path.join(args.save_path, id_file_name+"_paths")

    """ # Wait for the output directory and files
    max_wait_time = 30  # seconds
    elapsed_time = 0
    while not os.path.exists(output_json_dir) or not os.listdir(output_json_dir):
        time.sleep(1)
        elapsed_time += 1
        if elapsed_time > max_wait_time:
            print("Error: Timeout while waiting for the download to complete.")
            exit(1)"""

    groups = []
    group_names = []
    separates = []
    separate_names = []


    path_files = os.listdir(output_json_dir)
    for json_file in path_files:
        json_file_path = os.path.join(output_json_dir, json_file)
        group_name = json_file.split('.')[0]
        with open(json_file_path, "r") as f:
            data = json.load(f)
        
        for separate_key, objects_paths in data.items():
            separate = int(separate_key) 
            if separate:  # to render separately
                separates.append(objects_paths)
                separate_names.append(group_name)
            else:  # to render in one scene
                groups.append(objects_paths)
                group_names.append(group_name)

    return groups, group_names, separates, separate_names
            
    

    
# Render command execution function for multiprocessing
# def execute_command(args, objects_paths, gpu_id, separate_render):
def execute_command(objects_paths, save_file_name, gpu_id, separate_render):
    
    output_dir_name = args.id_file_path.split('.')[-2]
    
    if args.azimuth_aug:
        azimuth=round(random.uniform(0, 1), 2)
        output_dir_name+=f'_az{azimuth:.2f}'
    else:
        azimuth=0

    if args.elevation_aug:
        elevation= random.randint(5,30)
        output_dir_name+=f'_el{elevation:.2f}'
    else:
        elevation=0

    # output dir + name of json file + elevation/azimuth
    output_dir_path = os.path.join(args.output_dir,  output_dir_name, save_file_name)

    command = f'CUDA_VISIBLE_DEVICES={gpu_id} export DISPLAY=:0.1 && scripts/blender-3.2.2-linux-x64/blender \
        --background --python scripts/blender_render.py -- \
            --objects_paths {",".join(objects_paths)} \
            --separate {separate_render} \
            --output_dir {output_dir_path} \
            --gpu_id {gpu_id} \
            --num_images {args.num_images} \
            --azimuth {azimuth}\
            --elevation {elevation}\
            --resolution {args.resolution} \
            --mode_multi {args.mode_multi}\
            --mode_static {args.mode_static}\
            --mode_front {args.mode_front_view}\
            --mode_four_view {args.mode_four_view}\
            --engine {args.engine} \
            --only_northern_hemisphere {args.only_northern_hemisphere}'

    # Setting up logger
    logger = logging.getLogger("my_logger")
    # TODO task id ami összeáll a group name-ből vagy az obj id-ből
    logger.setLevel(logging.INFO)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    #running
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    logger.info(f"Executing command: {command}")
    logger.info(result.stdout.decode())
    logger.error(result.stderr.decode())

   
    

if __name__ == "__main__":
    args = parse_arguments()
    
    #downloading objects

    if not os.path.exists(args.id_file_path):
        print(f"The given --id_file_path file does not exist: {args.id_file_path}")
        exit(1)

    groups, group_names, separates, separate_names = download_groups(args)

    os.makedirs(args.output_dir, exist_ok=True)

    gpu_count = args.num_of_gpus
    render_tasks = []

    # Assign each group (non-separated) to a specific GPU
    for i, group in enumerate(groups):
        render_tasks.append((group, group_names[i], i % args.num_of_gpus, False))

    # Assign each separate object to a GPU
    k = 0
    for i, sep_objects in enumerate(separates):
        for obj in sep_objects:
            k=k+1
            render_tasks.append(([obj], separate_names[i], k % args.num_of_gpus, True))

    # Execute rendering tasks in parallel on available GPUs
    with multiprocessing.Pool(processes=gpu_count) as pool:
        pool.starmap(execute_command, render_tasks)
        
    print("Rendering process completed.")