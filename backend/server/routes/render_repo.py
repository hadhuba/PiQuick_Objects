from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
import os
from utils.setup_path import add_project_root
add_project_root()
# sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from models.render_model import Group
from typing import List
import json
import subprocess
import tempfile

from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("render")

router = APIRouter()

def validate_input(groups: List[Group]):
    """Validate the input groups for rendering."""
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
        logger.debug(group.settings.mode_multi + group.settings.mode_static + group.settings.mode_front_view + group.settings.mode_four_view)
        if not any([group.settings.mode_multi, group.settings.mode_static, group.settings.mode_front_view, group.settings.mode_four_view]):
            logger.error(f"Group '{group.name}' does not have any view mode set to true.")
            raise HTTPException(
                status_code=400,
                detail=f"Group '{group.name}' must have at least one view mode set to true."
            )

@router.post("/", status_code=201)
def render_groups(groups: List[Group]):
    validate_input(groups)
    temp_dir = None
    
    try:
        temp_dir = tempfile.mkdtemp(prefix="render_")
        logger.debug(f"Created temporary directory: {temp_dir}")
        
        
        current_dir = os.path.dirname(os.path.abspath(__file__))
        base_path = os.path.join(current_dir, "../../")
        base_path = os.path.normpath(base_path)

        # Create JSON file with groups data
        json_path = os.path.join(temp_dir, "groups.json")
        with open(json_path, "w") as f:
            # Convert Pydantic models to dict for JSON serialization
            json_data = [group.model_dump() for group in groups]
            json.dump(json_data, f, indent=2)
        
        # Path for the output file
        output_file = os.path.join(temp_dir, "render_output.zip")

        logger.debug("the output file: %s" , output_file)

        render_script = os.path.join(base_path, "scripts/render.py")
        logger.debug("render_script: %s", render_script)
        result = subprocess.run(
            ["python3", render_script, "--groups_json", json_path, "--output_dir", temp_dir, "--output_file", output_file],
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

        # Copy the output file to a new temporary file that will survive after we delete the temp directory
        import shutil
        final_temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")
        final_temp_file.close()
        shutil.copy2(output_file, final_temp_file.name)
        
        # Clean up the temporary directory before returning the response
        if temp_dir and os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
            logger.debug(f"Cleaned up temporary directory: {temp_dir}")
            temp_dir = None

        # Return the file with a callback to delete it after the request is completed
        response = FileResponse(
            path=final_temp_file.name,
            status_code=201,
            filename="rendered_dataset.zip",  # Fixed file extension
            media_type="application/zip",
        )
        
        # Add a background task to clean up the file after it's sent
        from fastapi import BackgroundTasks
        background_tasks = BackgroundTasks()
        
        def cleanup_temp_file():
            try:
                if os.path.exists(final_temp_file.name):
                    os.unlink(final_temp_file.name)
                    logger.debug(f"Cleaned up temporary file: {final_temp_file.name}")
            except Exception as e:
                logger.error(f"Error cleaning up temporary file: {str(e)}")
        
        background_tasks.add_task(cleanup_temp_file)
        response.background = background_tasks
        
        return response
        
    except Exception as e:
        # Clean up the temporary directory in case of an error
        if temp_dir and os.path.exists(temp_dir):
            import shutil
            shutil.rmtree(temp_dir)
            logger.debug(f"Cleaned up temporary directory after error: {temp_dir}")
        
        raise HTTPException(status_code=500, detail=f"Rendering error: {str(e)}")