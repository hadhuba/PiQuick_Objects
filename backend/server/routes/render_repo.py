"""
Render API Router Module

This module provides FastAPI routes for 3D object rendering operations.
It handles rendering requests by processing groups of 3D objects with specific rendering settings,
executing the rendering process, and returning the results as a zip file.
"""

from fastapi import HTTPException, APIRouter, BackgroundTasks
from fastapi.responses import FileResponse
import os
import sys
import json
import subprocess
import tempfile
import shutil
from typing import List

base_path = os.path.normpath(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
sys.path.append(base_path)

from models.render_model import Group
from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("render")
router = APIRouter()

def validate_input(groups: List[Group]):
    """
    Validate the input groups for rendering.
    
    Args:
        groups: List of Group objects to validate
        
    Raises:
        HTTPException: If validation fails
    """
    if not groups or len(groups) == 0:
        logger.error("No groups provided for rendering.")
        raise HTTPException(status_code=400, detail="No groups provided for rendering.")
    
    for group in groups:
        if not group.object_ids or len(group.object_ids) == 0:
            logger.error(f"Group '{group.name}' has an empty or missing object_ids field.")
            raise HTTPException(
                status_code=400, 
                detail=f"Group '{group.name}' has an empty list of objects."
            )
        if not any([group.settings.mode_multi, group.settings.mode_front_view, group.settings.mode_four_view]):
            logger.error(f"Group '{group.name}' does not have any view mode set to true.")
            raise HTTPException(
                status_code=400,
                detail=f"Group '{group.name}' must have at least one view mode set to true."
            )

@router.post("/", status_code=201)
def render_groups(groups: List[Group]):
    """
    Process and render groups of 3D objects based on specified settings.
    
    Args:
        groups: List of Group objects containing object IDs and rendering settings
        
    Returns:
        FileResponse: Zip file containing rendered results
        
    Raises:
        HTTPException: If rendering fails
    """
    validate_input(groups)
    temp_dir = None
    
    try:
        temp_dir = tempfile.mkdtemp(prefix="render_")
        
        output_file = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")
        output_file.close()

        json_path = os.path.join(temp_dir, "groups.json")
        with open(json_path, "w") as f:
            json_data = [group.model_dump() for group in groups]
            json.dump(json_data, f, indent=2)
        
        render_script = os.path.join(base_path, "scripts/render.py")
        result = subprocess.run(
            ["python3", render_script, "--groups_json", json_path, "--output_dir", temp_dir, "--output_file", output_file.name],
            text=True
        )
        
        if result.returncode != 0:
            raise HTTPException(
                status_code=500, 
                detail=f"Rendering failed: {result.stderr}"
            )
        
        if not os.path.exists(output_file.name):
            raise HTTPException(
                status_code=500, 
                detail="Render script did not produce output file"
            )
        
        if temp_dir and os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
            temp_dir = None

        try:
            response = FileResponse(
                path=output_file.name,
                status_code=201,
                filename="rendered_dataset.zip",
                media_type="application/zip",
            )
        except Exception as e:
            logger.error(f"Error preparing file response: {str(e)}")
            raise HTTPException(status_code=500, detail="Error preparing file response")

        background_tasks = BackgroundTasks()
        
        def cleanup_temp_file():
            try:
                if os.path.exists(output_file.name):
                    os.unlink(output_file.name)
            except Exception as e:
                logger.error(f"Error cleaning up temporary file: {str(e)}")
        
        background_tasks.add_task(cleanup_temp_file)
        response.background = background_tasks
        
        return response
        
    except Exception as e:
        if temp_dir and os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
        
        raise HTTPException(status_code=500, detail=f"Rendering error: {str(e)}")