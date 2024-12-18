"""Blender script to render images of a 3D scene with various objects.

This script is used to render images of a 3D scene containing objects scattered
on a table. It takes in a path to the directory of the .glb files and renders
images of the scene. The images are saved to the output directory.


"""

import argparse
import json
import math
import os
import random
import sys
from typing import Any, Callable, Dict, Generator, List, Literal, Optional, Set, Tuple
from mathutils.noise import random_unit_vector
import bpy
import numpy as np
from mathutils import Matrix, Vector
import os
# import imageio
# from skimage.metrics import structural_similarity as ssim

IMPORT_FUNCTIONS: Dict[str, Callable] = {
    "obj": bpy.ops.import_scene.obj,
    "glb": bpy.ops.import_scene.gltf,
    "gltf": bpy.ops.import_scene.gltf,
    "usd": bpy.ops.import_scene.usd,
    "fbx": bpy.ops.import_scene.fbx,
    "stl": bpy.ops.import_mesh.stl,
    "usda": bpy.ops.import_scene.usda,
    "dae": bpy.ops.wm.collada_import,
    "ply": bpy.ops.import_mesh.ply,
    "abc": bpy.ops.wm.alembic_import,
    "blend": bpy.ops.wm.append,
}


class MetadataExtractor:
    """Class to extract metadata from a Blender scene."""

    def __init__(
        self, object_path: str, scene: bpy.types.Scene, bdata: bpy.types.BlendData
    ) -> None:
        """Initializes the MetadataExtractor.

        Args:
            object_path (str): Path to the object file.
            scene (bpy.types.Scene): The current scene object from `bpy.context.scene`.
            bdata (bpy.types.BlendData): The current blender data from `bpy.data`.

        Returns:
            None
        """
        self.object_path = object_path
        self.scene = scene
        self.bdata = bdata

    def get_poly_count(self) -> int:
        """Returns the total number of polygons in the scene."""
        total_poly_count = 0
        for obj in self.scene.objects:
            if obj.type == "MESH":
                total_poly_count += len(obj.data.polygons)
        return total_poly_count

    def get_vertex_count(self) -> int:
        """Returns the total number of vertices in the scene."""
        total_vertex_count = 0
        for obj in self.scene.objects:
            if obj.type == "MESH":
                total_vertex_count += len(obj.data.vertices)
        return total_vertex_count

    def get_edge_count(self) -> int:
        """Returns the total number of edges in the scene."""
        total_edge_count = 0
        for obj in self.scene.objects:
            if obj.type == "MESH":
                total_edge_count += len(obj.data.edges)
        return total_edge_count

    def get_lamp_count(self) -> int:
        """Returns the number of lamps in the scene."""
        return sum(1 for obj in self.scene.objects if obj.type == "LIGHT")

    def get_mesh_count(self) -> int:
        """Returns the number of meshes in the scene."""
        return sum(1 for obj in self.scene.objects if obj.type == "MESH")

    def get_material_count(self) -> int:
        """Returns the number of materials in the scene."""
        return len(self.bdata.materials)

    def get_object_count(self) -> int:
        """Returns the number of objects in the scene."""
        return len(self.bdata.objects)

    def get_animation_count(self) -> int:
        """Returns the number of animations in the scene."""
        return len(self.bdata.actions)

    def get_linked_files(self) -> List[str]:
        """Returns the filepaths of all linked files."""
        image_filepaths = self._get_image_filepaths()
        material_filepaths = self._get_material_filepaths()
        linked_libraries_filepaths = self._get_linked_libraries_filepaths()

        all_filepaths = (
            image_filepaths | material_filepaths | linked_libraries_filepaths
        )
        if "" in all_filepaths:
            all_filepaths.remove("")
        return list(all_filepaths)

    def _get_image_filepaths(self) -> Set[str]:
        """Returns the filepaths of all images used in the scene."""
        filepaths = set()
        for image in self.bdata.images:
            if image.source == "FILE":
                filepaths.add(bpy.path.abspath(image.filepath))
        return filepaths

    def _get_material_filepaths(self) -> Set[str]:
        """Returns the filepaths of all images used in materials."""
        filepaths = set()
        for material in self.bdata.materials:
            if material.use_nodes:
                for node in material.node_tree.nodes:
                    if node.type == "TEX_IMAGE":
                        image = node.image
                        if image is not None:
                            filepaths.add(bpy.path.abspath(image.filepath))
        return filepaths

    def _get_linked_libraries_filepaths(self) -> Set[str]:
        """Returns the filepaths of all linked libraries."""
        filepaths = set()
        for library in self.bdata.libraries:
            filepaths.add(bpy.path.abspath(library.filepath))
        return filepaths

    def get_scene_size(self) -> Dict[str, list]:
        """Returns the size of the scene bounds in meters."""
        bbox_min, bbox_max = scene_bbox()
        return {"bbox_max": list(bbox_max), "bbox_min": list(bbox_min)}

    def get_shape_key_count(self) -> int:
        """Returns the number of shape keys in the scene."""
        total_shape_key_count = 0
        for obj in self.scene.objects:
            if obj.type == "MESH":
                shape_keys = obj.data.shape_keys
                if shape_keys is not None:
                    total_shape_key_count += (
                        len(shape_keys.key_blocks) - 1
                    )  # Subtract 1 to exclude the Basis shape key
        return total_shape_key_count

    def get_armature_count(self) -> int:
        """Returns the number of armatures in the scene."""
        total_armature_count = 0
        for obj in self.scene.objects:
            if obj.type == "ARMATURE":
                total_armature_count += 1
        return total_armature_count

    def read_file_size(self) -> int:
        """Returns the size of the file in bytes."""
        return os.path.getsize(self.object_path)

    def get_metadata(self) -> Dict[str, Any]:
        """Returns the metadata of the scene.

        Returns:
            Dict[str, Any]: Dictionary of the metadata with keys for "file_size",
            "poly_count", "vert_count", "edge_count", "material_count", "object_count",
            "lamp_count", "mesh_count", "animation_count", "linked_files", "scene_size",
            "shape_key_count", and "armature_count".
        """
        return {
            "file_size": self.read_file_size(),
            "poly_count": self.get_poly_count(),
            "vert_count": self.get_vertex_count(),
            "edge_count": self.get_edge_count(),
            "material_count": self.get_material_count(),
            "object_count": self.get_object_count(),
            "lamp_count": self.get_lamp_count(),
            "mesh_count": self.get_mesh_count(),
            "animation_count": self.get_animation_count(),
            "linked_files": self.get_linked_files(),
            "scene_size": self.get_scene_size(),
            "shape_key_count": self.get_shape_key_count(),
            "armature_count": self.get_armature_count(),
        }



