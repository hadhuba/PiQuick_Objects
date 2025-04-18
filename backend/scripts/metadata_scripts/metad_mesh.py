import bpy

def count_meshes(scene: bpy.types.Scene) -> int:
    """
    Returns the total number of meshes in the given Blender scene.

    Args:
        scene (bpy.types.Scene): The Blender scene object.
    
    Returns:
        int: The total number of meshes in the scene.
    """
    return sum(1 for obj in scene.objects if obj.type == "MESH")
