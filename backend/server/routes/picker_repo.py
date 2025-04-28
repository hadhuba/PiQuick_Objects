"""
Picker API Router Module

This module provides API routes for locating and serving 3D object files (.glb).
It includes functionality to fetch the file path of a specified object and return it as a response,
enabling clients to request and receive specific 3D models from the database.
"""

from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
import os
import json
from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("picker")

router = APIRouter()

@router.get("/updateobj", status_code=200)
def host_object(newObj: str = Query(...)):
    """
    Locate and return the .glb file for the specified object.
    
    Args:
        newObj: ID of the 3D object to retrieve
        
    Returns:
        FileResponse: The requested .glb file as a binary response
        
    Raises:
        HTTPException: If the GLB file is not found or another error occurs
    """
    try:
        glb_file_path = fetch_glb(newObj)

        if glb_file_path is None:
            logger.error("GLB file not found")
            raise HTTPException(status_code=404, detail="GLB file not found")

        return FileResponse(
            glb_file_path,
            media_type="model/gltf-binary",
            filename=newObj + ".glb",
        )
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

def fetch_glb(id: str) -> str | None:
    """
    Retrieve the file path of a .glb file by its ID.
    
    Args:
        id: ID of the 3D object to retrieve
        
    Returns:
        str or None: Full path to the GLB file if found, None otherwise
        
    Raises:
        FileNotFoundError: If the objects database doesn't exist
    """
    current_file_dir = os.path.dirname(os.path.abspath(__file__))
    objects_database_path = os.path.join(current_file_dir, "../../src/objects_database")
    objects_database_path = os.path.normpath(objects_database_path)
    paths_db_file = os.path.join(objects_database_path, "paths_for_db.json")
    
    if not os.path.exists(objects_database_path):
        raise FileNotFoundError(f"The directory {objects_database_path} does not exist.")
    
    # Check if paths database exists
    if os.path.exists(paths_db_file):
        try:
            with open(paths_db_file, 'r') as f:
                paths_db = json.load(f)
                
            # Check if the ID is in the database
            if id in paths_db:
                # Verify the file actually exists
                if os.path.exists(paths_db[id]):
                    return paths_db[id]
                else:
                    logger.warning(f"File path in database exists but actual file is missing: {paths_db[id]}")
        except json.JSONDecodeError:
            logger.warning(f"Error decoding {paths_db_file}")
        except Exception as e:
            logger.warning(f"Error reading paths database: {e}")
   
    return None