from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from models.render_model import Group
from typing import List
import json
import subprocess

from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("render")

router = APIRouter()

@router.post("/", status_code=201)
def render_groups(groups: List[Group]):
    
    # Validate input
    if not groups or len(groups) == 0:
        raise HTTPException(status_code=400, detail="No groups provided for rendering.")
    
    try:
        # define a function that only gets the temporary dir, and sends the rest

        # Create temporary directory
        # temp_dir = tempfile.mkdtemp(prefix="render_")
        current_dir = os.path.dirname(os.path.abspath(__file__))
        base_path = os.path.join(current_dir, "../../")
        base_path = os.path.normpath(base_path)

        temp_dir = os.path.join(base_path, "src/temporary/")
        temp_dir = os.path.normpath(temp_dir)

        if not os.path.exists(temp_dir):
            logger.debug(f"making folder: temp dir: {temp_dir}")
            os.makedirs(temp_dir)

        # Create JSON file with groups data
        json_path = os.path.join(temp_dir, "groups.json")
        with open(json_path, "w") as f:
            # Convert Pydantic models to dict for JSON serialization
            json_data = [group.model_dump() for group in groups]
            json.dump(json_data, f, indent=2)
        
        # Path for the output file
        output_file = os.path.join(temp_dir, "render_output.zip")

        logger.debug("the output file: %s" , output_file)

        # Call the render script (replace with your actual render script path)
        render_script = os.path.join(base_path, "scripts/render.py")
        logger.debug("render_script: %s", render_script)
        result = subprocess.run(
            ["python3", render_script, "--groups_json", json_path, "--output_dir", temp_dir, "--output_file", output_file],
            # capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            raise HTTPException(
                status_code=500, 
                detail=f"Rendering failed: {result.stderr}"
            )
        
        if not os.path.exists(output_file):
            raise HTTPException(
                status_code=500, 
                detail="Render script did not produce output file"
            )

        # Return the file and schedule cleanup
        return FileResponse(
            path=output_file,
            filename="rendered_dataset.py",
            media_type="application/zip",
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Rendering error: {str(e)}")
