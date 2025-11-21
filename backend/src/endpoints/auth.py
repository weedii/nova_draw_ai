"""
Authentication endpoints for user registration, login, and token management.

Provides REST API endpoints for:
- User registration
- User login
- Token refresh
- Get current user profile

All endpoints use kid-friendly error messages and validation.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.db import get_db
from src.services import AuthService
from src.schemas import (
    RegisterRequest,
    LoginRequest,
    RefreshTokenRequest,
    AuthResponse,
    TokenRefreshResponse,
    UserResponse,
)
from src.models import User

# Create router with /auth prefix
router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
    responses={
        401: {"description": "Unauthorized - Invalid credentials or token"},
        400: {"description": "Bad Request - Validation error"},
    },
)


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="Create a new user account with email and password. Returns access and refresh tokens.",
)
async def register(
    request: RegisterRequest, db: AsyncSession = Depends(get_db)
) -> AuthResponse:
    """
    Register a new user account.

    """

    return await AuthService.register_user(db, request)


@router.post(
    "/login",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="Login user",
    description="Authenticate user with email and password. Returns access and refresh tokens.",
)
async def login(
    request: LoginRequest, db: AsyncSession = Depends(get_db)
) -> AuthResponse:
    """
    Login user with email and password.
    """

    return await AuthService.login_user(db, request)


@router.post(
    "/refresh",
    response_model=TokenRefreshResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh access token",
    description="Generate a new access token using a refresh token.",
)
async def refresh_token(
    request: RefreshTokenRequest, db: AsyncSession = Depends(get_db)
) -> TokenRefreshResponse:
    """
    Refresh access token using refresh token.
    """

    return await AuthService.refresh_access_token(db, request.refresh_token)


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user",
    description="Get the profile of the currently authenticated user.",
)
async def get_current_user_profile(
    current_user: User = Depends(AuthService.get_current_user),
) -> UserResponse:
    """
    Get current authenticated user profile.

    **Authentication Required:**
    - Include access token in Authorization header: `Bearer <token>`

    **Example Response:**
    ```json
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "kid@example.com",
      "name": "Alex",
      "birthdate": "2015-05-20",
      "created_at": "2024-01-15T10:30:00"
    }
    ```

    **Errors:**
    - 401: Invalid or missing token
    - 404: User not found
    """

    return UserResponse.model_validate(current_user)
