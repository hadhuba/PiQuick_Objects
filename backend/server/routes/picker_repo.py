from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
import os
from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("picker")

router = APIRouter()

@router.get("/updateobj", status_code=200)
def host_object(newObj: str = Query(...)):
    """
    Locating the host object and return the .glb file.
    """
    try:
        glb_file_path = fetch_glb(newObj)
        
        if glb_file_path is None:
            logger.error("GLB file not found")
            raise HTTPException(status_code=404, detail="GLB file not found")
        
        logger.debug("Returning GLB file")
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

# function to get path of glb
def fetch_glb(id: str) -> str | None:
    current_file_dir = os.path.dirname(os.path.abspath(__file__))
    base_path = os.path.join(current_file_dir, "../../src/objects_database/glbs/000-023/")
    base_path = os.path.normpath(base_path)
    
    if not os.path.exists(base_path):
        raise FileNotFoundError(f"The directory {base_path} does not exist.")
    
    files = os.listdir(base_path)
    
    target_file = f"{id}.glb"
    if target_file in files:
        return os.path.join(base_path, target_file)
    return None