def reset_cameras() -> None:
    """Resets the cameras in the scene to a single default camera."""
    # Delete all existing cameras
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.object.select_by_type(type="CAMERA")
    bpy.ops.object.delete()

    # Create a new camera with default properties
    bpy.ops.object.camera_add()

    # Rename the new camera to 'NewDefaultCamera'
    new_camera = bpy.context.active_object
    new_camera.name = "Camera"

    # Set the new camera as the active camera for the scene
    scene.camera = new_camera

def sample_point_on_sphere(radius: float) -> Tuple[float, float, float]:
    """Samples a point on a sphere with the given radius.

    Args:
        radius (float): Radius of the sphere.

    Returns:
        Tuple[float, float, float]: A point on the sphere.
    """
    theta = random.random() * 2 * math.pi
    phi = math.acos(2 * random.random() - 1)
    return (
        radius * math.sin(phi) * math.cos(theta),
        radius * math.sin(phi) * math.sin(theta),
        radius * math.cos(phi),
    )

def _sample_spherical(
    radius_min: float = 1.5,
    radius_max: float = 2.0,
    maxz: float = 1.6,
    minz: float = -0.75,
) -> np.ndarray:
    """Sample a random point in a spherical shell.

    Args:
        radius_min (float): Minimum radius of the spherical shell.
        radius_max (float): Maximum radius of the spherical shell.
        maxz (float): Maximum z value of the spherical shell.
        minz (float): Minimum z value of the spherical shell.

    Returns:
        np.ndarray: A random (x, y, z) point in the spherical shell.
    """
    correct = False
    vec = np.array([0, 0, 0])
    while not correct:
        vec = np.random.uniform(-1, 1, 3)
        #         vec[2] = np.abs(vec[2])
        radius = np.random.uniform(radius_min, radius_max, 1)
        vec = vec / np.linalg.norm(vec, axis=0) * radius[0]
        if maxz > vec[2] > minz:
            correct = True
    return vec

