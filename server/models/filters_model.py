from pydantic import BaseModel
from typing import List , Optional

class Filter(BaseModel):
    type: str
    minValue: Optional[float] = None
    maxValue: Optional[float] = None

class Filters(BaseModel):
    filters: List[Filter]