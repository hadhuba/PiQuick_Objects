"""
Metadata Extraction with Multiprocessing

This script extracts various metadata attributes (e.g., vertex count, armature count) from 3D object files using multiprocessing for efficiency. It supports multiple attributes and allows selective execution based on user-specified flags.

Parameters:
    --save_path: Directory to save the extracted metadata (default: './metadata/').
    --objects_path: Directory containing JSON files with paths to 3D object files (default: './objects/').
    --cpu_count: Number of CPU cores to use for multiprocessing (default: all available cores).
    --run_vertex: Extract vertex count metadata (default: True).
    --run_armature: Extract armature count metadata (default: True).
    --run_mesh: Extract mesh count metadata (default: True).
    --run_poly: Extract polygon count metadata (default: True).
    --run_material: Extract material count metadata (default: True).
    --run_edge: Extract edge count metadata (default: True).

Usage:
    blender -b -P metadata_multiproc.py -- [args]
"""

from dataclasses import dataclass
import os
import multiprocessing
from typing import List, Dict, Any
import argparse
import sys
import json
from concurrent.futures import ProcessPoolExecutor

try:
    import bpy
except ModuleNotFoundError:
    pass

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from metadata_scripts.metad_vertex import count_vertices
from metadata_scripts.metad_armature import count_armatures
from metadata_scripts.metad_mesh import count_meshes
from metadata_scripts.metad_poly import count_poly
from metadata_scripts.metad_edge import count_edge

def parse_args():
    parser = argparse.ArgumentParser(description="Process metadata extraction arguments.")
    parser.add_argument("--save_path", type=str, default="./metadata/", help="Path to save the output metadata.")
    parser.add_argument("--objects_path", type=str, default="./objects/", help="Path to the folder of JSON files with object paths.")
    parser.add_argument("--cpu_count", type=int, default=multiprocessing.cpu_count(), help="Number of CPU cores to use.")
    parser.add_argument("--run_vertex", action="store_true", default=True, help="Extract vertex count metadata.")
    parser.add_argument("--run_armature", action="store_true", default=True, help="Extract armature count metadata.")
    parser.add_argument("--run_mesh", action="store_true", default=True, help="Extract mesh count metadata.")
    parser.add_argument("--run_poly", action="store_true", default=True, help="Extract polygon count metadata.")
    parser.add_argument("--run_material", action="store_true", default=True, help="Extract material count metadata.")
    parser.add_argument("--run_edge", action="store_true", default=True, help="Extract edge count metadata.")
    try:
        separator_index = sys.argv.index("--")
        argv = sys.argv[separator_index + 1:]
        return parser.parse_args(argv)
    except (ValueError, IndexError):
        return parser.parse_args([])

def save_to_file(results: list, attribute: str):
    os.makedirs(args.save_path, exist_ok=True)
    file_path = os.path.join(args.save_path, f"{attribute}.txt")
    with open(file_path, "a") as f:
        for result in results:
            for obj_id, value in result[attribute].items():
                f.write(f"{obj_id}: {value}\n")

def split_list(lst: List[str], n: int) -> List[List[str]]:
    return [lst[i::n] for i in range(n)]

def task(object_files_chunk: List[str]):
    vertex_numbers = {}
    armature_count = {}
    mesh_count = {}
    poly_count = {}
    material_count = {}
    edge_count = {}

    for object_file in object_files_chunk:
        if object_file.endswith(".glb"):
            bpy.ops.import_scene.gltf(filepath=object_file)
        elif object_file.endswith(".fbx"):
            bpy.ops.import_scene.fbx(filepath=object_file)
        else:
            raise ValueError(f"Unsupported file type: {object_file}")

        obj_id = os.path.splitext(os.path.basename(object_file))[0]

        if args.run_vertex:
            vertex_numbers.update({obj_id: count_vertices(bpy.context.scene)})
        if args.run_armature:
            armature_count.update({obj_id: count_armatures(bpy.context.scene)})
        if args.run_mesh:
            mesh_count.update({obj_id: count_meshes(bpy.context.scene)})
        if args.run_poly:
            poly_count.update({obj_id: count_poly(bpy.context.scene)})
        if args.run_material:
            material_count.update({obj_id: len(bpy.data.materials)})
        if args.run_edge:
            edge_count.update({obj_id: count_edge(bpy.context.scene)})
        
        for obj in bpy.data.objects:
            if obj.type not in {"CAMERA", "LIGHT"}:
                bpy.data.objects.remove(obj, do_unlink=True)

        for material in bpy.data.materials:
            bpy.data.materials.remove(material, do_unlink=True)

        for texture in bpy.data.textures:
            bpy.data.textures.remove(texture, do_unlink=True)

        for image in bpy.data.images:
            bpy.data.images.remove(image, do_unlink=True)

    return {
        "vertex_num": vertex_numbers,
        "armature_count": armature_count,
        "mesh_count": mesh_count,
        "poly_count": poly_count,
        "material_count": material_count,
        "edge_count": edge_count,
    }

def main():
    if not os.path.isdir(args.objects_path):
        print(f"Given path '{args.objects_path}' does not exist, or is not a directory.")
        exit(1)

    print(f"Working with {args.cpu_count} CPUs")

    paths_to_jsons = [os.path.join(args.objects_path, f) for f in os.listdir(args.objects_path)]
    object_files = []
    for json_file in paths_to_jsons:
        with open(json_file, "r") as file:
            data = json.load(file)
            object_files.extend(data)

    object_chunks = split_list(object_files, args.cpu_count)

    with multiprocessing.Pool(processes=args.cpu_count) as pool:
        results = pool.starmap(task, [[chunk] for chunk in object_chunks])

    attributes_to_write = {
        "vertex_num": args.run_vertex,
        "armature_count": args.run_armature,
        "mesh_count": args.run_mesh,
        "poly_count": args.run_poly,
        "material_count": args.run_material,
        "edge_count": args.run_edge,
    }

    final_attributes = [attr for attr, to_write in attributes_to_write.items() if to_write]

    max_workers = min(multiprocessing.cpu_count(), len(final_attributes))

    with multiprocessing.Pool(processes=max_workers) as pool:
        pool.starmap(save_to_file, [(results, attribute) for attribute in final_attributes])

args = parse_args()

if __name__ == "__main__":
    main()