def randomize_camera(camera_dist=2.0,Direction_type='front',az_front_vector=None):
    direction = random_unit_vector()
    set_camera(direction, camera_dist=camera_dist,Direction_type=Direction_type,az_front_vector=az_front_vector)


def _set_camera_at_size(i: int, scale: float = 1.5) -> bpy.types.Object:
    """Debugging function to set the camera on the 6 faces of a cube.

    Args:
        i (int): Index of the face of the cube.
        scale (float, optional): Scale of the cube. Defaults to 1.5.

    Returns:
        bpy.types.Object: The camera object.
    """
    if i == 0:
        x, y, z = scale, 0, 0
    elif i == 1:
        x, y, z = -scale, 0, 0
    elif i == 2:
        x, y, z = 0, scale, 0
    elif i == 3:
        x, y, z = 0, -scale, 0
    elif i == 4:
        x, y, z = 0, 0, scale
    elif i == 5:
        x, y, z = 0, 0, -scale
    else:
        raise ValueError(f"Invalid index: i={i}, must be int in range [0, 5].")
    camera = bpy.data.objects["Camera"]
    camera.location = Vector(np.array([x, y, z]))
    direction = -camera.location
    rot_quat = direction.to_track_quat("-Z", "Y")
    camera.rotation_euler = rot_quat.to_euler()
    return camera



def _create_light(
    name: str,
    light_type: Literal["POINT", "SUN", "SPOT", "AREA"],
    location: Tuple[float, float, float],
    rotation: Tuple[float, float, float],
    energy: float,
    use_shadow: bool = False,
    specular_factor: float = 1.0,
):
    """Creates a light object.

    Args:
        name (str): Name of the light object.
        light_type (Literal["POINT", "SUN", "SPOT", "AREA"]): Type of the light.
        location (Tuple[float, float, float]): Location of the light.
        rotation (Tuple[float, float, float]): Rotation of the light.
        energy (float): Energy of the light.
        use_shadow (bool, optional): Whether to use shadows. Defaults to False.
        specular_factor (float, optional): Specular factor of the light. Defaults to 1.0.

    Returns:
        bpy.types.Object: The light object.
    """

    light_data = bpy.data.lights.new(name=name, type=light_type)
    light_object = bpy.data.objects.new(name, light_data)
    bpy.context.collection.objects.link(light_object)
    light_object.location = location
    light_object.rotation_euler = rotation
    light_data.use_shadow = use_shadow
    light_data.specular_factor = specular_factor
    light_data.energy = energy
    return light_object

def randomize_lighting() -> Dict[str, bpy.types.Object]:
    """Randomizes the lighting in the scene.

    Returns:
        Dict[str, bpy.types.Object]: Dictionary of the lights in the scene. The keys are
            "key_light", "fill_light", "rim_light", and "bottom_light".
    """

    # Clear existing lights
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.object.select_by_type(type="LIGHT")
    bpy.ops.object.delete()

    # Create key light
    key_light = _create_light(
        name="Key_Light",
        light_type="SUN",
        location=(0, 0, 0),
        rotation=(0.785398, 0, -0.785398),
        energy=random.choice([3, 4, 5]),
    )

    # Create fill light
    fill_light = _create_light(
        name="Fill_Light",
        light_type="SUN",
        location=(0, 0, 0),
        rotation=(0.785398, 0, 2.35619),
        energy=random.choice([2, 3, 4]),
    )

    # Create rim light
    rim_light = _create_light(
        name="Rim_Light",
        light_type="SUN",
        location=(0, 0, 0),
        rotation=(-0.785398, 0, -3.92699),
        energy=random.choice([3, 4, 5]),
    )

    # Create bottom light
    bottom_light = _create_light(
        name="Bottom_Light",
        light_type="SUN",
        location=(0, 0, 0),
        rotation=(3.14159, 0, 0),
        energy=random.choice([1, 2, 3]),
    )

    return dict(
        key_light=key_light,
        fill_light=fill_light,
        rim_light=rim_light,
        bottom_light=bottom_light,
    )

def reset_scene() -> None:
    """Resets the scene to a clean state.

    Returns:
        None
    """
    # delete everything that isn't part of a camera or a light
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


