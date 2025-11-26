"""
Schemas for Drawing API responses.
Used for serializing drawing data in API endpoints.
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID


class DrawingResponse(BaseModel):
    """Response schema for a single drawing"""

    id: UUID = Field(..., description="Drawing ID")
    user_id: UUID = Field(..., description="User ID who created the drawing")
    tutorial_id: Optional[UUID] = Field(None, description="Associated tutorial ID")
    uploaded_image_url: Optional[str] = Field(
        None, description="URL of the original uploaded image"
    )
    edited_images_urls: Optional[List[str]] = Field(
        None, description="List of URLs for edited images"
    )
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        from_attributes = True


class DrawingListResponse(BaseModel):
    """Response schema for a list of drawings"""

    success: bool = Field(..., description="Whether the request was successful")
    data: List[DrawingResponse] = Field(..., description="List of drawings")
    count: int = Field(..., description="Total number of drawings")
    page: Optional[int] = Field(None, description="Current page number")
    limit: Optional[int] = Field(None, description="Items per page")

    class Config:
        from_attributes = True


class DrawingCreateRequest(BaseModel):
    """Request schema for creating a drawing"""

    tutorial_id: Optional[UUID] = Field(None, description="Associated tutorial ID")
    uploaded_image_url: Optional[str] = Field(
        None, description="URL of the original image"
    )
    edited_images_urls: Optional[List[str]] = Field(
        None, description="List of edited image URLs"
    )


class DrawingUpdateRequest(BaseModel):
    """Request schema for updating a drawing"""

    tutorial_id: Optional[UUID] = Field(None, description="Associated tutorial ID")
    uploaded_image_url: Optional[str] = Field(
        None, description="URL of the original image"
    )
    edited_images_urls: Optional[List[str]] = Field(
        None, description="List of edited image URLs"
    )
