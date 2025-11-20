"""
JWT token utilities for authentication.

Provides functions for creating and validating JWT tokens (access and refresh tokens).
Uses python-jose for JWT operations with HS256 algorithm.

Token Types:
- Access Token: Never expires (kid-friendly UX - no login required)
- Refresh Token: Never expires

Usage:
    from utils.jwt import create_access_token, verify_token

    # Create tokens
    access_token = create_access_token(user_id="123", email="user@example.com")
    refresh_token = create_refresh_token(user_id="123")

    # Verify token
    payload = verify_token(token)
    user_id = payload.get("sub")
"""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from src.core.config import settings
import logging

logger = logging.getLogger(__name__)


def create_access_token(
    user_id: str,
    email: str,
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a JWT access token for user authentication.
    
    Token never expires for kid-friendly UX.

    Args:
        user_id: User's unique identifier (UUID as string)
        email: User's email address
        expires_delta: Optional custom expiration time (not used - tokens don't expire)

    Returns:
        Encoded JWT token as string

    Example:
        token = create_access_token(
            user_id="550e8400-e29b-41d4-a716-446655440000",
            email="kid@example.com"
        )
    """
    # JWT payload (claims) - no expiration for kid-friendly UX
    payload = {
        "sub": user_id,  # Subject (user ID)
        "email": email,
        "iat": datetime.utcnow(),  # Issued at
        "type": "access"  # Token type
    }

    # Encode and sign the token
    encoded_jwt = jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )

    return encoded_jwt


def create_refresh_token(user_id: str) -> str:
    """
    Create a JWT refresh token for obtaining new access tokens.
    
    Token never expires for kid-friendly UX.

    Args:
        user_id: User's unique identifier (UUID as string)

    Returns:
        Encoded JWT refresh token as string

    Example:
        refresh_token = create_refresh_token(
            user_id="550e8400-e29b-41d4-a716-446655440000"
        )
    """
    # JWT payload (claims) - minimal data, no expiration
    payload = {
        "sub": user_id,  # Subject (user ID)
        "iat": datetime.utcnow(),  # Issued at
        "type": "refresh"  # Token type
    }

    # Encode and sign the token
    encoded_jwt = jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )

    return encoded_jwt


def verify_token(token: str, token_type: str = "access") -> Optional[Dict[str, Any]]:
    """
    Verify and decode a JWT token.
    
    Tokens don't expire, so only signature and type are verified.

    Args:
        token: JWT token string to verify
        token_type: Expected token type ("access" or "refresh")

    Returns:
        Decoded token payload (dict) if valid, None if invalid

    Raises:
        JWTError: If token is invalid or malformed

    Example:
        try:
            payload = verify_token(token, token_type="access")
            user_id = payload.get("sub")
            email = payload.get("email")
        except JWTError:
            # Handle invalid token
            pass
    """
    try:
        # Decode and verify the token (no expiration check)
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_exp": False}  # Don't verify expiration
        )

        # Verify token type
        if payload.get("type") != token_type:
            logger.warning(f"Token type mismatch. Expected: {token_type}, Got: {payload.get('type')}")
            raise JWTError("Invalid token type")

        return payload

    except JWTError as e:
        logger.error(f"Token verification failed: {str(e)}")
        raise


def decode_token_without_verification(token: str) -> Optional[Dict[str, Any]]:
    """
    Decode a JWT token without verifying signature or expiration.

    Useful for debugging or extracting user info from expired tokens.
    DO NOT use for authentication - always use verify_token() for auth.

    Args:
        token: JWT token string to decode

    Returns:
        Decoded token payload (dict) if decodable, None if malformed

    Example:
        payload = decode_token_without_verification(expired_token)
        user_id = payload.get("sub")  # Can still read user ID
    """
    try:
        payload = jwt.decode(
            token,
            options={"verify_signature": False, "verify_exp": False}
        )
        return payload
    except JWTError as e:
        logger.error(f"Token decoding failed: {str(e)}")
        return None