def load_objects(objects_paths: str) -> None:
    """Loads a model with a supported file extension into the scene.

    Args:
        object_path (str): Path to the model file.

    Raises:
        ValueError: If the file extension is not supported.

    Returns:
        None
    """
    # Convert the objects_paths string into a list  
    objects_path_list = objects_paths.split(',')

    #single object
    if len(objects_path_list) == 1: 
        object_path = objects_path_list[0]

        file_extension = object_path.split(".")[-1].lower()
        if file_extension is None:
            raise ValueError(f"Unsupported file type: {object_path}")

        if file_extension == "usdz":
            # install usdz io package
            dirname = os.path.dirname(os.path.realpath(__file__))
            usdz_package = os.path.join(dirname, "io_scene_usdz.zip")
            bpy.ops.preferences.addon_install(filepath=usdz_package)
            # enable it
            addon_name = "io_scene_usdz"
            bpy.ops.preferences.addon_enable(module=addon_name)
            # import the usdz
            from io_scene_usdz.import_usdz import import_usdz

            import_usdz(context, filepath=object_path, materials=True, animations=True)
            return None

        # load from existing import functions
        import_function = IMPORT_FUNCTIONS[file_extension]

        if file_extension == "blend":
            import_function(directory=object_path, link=False)
        elif file_extension in {"glb", "gltf"}:
            import_function(filepath=object_path, merge_vertices=True)
        else:
            import_function(filepath=object_path)
    #multiple objects
    else: #len(objects_path_list) > 1:
        spacing = 2.0 
        for index, object_path in enumerate(objects_path_list):

            file_extension = object_path.split(".")[-1].lower()
            if file_extension is None:
                raise ValueError(f"Unsupported file type: {object_path}")

            elif file_extension in {"glb", "gltf"}: # just this one 
                bpy.ops.import_scene.gltf(filepath=object_path)
                imported_object = bpy.context.selected_objects[0]
                imported_object.location.x = index * spacing


           


def scene_bbox(
    single_obj: Optional[bpy.types.Object] = None, ignore_matrix: bool = False
) -> Tuple[Vector, Vector]:
    """Returns the bounding box of the scene.

    Taken from Shap-E rendering script
    (https://github.com/openai/shap-e/blob/main/shap_e/rendering/blender/blender_script.py#L68-L82)

    Args:
        single_obj (Optional[bpy.types.Object], optional): If not None, only computes
            the bounding box for the given object. Defaults to None.
        ignore_matrix (bool, optional): Whether to ignore the object's matrix. Defaults
            to False.

    Raises:
        RuntimeError: If there are no objects in the scene.

    Returns:
        Tuple[Vector, Vector]: The minimum and maximum coordinates of the bounding box.
    """
    bbox_min = (math.inf,) * 3
    bbox_max = (-math.inf,) * 3
    found = False
    for obj in get_scene_meshes() if single_obj is None else [single_obj]:
        found = True
        for coord in obj.bound_box:
            coord = Vector(coord)
            if not ignore_matrix:
                coord = obj.matrix_world @ coord
            bbox_min = tuple(min(x, y) for x, y in zip(bbox_min, coord))
            bbox_max = tuple(max(x, y) for x, y in zip(bbox_max, coord))

    if not found:
        raise RuntimeError("no objects in scene to compute bounding box for")

    return Vector(bbox_min), Vector(bbox_max)


def get_scene_root_objects() -> Generator[bpy.types.Object, None, None]:
    """Returns all root objects in the scene.

    Yields:
        Generator[bpy.types.Object, None, None]: Generator of all root objects in the
            scene.
    """
    for obj in bpy.context.scene.objects.values():
        if not obj.parent:
            yield obj


def get_scene_meshes() -> Generator[bpy.types.Object, None, None]:
    """Returns all meshes in the scene.

    Yields:
        Generator[bpy.types.Object, None, None]: Generator of all meshes in the scene.
    """
    for obj in bpy.context.scene.objects.values():
        if isinstance(obj.data, (bpy.types.Mesh)):
            yield obj


def get_3x4_RT_matrix_from_blender(cam: bpy.types.Object) -> Matrix:
    """Returns the 3x4 RT matrix from the given camera.

    Taken from Zero123, which in turn was taken from
    https://github.com/panmari/stanford-shapenet-renderer/blob/master/render_blender.py

    Args:
        cam (bpy.types.Object): The camera object.

    Returns:
        Matrix: The 3x4 RT matrix from the given camera.
    """
    # Use matrix_world instead to account for all constraints
    location, rotation = cam.matrix_world.decompose()[0:2]
    R_world2bcam = rotation.to_matrix().transposed()

    # Use location from matrix_world to account for constraints:
    T_world2bcam = -1 * R_world2bcam @ location

    # put into 3x4 matrix
    RT = Matrix(
        (
            R_world2bcam[0][:] + (T_world2bcam[0],),
            R_world2bcam[1][:] + (T_world2bcam[1],),
            R_world2bcam[2][:] + (T_world2bcam[2],),
        )
    )
    return RT


