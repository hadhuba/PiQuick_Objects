import bpy

def count_edge(scene: bpy.types.Scene) -> int:
    """
    Returns the total number of edges in the given Blender scene.

    Args:
        scene (bpy.types.Scene): The Blender scene object.

    Returns:
        int: The total number of edges in all mesh objects in the scene.
    """
    total_edge_count = 0
    for obj in scene.objects:
        if obj.type == "MESH":
            total_edge_count += len(obj.data.edges)
    return total_edge_count