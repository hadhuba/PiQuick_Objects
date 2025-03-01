from dataclasses import dataclass
import os
import multiprocessing
from typing import List, Dict, Any
import argparse
import bpy
import sys
import json

from concurrent.futures import ProcessPoolExecutor

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from metadata_scripts.metad_vertex import count_vertices
from metadata_scripts.metad_armature import count_armatures
from metadata_scripts.metad_mesh import count_meshes
from metadata_scripts.metad_poly import count_poly
from metadata_scripts.metad_edge import count_edge
# from metadata_scripts.metad_vertex import save_vert_to_file

def parse_args():
    parser = argparse.ArgumentParser(description="Process metadata extraction arguments.")

    # Setting default save path
    # default_save_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "metadata/")
    # default_objects_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src/glb_files/group_1/glbs/000-023/")

    # Argumentumok hozzáadása
    parser.add_argument( # --save_path
        "--save_path",
        type=str,
        # default=default_save_path,
        help="A path where the output metadata will be saved.")
    parser.add_argument( # --objects_path
        "--objects_path",
        type=str,
        # default=default_objects_path,
        help="The path to the folder of .json files containing object paths to work with.")
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
    argv = sys.argv[sys.argv.index("--") + 1 :]
    return parser.parse_args(argv)

def save_to_file(results: list, attribute: str):
    """Write to file based on current attribute.
    Args:
        result (list): metadata info gathered in task()
        attribute (str): name of attribute
    """
    for result in results:
        print(f"Writing attribute to file: {attribute}")

        os.makedirs(args.save_path, exist_ok=True)
        file_path = os.path.join(args.save_path, f"{attribute}.txt")

        with open(file_path, "a") as f:
            for obj_id, value in result[attribute].items():
                f.write(f"{obj_id}: {value}\n")

# Splitting based on cpu count
def split_list(lst: List[str], n: int) -> List[List[str]]:
    """Split a list into n parts."""
    return [lst[i::n] for i in range(n)]

# calling metadata_extractor script
def task(object_files_chunk: List[str]):
    vertex_numbers = {}
    armature_count = {}
    mesh_count = {}
    poly_count = {}
    material_count = {}
    edge_count = {}
    animation_count = {}
    i = 0

    for object_file in object_files_chunk:
        """Loads a model into the scene."""
        if object_file.endswith(".glb"):
            bpy.ops.import_scene.gltf(filepath=object_file)
        elif object_file.endswith(".fbx"):
            bpy.ops.import_scene.fbx(filepath=object_file)
        else:
            raise ValueError(f"Unsupported file type: {object_file}")
        
        obj_id = os.path.splitext(os.path.basename(object_file))[0]


        # saving all metadata to variable
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
        if args.run_animation:
            animation_count.update({obj_id: len(bpy.data.actions)})
        
        for obj in bpy.data.objects:
            if obj.type not in {"CAMERA", "LIGHT"}:
                bpy.data.objects.remove(obj, do_unlink=True)

        # delete all the materials
        for material in bpy.data.materials:
            bpy.data.materials.remove(material, do_unlink=True)

        # delete all the textures
        for texture in bpy.data.textures:
            bpy.data.textures.remove(texture, do_unlink=True)

        # delete all the images
        for image in bpy.data.images:
            bpy.data.images.remove(image, do_unlink=True)


        # # Deleting loaded objects from memory
        # bpy.ops.object.select_all(action='DESELECT')
        # bpy.data.objects[obj_id].select_set(True)
        # bpy.ops.object.delete()


    return {
        "vertex_num": vertex_numbers,
        "armature_count": armature_count,
        "mesh_count": mesh_count,
        "poly_count": poly_count,
        "material_count": material_count,
        "edge_count": edge_count,
        "animation_count": animation_count
    }
    
    

def main():
    if not os.path.isdir(args.objects_path):
        print(f"Given path '{args.objects_path}' does not exist, or is not directory.")
        exit(1)

    print(f"Working with {args.cpu_count} CPUs")

    # loading object paths
    paths_to_jsons = [os.path.join(args.objects_path, f) for f in os.listdir(args.objects_path)]
    object_files = []
    for json_file in paths_to_jsons:
        with open(json_file, "r") as file:
            data = json.load(file)
            _, paths = next(iter(data.items()))
            object_files.extend(paths)
    # Splitting based on cpu count
    object_chunks = split_list(object_files, args.cpu_count)

    # Running multiproc for every cpu
    with multiprocessing.Pool(processes=args.cpu_count) as pool:
        results = pool.starmap(task, [[chunk] for chunk in object_chunks])
    
    attributes_to_write = {
        "vertex_num": args.run_vertex,
        "armature_count": args.run_armature,
        "mesh_count": args.run_mesh,
        "poly_count": args.run_poly,
        "material_count": args.run_material,
        "edge_count": args.run_edge,
        "animation_count": args.run_animation
    }

    final_attributes = []
    for attribute, to_write in attributes_to_write.items():
        if to_write:
            final_attributes.append(attribute)

    max_workers = min(multiprocessing.cpu_count(), len(final_attributes))  # CPU-k száma vagy aktív booleanok száma
    print("max_workers ", max_workers)

    with multiprocessing.Pool(processes=max_workers) as pool:
        pool.starmap(save_to_file, [(results, attribute) for attribute in final_attributes])

args = parse_args()

if __name__ == "__main__":
    main()