def delete_invisible_objects() -> None:
    """Deletes all invisible objects in the scene.

    Returns:
        None
    """
    bpy.ops.object.select_all(action="DESELECT")
    for obj in scene.objects:
        if obj.hide_viewport or obj.hide_render:
            obj.hide_viewport = False
            obj.hide_render = False
            obj.hide_select = False
            obj.select_set(True)
    bpy.ops.object.delete()

    # Delete invisible collections
    invisible_collections = [col for col in bpy.data.collections if col.hide_viewport]
    for col in invisible_collections:
        bpy.data.collections.remove(col)


def normalize_scene() -> None:
    """Normalizes the scene by scaling and translating it to fit in a unit cube centered
    at the origin.

    Mostly taken from the Point-E / Shap-E rendering script
    (https://github.com/openai/point-e/blob/main/point_e/evals/scripts/blender_script.py#L97-L112),
    but fix for multiple root objects: (see bug report here:
    https://github.com/openai/shap-e/pull/60).

    Returns:
        None
    """
    if len(list(get_scene_root_objects())) > 1:
        # create an empty object to be used as a parent for all root objects
        parent_empty = bpy.data.objects.new("ParentEmpty", None)
        bpy.context.scene.collection.objects.link(parent_empty)

        # parent all root objects to the empty object
        for obj in get_scene_root_objects():
            if obj != parent_empty:
                obj.parent = parent_empty

    bbox_min, bbox_max = scene_bbox()
    scale = 1 / max(bbox_max - bbox_min)
    for obj in get_scene_root_objects():
        obj.scale = obj.scale * scale

    # Apply scale to matrix_world.
    bpy.context.view_layer.update()
    bbox_min, bbox_max = scene_bbox()
    offset = -(bbox_min + bbox_max) / 2
    for obj in get_scene_root_objects():
        obj.matrix_world.translation += offset
    bpy.ops.object.select_all(action="DESELECT")

    # unparent the camera
    bpy.data.objects["Camera"].parent = None


def delete_missing_textures() -> Dict[str, Any]:
    """Deletes all missing textures in the scene.

    Returns:
        Dict[str, Any]: Dictionary with keys "count", "files", and "file_path_to_color".
            "count" is the number of missing textures, "files" is a list of the missing
            texture file paths, and "file_path_to_color" is a dictionary mapping the
            missing texture file paths to a random color.
    """
    missing_file_count = 0
    out_files = []
    file_path_to_color = {}

    # Check all materials in the scene
    for material in bpy.data.materials:
        if material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type == "TEX_IMAGE":
                    image = node.image
                    if image is not None:
                        file_path = bpy.path.abspath(image.filepath)
                        if file_path == "":
                            # means it's embedded
                            continue

                        if not os.path.exists(file_path):
                            # Find the connected Principled BSDF node
                            connected_node = node.outputs[0].links[0].to_node

                            if connected_node.type == "BSDF_PRINCIPLED":
                                if file_path not in file_path_to_color:
                                    # Set a random color for the unique missing file path
                                    random_color = [random.random() for _ in range(3)]
                                    file_path_to_color[file_path] = random_color + [1]

                                connected_node.inputs[
                                    "Base Color"
                                ].default_value = file_path_to_color[file_path]

                            # Delete the TEX_IMAGE node
                            material.node_tree.nodes.remove(node)
                            missing_file_count += 1
                            out_files.append(image.filepath)
    return {
        "count": missing_file_count,
        "files": out_files,
        "file_path_to_color": file_path_to_color,
    }


def _get_random_color() -> Tuple[float, float, float, float]:
    """Generates a random RGB-A color.

    The alpha value is always 1.

    Returns:
        Tuple[float, float, float, float]: A random RGB-A color. Each value is in the
        range [0, 1].
    """
    return (random.random(), random.random(), random.random(), 1)


