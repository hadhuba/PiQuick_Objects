from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
from models.render_model import Group
from typing import List
import os
import json

from logger.logging_config import setup_custom_logger

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
        # output_file = os.path.join(temp_dir, "render_output.zip")

        logger.debug("the output file: %s" , output_file)

        # Call the render script (replace with your actual render script path)
        render_script = os.path.join(base_path, "scripts/render_copy.py")
        result = subprocess.run(
            ["python3", render_script, "--groups_json", json_path, "--output_dir", temp_dir],
            capture_output=True,
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
        current_file = os.path.join(current_dir, "render_repo.py")
        return FileResponse(
            path=current_file,
            filename="render_repo.py",
            media_type="application/zip",
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Rendering error: {str(e)}")





# @router.post("/", status_code=201)
# def render_groups(groups: List[Group]):
#     """
#     Process a list of object groups for rendering.
    
#     Creates a JSON file with the provided groups data in a temporary directory,
#     runs the render script, and returns the resulting file.
    
#     Args:
#         groups: List of Group objects with rendering settings
        
#     Returns:
#         FileResponse: The rendered file
        
#     Raises:
#         HTTPException: If the data is invalid or rendering fails
#     """
#     # Validate input
#     if not groups or len(groups) == 0:
#         raise HTTPException(status_code=400, detail="No groups provided for rendering.")
    
#     try:
#         # Create temporary directory
#         # temp_dir = tempfile.mkdtemp(prefix="render_")
#         current_dir = os.path.dirname(os.path.abspath(__file__))
#         logger.debug("current_dir: ", current_dir)
#         base_path = os.path.join(current_dir, "../../")
#         base_path = os.path.normpath(base_path)

#         if not os.path.exists(temp_dir):
#             os.makedirs(temp_dir)

#         # Create JSON file with groups data
#         json_path = os.path.join(temp_dir, "groups.json")
#         with open(json_path, "w") as f:
#             # Convert Pydantic models to dict for JSON serialization
#             json_data = [group.model_dump() for group in groups]
#             json.dump(json_data, f, indent=2)
        
#         # Path for the output file
#         output_file = os.path.join(temp_dir, "render_output.zip")

#         logger.debug("the output file: " , output_file)

#         # # Call the render script (replace with your actual render script path)
#         # render_script = "/home/huba/PiQuick_Objects_git/renderer/render_script.py"
#         # result = subprocess.run(
#         #     ["python", render_script, "--input", json_path, "--output", output_file],
#         #     capture_output=True,
#         #     text=True
#         # )
        
#         # if result.returncode != 0:
#         #     raise HTTPException(
#         #         status_code=500, 
#         #         detail=f"Rendering failed: {result.stderr}"
#         #     )
        
#         # if not os.path.exists(output_file):
#         #     raise HTTPException(
#         #         status_code=500, 
#         #         detail="Render script did not produce output file"
#         #     )
        
#         # # Return the file and schedule cleanup
#         # return FileResponse(
#         #     path=output_file,
#         #     filename="render_results.zip",
#         #     media_type="application/zip",
#         #     background=lambda: shutil.rmtree(temp_dir, ignore_errors=True)
#         # )
#         # Return the file and schedule cleanup
#         current_file = os.path.join(current_dir, "render_repo.py")
#         return FileResponse(
#             path=current_file,
#             filename="render_repo.py",
#             media_type="application/zip",
#         )
        
#     except Exception as e:
#         # Clean up temp directory if anything fails
#         # if 'temp_dir' in locals():
#         #     shutil.rmtree(temp_dir, ignore_errors=True)
#         raise HTTPException(status_code=500, detail=f"Rendering error: {str(e)}")