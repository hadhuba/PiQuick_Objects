from typing import List
from pydantic import BaseModel

class ThreeDObject(BaseModel):
    id: str

class ThreeDObjectsModel(BaseModel):
    object_ids: List[str]