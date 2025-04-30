from pydantic import BaseModel
"""
This module defines models for representing filters using Pydantic BaseModel.
Classes:
    Filter:
        Represents a single filter with attributes for type, optional minimum and maximum values, 
        and an optional description.
    Filters:
        Represents a collection of filters as a list of Filter objects.
"""
from typing import List , Optional

class Filter(BaseModel):
    type: str
    minValue: Optional[float] = None
    maxValue: Optional[float] = None
    description: Optional[str] = None

class Filters(BaseModel):
    filters: List[Filter]