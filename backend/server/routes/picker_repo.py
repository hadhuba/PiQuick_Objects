"""
Filter API Router Module

This module defines API routes for filtering and retrieving 3D objects.
It includes endpoints for fetching filter options, applying filters, and retrieving all objects,
allowing clients to query the 3D object database with specific criteria.
"""

from fastapi import HTTPException, APIRouter, Depends
import uuid
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from models.filters_model import Filters
from models.objects_model import ThreeDObjectsModel
from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("filter")

router = APIRouter()

filter_options = {
    "filters": [
        {"type": "vertex_num", "description": "Number of vertices in the 3D model", "minValue": None, "maxValue": None},
        {"type": "animation_count", "description": "Number of animations contained in the model", "minValue": None, "maxValue": None},
        {"type": "material_count", "description": "Count of distinct materials used", "minValue": None, "maxValue": None},
        {"type": "edge_count", "description": "Total number of edges in the mesh", "minValue": None, "maxValue": None},
        {"type": "poly_count", "description": "Number of polygons/faces", "minValue": None, "maxValue": None},
        {"type": "mesh_count", "description": "How many meshes the model contains", "minValue": None, "maxValue": None},
        {"type": "armature_count", "description": "Number of armatures/bones", "minValue": None, "maxValue": None},
    ]
}

@router.get("/options", response_model=Filters, status_code=200)
def fetch_filters():
    """
    Fetch available filter options.
    
    Returns:
        Filters: A dictionary containing all available filter options
    """
    return filter_options

@router.post("/apply", response_model=ThreeDObjectsModel, status_code=200)
def apply_filters(filters: Filters):
    """
    Apply filters and return the intersection of objects that match all filter criteria.
    
    Args:
        filters: Filter specifications including min/max values for various attributes
        
    Returns:
        ThreeDObjectsModel: Object containing IDs of all matching 3D objects
        
    Raises:
        HTTPException: If no objects match the specified filters
    """
    all_matching_ids = None

    for filter_item in filters.filters:
        if filter_item.minValue is None and filter_item.maxValue is None:
            continue

        min_val = 0 if filter_item.minValue is None else filter_item.minValue
        max_val = float('inf') if filter_item.maxValue is None else filter_item.maxValue

        current_matches = list_by(min_val, max_val, filter_item.type)

        if all_matching_ids is None:
            all_matching_ids = set(current_matches)
        else:
            all_matching_ids = all_matching_ids.intersection(set(current_matches))

    if all_matching_ids is None or len(all_matching_ids) == 0:
        raise HTTPException(status_code=404, detail="No objects found matching the filters.")

    return ThreeDObjectsModel(object_ids=list(all_matching_ids))

@router.get("/allobjects", response_model=ThreeDObjectsModel, status_code=200)
def all_objects():
    """
    Retrieve all objects in the database.
    
    Returns:
        ThreeDObjectsModel: Object containing IDs of all 3D objects in database
        
    Raises:
        HTTPException: If no objects are found or another error occurs
    """
    try:
        ids = get_all()

        if ids is None or len(ids) == 0:
            raise HTTPException(status_code=404, detail="No objects found matching the filters.")

        return ThreeDObjectsModel(object_ids=list(ids))
    except Exception as e:
        logger.error(f"Error fetching all objects: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

def list_by(min_val: float, max_val: float, attribute: str):
    """
    Retrieve object IDs that match the given attribute range.
    
    Args:
        min_val: Minimum value for the attribute
        max_val: Maximum value for the attribute
        attribute: The attribute type to filter by (e.g., 'vertex_num')
        
    Returns:
        list: List of object IDs matching the criteria
        
    Raises:
        FileNotFoundError: If the attribute metadata file doesn't exist
    """
    current_file_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_file_dir, "../../metadata", f"{attribute}.txt")
    file_path = os.path.normpath(file_path)

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")

    matching_ids = []

    with open(file_path, "r") as file:
        for line in file:
            parts = line.split(":")
            if len(parts) == 2:
                id = parts[0].strip()
                try:
                    value = float(parts[1].strip())
                    if min_val <= value <= max_val:
                        matching_ids.append(id)
                except ValueError:
                    continue

    return matching_ids

def get_all():
    """
    Retrieve all object IDs from the database.
    
    Returns:
        list: List of all object IDs in the database
        
    Raises:
        FileNotFoundError: If the objects directory doesn't exist
    """
    current_file_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.normpath(os.path.join(
        current_file_dir,
        "..", "..",
        "src",
        "objects_database",
        "glbs",
        "000-023"
    ))

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")

    ids = []

    paths = os.listdir(file_path)
    for path in paths:
        if path.endswith(".glb"):
            id = path.split(".")[0]
            ids.append(id)

    return ids