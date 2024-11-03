import bpy

def count_poly(scene: bpy.types.Scene) -> int:
    """
    Returns the total number of polygons in the given Blender scene.

    Args:
        scene (bpy.types.Scene): The Blender scene object.

    Returns:
        int: The total number of polygons in all mesh objects in the scene.
    """
    total_poly_count = 0
    for obj in scene.objects:
        if obj.type == "MESH":
            total_poly_count += len(obj.data.polygons)
    return total_poly_count