def _apply_color_to_object(
    obj: bpy.types.Object, color: Tuple[float, float, float, float]
) -> None:
    """Applies the given color to the object.

    Args:
        obj (bpy.types.Object): The object to apply the color to.
        color (Tuple[float, float, float, float]): The color to apply to the object.

    Returns:
        None
    """
    mat = bpy.data.materials.new(name=f"RandomMaterial_{obj.name}")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    principled_bsdf = nodes.get("Principled BSDF")
    if principled_bsdf:
        principled_bsdf.inputs["Base Color"].default_value = color
    obj.data.materials.append(mat)


def apply_single_random_color_to_all_objects() -> Tuple[float, float, float, float]:
    """Applies a single random color to all objects in the scene.

    Returns:
        Tuple[float, float, float, float]: The random color that was applied to all
        objects.
    """
    rand_color = _get_random_color()
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            _apply_color_to_object(obj, rand_color)
    return rand_color


def place_camera(time, camera_pose_mode="random", camera_dist_min=2.0, camera_dist_max=2.0,Direction_type='front',elevation=0,azimuth=0,az_front_vector=None):
    camera_dist = random.uniform(camera_dist_min, camera_dist_max)
    if camera_pose_mode == "random":
        randomize_camera(camera_dist=camera_dist,Direction_type=Direction_type,az_front_vector=az_front_vector)
        # bpy.ops.view3d.camera_to_view_selected()
    elif camera_pose_mode == "z-circular":
        pan_camera(time, axis="Z", camera_dist=camera_dist,elevation=elevation,Direction_type=Direction_type,azimuth=azimuth)
    elif camera_pose_mode == "z-circular-elevated":
        pan_camera(time, axis="Z", camera_dist=camera_dist, elevation=0.2617993878,Direction_type=Direction_type)
    else:
        raise ValueError(f"Unknown camera pose mode: {camera_pose_mode}")

def pan_camera(time, axis="Z", camera_dist=2.0, elevation=-0.1,Direction_type='multi',azimuth=0):
    angle = (math.pi *2 -time * math.pi * 2)+ azimuth * math.pi * 2
    #example  15-345
    direction = [-math.cos(angle), -math.sin(angle), -elevation]
    direction = [math.sin(angle), math.cos(angle), -elevation]
    assert axis in ["X", "Y", "Z"]
    if axis == "X":
        direction = [direction[2], *direction[:2]]
    elif axis == "Y":
        direction = [direction[0], -elevation, direction[1]]
    direction = Vector(direction).normalized()
    set_camera(direction, camera_dist=camera_dist,Direction_type=Direction_type)


def set_camera(direction, camera_dist=2.0,Direction_type='front',az_front_vector=None):
    if Direction_type=='front':
        direction=Vector((0, 1, 0)).normalized()
    elif Direction_type=='back':
        direction=Vector((0, -1, 0)).normalized()
    elif Direction_type=='left':
        direction=Vector((1, 0, 0)).normalized()  
    elif Direction_type=='right':
        direction=Vector((-1, 0, 0)).normalized()  
    elif Direction_type=='az_front':
        direction=az_front_vector
    
    
    print('direction:',direction)
    camera_pos = -camera_dist * direction
    bpy.context.scene.camera.location = camera_pos

    # https://blender.stackexchange.com/questions/5210/pointing-the-camera-in-a-particular-direction-programmatically
    rot_quat = direction.to_track_quat("-Z", "Y")
    bpy.context.scene.camera.rotation_euler = rot_quat.to_euler()

    bpy.context.view_layer.update()

def write_camera_metadata(path):
    x_fov, y_fov = scene_fov()
    bbox_min, bbox_max = scene_bbox()
    matrix = bpy.context.scene.camera.matrix_world
    matrix_world_np = np.array(matrix)
    
    with open(path, "w") as f:
        json.dump(
            dict(
                matrix_world=matrix_world_np.tolist(),
                format_version=6,
                max_depth=5.0,
                bbox=[list(bbox_min), list(bbox_max)],
                origin=list(matrix.col[3])[:3],
                x_fov=x_fov,
                y_fov=y_fov,
                x=list(matrix.col[0])[:3],
                y=list(-matrix.col[1])[:3],
                z=list(-matrix.col[2])[:3],
            ),
            f,
        )

def scene_fov():
    x_fov = bpy.context.scene.camera.data.angle_x
    y_fov = bpy.context.scene.camera.data.angle_y
    width = bpy.context.scene.render.resolution_x
    height = bpy.context.scene.render.resolution_y
    if bpy.context.scene.camera.data.angle == x_fov:
        y_fov = 2 * math.atan(math.tan(x_fov / 2) * height / width)
    else:
        x_fov = 2 * math.atan(math.tan(y_fov / 2) * width / height)
    return x_fov, y_fov


