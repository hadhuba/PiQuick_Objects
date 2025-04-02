from fastapi import HTTPException, APIRouter, Query
from fastapi.responses import FileResponse
import os

router = APIRouter()

@router.get("/updateobj",  status_code=200)
def host_object(newObj: str = Query(...)):
    """
    Simulate applying the host object and return the .glb file.
    """
    try:
        glb_file_path = os.path.join("assets", "chicken_warrior.glb")
        print(f"Applying host object: {newObj}")
        print(f"GLB file path: {os.path.abspath(glb_file_path)}")

        if not os.path.exists(glb_file_path):
            print("GLB file not found")
            raise HTTPException(status_code=404, detail="GLB file not found")
        
        print("Returning GLB file")

        # Path to the .glb file

        # Check if the file exists
        if not os.path.exists(glb_file_path):
            raise HTTPException(status_code=404, detail="GLB file not found")

        # Return the .glb file as a response
        return FileResponse(
            glb_file_path,
            media_type="model/gltf-binary",
            filename="lamsu.glb"
        )
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")