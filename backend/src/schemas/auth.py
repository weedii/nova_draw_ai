"""
Authentication schemas for request/response validation.

Pydantic models for:
- User registration
- User login
- Token refresh
- Authentication responses
- User profile data

These schemas validate incoming requests and serialize outgoing responses.
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import date, datetime
from uuid import UUID


class RegisterRequest(BaseModel):
    """
    Request schema for user registration.

    Kid-friendly validation:
    - Email format validation
    - Simple password requirements (min 6 chars)
    - Optional name and birthdate
    """

    email: EmailStr = Field(
        ..., description="User's email address", examples=["kid@example.com"]
    )
    password: str = Field(
        ...,
        min_length=6,
        description="Password (minimum 6 characters)",
        examples=["mypassword123"],
    )
    name: Optional[str] = Field(
        None, max_length=50, description="User's name (optional)", examples=["Alex"]
    )
    birthdate: Optional[date] = Field(
        None,
        description="User's birthdate (optional, for age-appropriate content)",
        examples=["2015-05-20"],
    )

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password meets minimum requirements."""
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters long")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Validate name if provided."""
        if v is not None:
            v = v.strip()
            if len(v) == 0:
                return None
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "email": "kid@example.com",
                "password": "mypassword123",
                "name": "Alex",
                "birthdate": "2015-05-20",
            }
        }


class LoginRequest(BaseModel):
    """
    Request schema for user login.

    Simple email and password authentication.
    """

    email: EmailStr = Field(
        ..., description="User's email address", examples=["kid@example.com"]
    )
    password: str = Field(
        ..., description="User's password", examples=["mypassword123"]
    )

    class Config:
        json_schema_extra = {
            "example": {"email": "kid@example.com", "password": "mypassword123"}
        }


class RefreshTokenRequest(BaseModel):
    """
    Request schema for refreshing access token.

    Provides refresh token to get a new access token.
    """

    refresh_token: str = Field(
        ...,
        description="Refresh token from login/register",
        examples=["eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."],
    )

    class Config:
        json_schema_extra = {
            "example": {"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
        }


class UserResponse(BaseModel):
    """
    Response schema for user profile data.

    Returns user information without sensitive data (no password).
    """

    id: UUID = Field(..., description="User's unique identifier")
    email: str = Field(..., description="User's email address")
    name: Optional[str] = Field(None, description="User's name")
    birthdate: Optional[date] = Field(None, description="User's birthdate")
    created_at: datetime = Field(..., description="Account creation timestamp")

    class Config:
        from_attributes = True  # Enable ORM mode for SQLAlchemy models
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "kid@example.com",
                "name": "Alex",
                "birthdate": "2015-05-20",
                "created_at": "2024-01-15T10:30:00",
            }
        }


class AuthResponse(BaseModel):
    """
    Response schema for authentication (login/register).

    Returns tokens and user information.
    Tokens never expire for kid-friendly UX.
    """

    access_token: str = Field(..., description="JWT access token (never expires)")
    refresh_token: str = Field(..., description="JWT refresh token (never expires)")
    token_type: str = Field(
        default="bearer", description="Token type (always 'bearer')"
    )
    user: UserResponse = Field(..., description="User profile information")

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "user": {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "email": "kid@example.com",
                    "name": "Alex",
                    "birthdate": "2015-05-20",
                    "created_at": "2024-01-15T10:30:00",
                },
            }
        }


class TokenRefreshResponse(BaseModel):
    """
    Response schema for token refresh.

    Returns new access token.
    """

    access_token: str = Field(..., description="New JWT access token (never expires)")
    token_type: str = Field(
        default="bearer", description="Token type (always 'bearer')"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
            }
        }


class MessageResponse(BaseModel):
    """
    Generic message response schema.

    Used for simple success/error messages.
    """

    message: str = Field(
        ..., description="Response message", examples=["Logout successful"]
    )

    class Config:
        json_schema_extra = {"example": {"message": "Operation successful"}}


class PasswordResetRequest(BaseModel):
    """
    Request schema for requesting a password reset.
    """

    email: EmailStr = Field(
        ..., description="User's email address", examples=["kid@example.com"]
    )


class PasswordResetConfirm(BaseModel):
    """
    Request schema for confirming password reset with OTP code.
    """

    email: EmailStr = Field(
        ..., description="User's email address", examples=["kid@example.com"]
    )
    code: str = Field(
        ...,
        min_length=6,
        max_length=6,
        description="6-digit reset code received via email",
        examples=["123456"],
    )
    new_password: str = Field(
        ...,
        min_length=6,
        description="New password (minimum 6 characters)",
        examples=["newpassword123"],
    )

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password meets minimum requirements."""
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters long")
        return v


class ChangePasswordRequest(BaseModel):
    """
    Request schema for changing password (authenticated users).
    """

    current_password: str = Field(
        ...,
        description="Current password for verification",
        examples=["currentpassword123"],
    )
    new_password: str = Field(
        ...,
        min_length=6,
        description="New password (minimum 6 characters)",
        examples=["newpassword123"],
    )

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        """Validate new password meets minimum requirements."""
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters long")
        return v
