"""
EditOption-related request/response schemas.

Pydantic models for validating and serializing edit option data.
These schemas are used in API endpoints for request/response handling.
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class EditOptionCreate(BaseModel):
    """
    Schema for creating a new edit option.

    Used when POST request comes to create an edit option.
    All fields except optional ones are required.
    """

    category: str = Field(
        ..., min_length=1, max_length=100, description="Category name (e.g., 'Animals')"
    )
    subject: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Subject name (e.g., 'dog', 'cat')",
    )
    title_en: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="English title of the edit option",
    )
    title_de: str = Field(
        ..., min_length=1, max_length=100, description="German title of the edit option"
    )
    description_en: str = Field(
        ..., description="English description of the edit option"
    )
    description_de: str = Field(
        ..., description="German description of the edit option"
    )
    prompt_en: str = Field(
        ..., description="English prompt to pass to the AI for image editing"
    )
    prompt_de: str = Field(
        ..., description="German prompt to pass to the AI for image editing"
    )
    icon: Optional[str] = Field(
        None, max_length=32, description="Emoji or icon identifier (e.g., '🎨')"
    )


class EditOptionUpdate(BaseModel):
    """
    Schema for updating an existing edit option.

    Used when PUT request comes to update an edit option.
    All fields are optional - only provided fields will be updated.
    """

    category: Optional[str] = Field(None, min_length=1, max_length=100)
    subject: Optional[str] = Field(None, min_length=1, max_length=100)
    title_en: Optional[str] = Field(None, min_length=1, max_length=100)
    title_de: Optional[str] = Field(None, max_length=100)
    description_en: Optional[str] = Field(None)
    description_de: Optional[str] = Field(None)
    prompt_en: Optional[str] = Field(None)
    prompt_de: Optional[str] = Field(None)
    icon: Optional[str] = Field(None, max_length=32)


class EditOptionRead(BaseModel):
    """
    Schema for reading/returning an edit option.

    Used when returning edit option data in API responses.
    Includes all fields plus metadata (id, created_at, updated_at).
    """

    id: str = Field(..., description="Unique identifier (UUID)")
    category: str = Field(..., description="Category name")
    subject: str = Field(..., description="Subject name")
    title_en: str = Field(..., description="English title")
    title_de: str = Field(..., description="German title")
    description_en: str = Field(..., description="English description")
    description_de: str = Field(..., description="German description")
    prompt_en: str = Field(..., description="English prompt for AI editing")
    prompt_de: str = Field(..., description="German prompt for AI editing")
    icon: Optional[str] = Field(None, description="Emoji or icon identifier")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        from_attributes = True  # Allow reading from ORM models


class EditOptionsListResponse(BaseModel):
    """
    Schema for returning a list of edit options.

    Used when returning multiple edit options (e.g., all options for a subject).
    """

    success: bool = Field(..., description="Whether the request was successful")
    data: List[EditOptionRead] = Field(..., description="List of edit options")
    count: int = Field(..., description="Total number of edit options returned")


class EditOptionResponse(BaseModel):
    """
    Schema for returning a single edit option.

    Used when returning a single edit option (e.g., after creation or retrieval).
    """

    success: bool = Field(..., description="Whether the request was successful")
    data: EditOptionRead = Field(..., description="The edit option data")
