import bpy

def count_vertices(scene: bpy.types.Scene) -> int:
    """
    Returns the total number of vertices in the given Blender scene.

    Args:
        scene (bpy.types.Scene): The Blender scene object.
    
    Returns:
        int: The total number of vertices in all mesh objects in the scene.
    """
    vert_num = 0
    for obj in scene.objects:
        if obj.type == "MESH":
            vert_num += len(obj.data.vertices)
    return vert_num


"""
def save_vert_to_file(save_path, result)

    os.makedirs(args.save_path, exist_ok=True)

    vertex_numbers = result[vertex_num]
    vertex_save_path = os.path.join(save_path, "vertex/")
    
    with open(os.path.join(vertex_save_path, "vert_num.txt"), "a") as f:
        for obj_id, value in vertex_numbers.items():
            f.write(f"{obj_id}: {value}\n")
"""
