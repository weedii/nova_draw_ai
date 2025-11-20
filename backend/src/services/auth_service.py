"""
Authentication service for user registration, login, and token management.

Provides business logic for:
- User registration with validation
- User login with password verification
- Token generation and refresh
- Current user retrieval from token

This service handles all authentication-related operations and integrates
with the User model, UserRepository, JWT utilities, and password utilities.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from datetime import date
import logging

from src.models import User
from src.repositories.user_repository import UserRepository
from src.schemas import (
    RegisterRequest,
    LoginRequest,
    AuthResponse,
    UserResponse,
    TokenRefreshResponse,
)
from src.utils import (
    hash_password,
    verify_password,
    validate_password_strength,
    create_access_token,
    create_refresh_token,
    verify_token,
)
from src.database.db import get_db

logger = logging.getLogger(__name__)

# HTTP Bearer token security scheme
security = HTTPBearer()


class AuthService:
    """
    Service class for authentication operations.
    
    Handles user registration, login, token management, and user retrieval.
    """

    @staticmethod
    async def register_user(
        db: AsyncSession,
        request: RegisterRequest
    ) -> AuthResponse:
        """
        Register a new user account.
        
        Steps:
        1. Validate password strength
        2. Check if email already exists
        3. Hash password
        4. Create user in database
        5. Generate tokens
        6. Return auth response
        
        Args:
            db: Database session
            request: Registration request data
            
        Returns:
            AuthResponse with tokens and user info
            
        Raises:
            HTTPException 400: If email already exists or validation fails
            HTTPException 500: If registration fails
            
        Example:
            response = await AuthService.register_user(db, register_request)
            access_token = response.access_token
        """
        try:
            # Validate password strength
            is_valid, message = validate_password_strength(request.password)
            if not is_valid:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=message
                )
            
            # Check if email already exists
            existing_user = await UserRepository.find_by_email(db, request.email)
            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This email is already registered"
                )
            
            # Hash password using bcrypt
            hashed_password = hash_password(request.password)
            
            # Create user in database
            # Note: The @encrypted_field decorator will encrypt the password again with Fernet
            # We need to store the bcrypt hash, not double-encrypt it
            user_data = {
                "email": request.email,
                "password": hashed_password,
                "name": request.name,
                "birthdate": request.birthdate,
            }
            
            user = await User.create(db, **user_data)
            await db.commit()
            await db.refresh(user)
            
            # Generate tokens (never expire)
            access_token = create_access_token(
                user_id=str(user.id),
                email=user.email
            )
            refresh_token = create_refresh_token(user_id=str(user.id))
            
            # Create response
            user_response = UserResponse.model_validate(user)
            auth_response = AuthResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                token_type="bearer",
                user=user_response
            )
            
            logger.info(f"User registered successfully: {user.email}")
            return auth_response
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Registration failed: {str(e)}")
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Oops! Something went wrong. Please try again."
            )

    @staticmethod
    async def login_user(
        db: AsyncSession,
        request: LoginRequest
    ) -> AuthResponse:
        """
        Authenticate user and generate tokens.
        
        Steps:
        1. Find user by email
        2. Verify password
        3. Generate new tokens
        4. Return auth response
        
        Args:
            db: Database session
            request: Login request data
            
        Returns:
            AuthResponse with tokens and user info
            
        Raises:
            HTTPException 401: If credentials are invalid
            HTTPException 500: If login fails
            
        Example:
            response = await AuthService.login_user(db, login_request)
            access_token = response.access_token
        """
        try:
            # Find user by email
            user = await UserRepository.find_by_email(db, request.email)
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Email or password is incorrect. Please try again!"
                )
            
            # Verify password
            # Note: user.password is the bcrypt hash (encrypted by Fernet decorator)
            # We need to decrypt it first, then verify with bcrypt
            is_valid = verify_password(request.password, user.password)
            if not is_valid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Email or password is incorrect. Please try again!"
                )
            
            # Generate new tokens (never expire)
            access_token = create_access_token(
                user_id=str(user.id),
                email=user.email
            )
            refresh_token = create_refresh_token(user_id=str(user.id))
            
            # Create response
            user_response = UserResponse.model_validate(user)
            auth_response = AuthResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                token_type="bearer",
                user=user_response
            )
            
            logger.info(f"User logged in successfully: {user.email}")
            return auth_response
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Login failed: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Oops! Something went wrong. Please try again."
            )

    @staticmethod
    async def refresh_access_token(
        db: AsyncSession,
        refresh_token: str
    ) -> TokenRefreshResponse:
        """
        Generate new access token from refresh token.
        
        Steps:
        1. Verify refresh token
        2. Get user from database
        3. Generate new access token
        4. Return token response
        
        Args:
            db: Database session
            refresh_token: Refresh token string
            
        Returns:
            TokenRefreshResponse with new access token
            
        Raises:
            HTTPException 401: If refresh token is invalid
            HTTPException 404: If user not found
            HTTPException 500: If token refresh fails
            
        Example:
            response = await AuthService.refresh_access_token(db, refresh_token)
            new_access_token = response.access_token
        """
        try:
            # Verify refresh token
            payload = verify_token(refresh_token, token_type="refresh")
            user_id = payload.get("sub")
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token. Please log in again."
                )
            
            # Get user from database
            user = await User.get_by_id(db, user_id)
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found. Please log in again."
                )
            
            # Generate new access token (never expires)
            access_token = create_access_token(
                user_id=str(user.id),
                email=user.email
            )
            
            # Create response
            token_response = TokenRefreshResponse(
                access_token=access_token,
                token_type="bearer"
            )
            
            logger.info(f"Access token refreshed for user: {user.email}")
            return token_response
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Token refresh failed: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token. Please log in again."
            )

    @staticmethod
    async def get_current_user(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: AsyncSession = Depends(get_db)
    ) -> User:
        """
        Get current authenticated user from token.
        
        This is a FastAPI dependency that can be used in protected endpoints.
        It extracts the token from the Authorization header, verifies it,
        and returns the user from the database.
        
        Args:
            credentials: HTTP Bearer credentials (injected by FastAPI)
            db: Database session (injected by FastAPI)
            
        Returns:
            User instance
            
        Raises:
            HTTPException 401: If token is invalid or user not found
            
        Example:
            @router.get("/me")
            async def get_me(user: User = Depends(AuthService.get_current_user)):
                return {"email": user.email}
        """
        try:
            # Extract token from credentials
            token = credentials.credentials
            
            # Verify token
            payload = verify_token(token, token_type="access")
            user_id = payload.get("sub")
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token. Please log in again.",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            
            # Get user from database
            user = await User.get_by_id(db, user_id)
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found. Please log in again.",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            
            return user
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Get current user failed: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token. Please log in again.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    @staticmethod
    async def verify_user_token(token: str, db: AsyncSession) -> Optional[User]:
        """
        Verify token and return user (without raising exceptions).
        
        Useful for optional authentication or token validation.
        
        Args:
            token: JWT token string
            db: Database session
            
        Returns:
            User instance if token is valid, None otherwise
            
        Example:
            user = await AuthService.verify_user_token(token, db)
            if user:
                # Token is valid
                pass
        """
        try:
            payload = verify_token(token, token_type="access")
            user_id = payload.get("sub")
            
            if not user_id:
                return None
            
            user = await User.get_by_id(db, user_id)
            return user
            
        except Exception as e:
            logger.warning(f"Token verification failed: {str(e)}")
            return None
