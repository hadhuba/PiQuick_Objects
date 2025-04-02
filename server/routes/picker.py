from fastapi import HTTPException, APIRouter
from fastapi.responses import FileResponse
import os

router = APIRouter()

@router.post("/updateobj", status_code=200)
def host_object(newObj: str):
    """
    Simulate applying the host object and return the .glb file.
    """
    try:
        print(f"Applying host object: {newObj}")

        # Path to the .glb file
        glb_file_path = os.path.join("server", "assets", "Astronaut.glb")

        # Check if the file exists
        if not os.path.exists(glb_file_path):
            raise HTTPException(status_code=404, detail="GLB file not found")

        # Return the .glb file as a response
        return FileResponse(
            glb_file_path,
            media_type="model/gltf-binary",
            filename="Astronaut.glb"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))