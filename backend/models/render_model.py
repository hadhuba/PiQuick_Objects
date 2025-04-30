from typing import Dict, List, Optional
"""
This module defines data models for rendering 3D object groups using Pydantic's BaseModel. 
It includes settings for rendering and grouping of 3D objects.

Classes:
    RenderSettings: Represents the configuration for rendering 3D object groups, 
                    including parameters like number of images, resolution, and augmentation options.
    Group: Represents a group of 3D objects with associated rendering settings.
"""
from pydantic import BaseModel, Field

class RenderSettings(BaseModel):
    """Settings for rendering object groups"""
    num_images: int = Field(default=12)
    azimuth_aug: bool = Field(default=True)
    elevation_aug: bool = Field(default=False)
    resolution: int = Field(default=256)
    mode_multi: bool = Field(default=True)
    mode_front_view: bool = Field(default=False)
    mode_four_view: bool = Field(default=False)
    only_northern_hemisphere: bool = Field(default=True)


class Group(BaseModel):
    """Group of 3D objects with rendering settings"""
    name: str
    object_ids: List[str]
    settings: RenderSettings = Field(default_factory=RenderSettings)