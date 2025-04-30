from typing import List
from pydantic import BaseModel
"""
This module defines two classes:

1. ThreeDObject: Represents a 3D object with a unique identifier.
2. ThreeDObjectsModel: Represents a collection of 3D object IDs as a list.
"""
class ThreeDObject(BaseModel):
    id: str

class ThreeDObjectsModel(BaseModel):
    object_ids: List[str]