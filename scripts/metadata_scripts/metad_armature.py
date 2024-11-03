import bpy

def count_armatures(scene: bpy.types.Scene) -> int:
    """
    Returns the total number of armatures in the given Blender scene.

    Args:
        scene (bpy.types.Scene): The Blender scene object.
    
    Returns:
        int: The total number of armature objects in the scene.
    """
    total_armature_count = 0
    for obj in scene.objects:
        if obj.type == "ARMATURE":
            total_armature_count += 1
    return total_armature_count