def render_scene(
    objects_paths: str,
    scene,
    args,
    num_images: int,
    only_northern_hemisphere: bool,
    output_dir: str,
    elevation:int,
    azimuth:float,
) -> None:
    """Saves rendered images with its camera matrix and metadata of the object.

    Args:
        objects_paths (str): Path to the object file.
        num_images (int): Number of renders to save of the object.
        only_northern_hemisphere (bool): Whether to only render sides of the object that
            are in the northern hemisphere. This is useful for rendering objects that
            are photogrammetrically scanned, as the bottom of the object often has
            holes.
        output_dir (str): Path to the directory where the rendered images and metadata
            will be saved.

    Returns:
        None
    """
    os.makedirs(output_dir, exist_ok=True)

    #load the objects
    reset_scene()
    # reset_cameras()
    # delete_invisible_objects()
    load_objects(objects_paths)

    # Set up cameras
    # cam = scene.objects["Camera"]
    # cam.data.lens = 35
    # cam.data.sensor_width = 32

    # # Set up camera constraints
    # cam_constraint = cam.constraints.new(type="TRACK_TO")
    # cam_constraint.track_axis = "TRACK_NEGATIVE_Z"
    # cam_constraint.up_axis = "UP_Y"
    # empty = bpy.data.objects.new("Empty", None)
    # scene.collection.objects.link(empty)
    # cam_constraint.target = empty

    # Extract the metadata. This must be done before normalizing the scene to get
    # accurate bounding box information.
    for obj_path in objects_paths.split(','):
        metadata_extractor = MetadataExtractor(
            object_path=obj_path, scene=scene, bdata=bpy.data
        )
        metadata = metadata_extractor.get_metadata()
        #print(metadata)

        # delete all objects that are not meshes
        if obj_path.lower().endswith(".usdz"):
            # don't delete missing textures on usdz files, lots of them are embedded
            missing_textures = None
        else:
            missing_textures = delete_missing_textures()
        metadata["missing_textures"] = missing_textures

        # possibly apply a random color to all objects
        if obj_path.endswith(".stl") or obj_path.endswith(".ply"):
            assert len(bpy.context.selected_objects) == 1
            rand_color = apply_single_random_color_to_all_objects()
            metadata["random_color"] = rand_color
        else:
            metadata["random_color"] = None
    """
    # save metadata
    metadata_path = os.path.join(output_dir, "metadata.json")
    os.makedirs(os.path.dirname(metadata_path), exist_ok=True)
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, sort_keys=True, indent=2)"""

    # normalize the scene
    normalize_scene()
    print("Scene normalized")

    # randomize the lighting
    randomize_lighting()
    print("light randomized")
    # camera = bpy.data.objects["Camera"]
    # camera.location = Vector((0.0, -4.0, 0.0))
    # look_at(camera, Vector((0.0, 0.0, 0.0)))

    
    camera_pose="random"
    camera_dist_min=2
    camera_dist_max=2
    # render the images


    angle = azimuth * math.pi * 2
    direction = [math.sin(angle), math.cos(angle), 0]
    direction_az = Vector(direction).normalized()
    
    print("starting render")
    for frame in range(num_images):
        if args.mode_multi:
            print("mode_multi")
            t = frame / max(num_images - 1, 1)
            place_camera(
                t,
                camera_pose_mode="z-circular",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='multi',
                elevation=elevation,
                azimuth=azimuth
            )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"multi_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            print("render_path: ", render_path)
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"multi{frame}.json"))    
    

        if args.mode_front:
            place_camera(
                0,
                camera_pose_mode="random",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='az_front',
                az_front_vector=direction_az
            )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"front_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            bpy.ops.render.render(write_still=True)
            
            write_camera_metadata(os.path.join(output_dir, f"front.json"))
        
        #print('args.mode_four_view:',args.mode_four_view)
        if args.mode_four_view:
             #front
            place_camera(
                0,
                camera_pose_mode="random",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='front'
                )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"front_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"front.json"))
            
            place_camera(
                0,
                camera_pose_mode="random",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='back'
                )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"back_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"back.json"))
            
            place_camera(
                0,
                camera_pose_mode="random",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='left'
                )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"left_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"left.json"))
            
            place_camera(
                0,
                camera_pose_mode="random",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='right'
                )
            bpy.context.scene.frame_set(frame)
            render_path = os.path.join(output_dir, f"right_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"right.json"))
    
    for frame in range(num_images):
        print(output_dir)
        if  args.mode_static:
            t = frame / max(num_images - 1, 1)
            place_camera(
                t,
                camera_pose_mode="z-circular",
                camera_dist_min=camera_dist_min,
                camera_dist_max=camera_dist_max,
                Direction_type='multi',
                elevation=elevation,
                azimuth=azimuth
            )
            bpy.context.scene.frame_set(0)
            render_path = os.path.join(output_dir, f"multi_static_frame{frame}.png")  #view and frame 
            scene.render.filepath = render_path
            print("render_path: ", render_path)
            bpy.ops.render.render(write_still=True)
            write_camera_metadata(os.path.join(output_dir, f"static{frame}.json"))   
    



def look_at(obj_camera, point):
    # Calculate the direction vector from the camera to the point
    direction = point - obj_camera.location
    # Make the camera look in this direction
    rot_quat = direction.to_track_quat('-Z', 'Y')
    obj_camera.rotation_euler = rot_quat.to_euler()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument( #--objects_paths
        "--objects_paths",
        type=str,
        required=True,
        help="Paths of the object files",)
    parser.add_argument( #--separate
        "--separate",
        type=bool,
        required=True,
        help="Wether to render in group or separately",)
    parser.add_argument( #--output_dir
        "--output_dir", 
        type=str, 
        default="~/.objaverse/hf-objaverse-v1/scene_views",
        help="Path to save output images",)
    parser.add_argument( #--gpu_id
        "--gpu_id",
        type=int,
        default=0,
        help="Current GPU id")
    parser.add_argument( #--engine
        "--engine", 
        type=str, 
        default="CYCLES", 
        choices=["CYCLES", "BLENDER_EEVEE"])
    parser.add_argument( #--num_images
        "--num_images",
        type=int, 
        default=16)
    parser.add_argument( #--only_northern_hemisphere
        "--only_northern_hemisphere",
        type=int,
        help="Only render the northern hemisphere of the object.",
        default=0,
    )
    parser.add_argument(
        "--elevation",
        type=int,
        default=0,
        help="elevation of each object",
    )
    
    parser.add_argument(
        "--azimuth",
        type=float,
        default=0,
        help="azimuth of each object",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=256,
        help="azimuth of each object",
    )
    
    parser.add_argument(
        "--mode_multi",
       type=int, default=0,
        help="render multi-view images at each time",
    )
    
    parser.add_argument(
        "--mode_four_view",
       type=int, default=0,
        help="render images of four views at each time",
    )
    
    parser.add_argument(
        "--mode_static",
    type=int, default=0,
        help="render multi view images at time 0",
    )
    
    parser.add_argument(
        "--mode_front",
        type=int, default=0,
        help="render images of front views at each time",
    )

    argv = sys.argv[sys.argv.index("--") + 1 :]
    args = parser.parse_args(argv)

    os.environ['CUDA_VISIBLE_DEVICES'] = str(args.gpu_id)

    context = bpy.context
    scene = context.scene
    render = scene.render
    
    # Set render settings
    render.engine = args.engine
    render.image_settings.file_format = "PNG"
    render.image_settings.color_mode = "RGBA"
    render.resolution_x = args.resolution
    render.resolution_y = args.resolution
    render.resolution_percentage = 100

    scene.cycles.device = "GPU"
    scene.cycles.samples = 128
    scene.cycles.diffuse_bounces = 1
    scene.cycles.glossy_bounces = 1
    scene.cycles.transparent_max_bounces = 3
    scene.cycles.transmission_bounces = 3
    scene.cycles.filter_width = 0.01
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    bpy.context.preferences.addons["cycles"].preferences.get_devices()
    bpy.context.preferences.addons[
        "cycles"
    ].preferences.compute_device_type = "CUDA"  # or "OPENCL"

    # print(f"starting render of: {objects_path_list}")
    render_scene(
        objects_paths=args.objects_paths,
        scene=scene,
        args=args,
        num_images=args.num_images,
        only_northern_hemisphere=args.only_northern_hemisphere,
        output_dir=args.output_dir,
        elevation=args.elevation/180,
        azimuth=args.azimuth,
    )


if __name__ == "__main__":
    main()

