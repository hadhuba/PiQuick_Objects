import subprocess
import multiprocessing
import argparse
import logging

parser = argparse.ArgumentParser(description="Process metadata multiproc arguments.")

parser.add_argument( # --save_path
    "--save_path",
    type=str,
    # default=default_save_path,
    help="A path where the output metadata will be saved.")
parser.add_argument( # --objects_path
    "--objects_path",
    type=str,
    # default=default_objects_path,
    help="The path of the objects to work with.")
parser.add_argument( # --cpu_count
    "--cpu_count",
    type=int,
    default=multiprocessing.cpu_count(),
    help="Number of CPU cores to use.")
parser.add_argument( # --run_vertex
    "--run_vertex",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the vertex metadata extraction.")
parser.add_argument( # --run_armature
    "--run_armature",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the armature metadata extraction.")
parser.add_argument( # --run_mesh
    "--run_mesh",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the mesh metadata extraction.")
parser.add_argument( # --run_poly
    "--run_poly",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the polygons metadata extraction.")
parser.add_argument( # --run_material
    "--run_material",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the materials metadata extraction.")
parser.add_argument( # --run_edge
    "--run_edge",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the edge metadata extraction.")
parser.add_argument( # --run_animation
    "--run_animation",
    action="store_true",
    default=True,
    help="Flag to indicate whether to run the animations metadata extraction.")

args = parser.parse_args()

#CUDA_VISIBLE_DEVICES={gpu_id} export DISPLAY=:0.1 &&
gpu_id = 0
command=f'CUDA_VISIBLE_DEVICES={gpu_id} export DISPLAY=:0.1 && scripts/blender-3.2.2-linux-x64/blender \
    --background --python metadata_multiproc.py -- \
    --save_path {args.save_path} \
    --objects_path {args.objects_path} \
    --cpu_count {args.cpu_count} \
    --run_vertex {args.run_vertex} \
    --run_armature {args.run_armature} \
    --run_mesh {args.run_mesh} \
    --run_poly {args.run_poly} \
    --run_material {args.run_material} \
    --run_edge {args.run_edge} \
    --run_animation {args.run_animation}'

print('command:',command)
logging.info(f'Executing command: {command}')
result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
logging.info(result.stdout.decode())
logging.error(result.stderr.decode())