from fastapi import HTTPException, APIRouter, Depends
import uuid
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from models.filters_model import Filters
from models.objects_model import ThreeDObjectsModel
from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("picker")

router = APIRouter() # OFFERS ALL OF THE FUNCTIONALITY AS APP

logger.debug("Initializing filter repository router")


example_filters = {
    "filters": [
        {"type": "vertex_num", "minValue": None, "maxValue": None},
        {"type": "animation_count", "minValue": None, "maxValue": None},
        {"type": "material_count", "minValue": None, "maxValue": None},
        {"type": "edge_count", "minValue": None, "maxValue": None},
        {"type": "poly_count", "minValue": None, "maxValue": None},
        {"type": "mesh_count", "minValue": None, "maxValue": None},
        {"type": "armature_count", "minValue": None, "maxValue": None},
    ]
}

@router.get("/options", response_model=Filters, status_code=200)
def fetch_filters():
    return example_filters

@router.post("/apply", response_model=ThreeDObjectsModel, status_code=200)
def apply_filters(filters: Filters):
    """
    Apply filters and return the intersection of objects that match all filter criteria.
    If no filters are specified (all min/max values are None), return all available objects.
    """
    all_matching_ids = None
    logger.debug("filters/apply called")

    for filter_item in filters.filters:
        # Skip filters where both min and max are None
        if filter_item.minValue is None and filter_item.maxValue is None:
            continue
        
        # Set default values if one bound is missing
        min_val = 0 if filter_item.minValue is None else filter_item.minValue
        max_val = float('inf') if filter_item.maxValue is None else filter_item.maxValue
        
        # Get matching IDs for this filter
        current_matches = list_by(min_val, max_val, filter_item.type)
        
        # If this is the first valid filter, set all_matching_ids to its results
        if all_matching_ids is None:
            all_matching_ids = set(current_matches)
        else:
            # Otherwise, get intersection with previous results
            all_matching_ids = all_matching_ids.intersection(set(current_matches))
    
    # If no valid filters were applied or no matches were found, return example data
    if all_matching_ids is None or len(all_matching_ids) == 0:
        raise HTTPException(status_code=404, detail="No objects found matching the filters.")
    
    return ThreeDObjectsModel(object_ids=list(all_matching_ids))



# function to list by metadata
def list_by(min_val: float, max_val: float, attribute: str):
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
                    value = float(parts[1].strip())  # Changed to float to handle both int and float values
                    if min_val <= value <= max_val:
                        matching_ids.append(id)
                except ValueError:
                    continue
    
    return matching_ids