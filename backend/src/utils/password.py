"""
Password hashing and verification utilities.

Uses passlib with bcrypt for secure password hashing.
Bcrypt is the industry standard for password hashing - more secure than Fernet for passwords.

Note: This is separate from the Fernet encryption used for other sensitive data.
- Use bcrypt (this module) for passwords
- Use Fernet (encryption.py) for other encrypted fields

Usage:
    from utils.password import hash_password, verify_password

    # Hash a password
    hashed = hash_password("kid_password123")

    # Verify a password
    is_valid = verify_password("kid_password123", hashed)
"""

from passlib.context import CryptContext
import logging

logger = logging.getLogger(__name__)

# Create password context with bcrypt
# Bcrypt automatically handles salting and is resistant to rainbow table attacks
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash a plain text password using bcrypt.

    Bcrypt automatically:
    - Generates a unique salt for each password
    - Uses multiple rounds of hashing (cost factor)
    - Stores the salt and hash together in the output

    Args:
        password: Plain text password to hash

    Returns:
        Hashed password string (includes salt and hash)

    Example:
        hashed = hash_password("my_secure_password")
        # Returns: "$2b$12$KIXxLV..." (60 chars)
    """
    if not password:
        raise ValueError("Password cannot be empty")

    try:
        hashed = pwd_context.hash(password)
        return hashed
    except Exception as e:
        logger.error(f"Password hashing failed: {str(e)}")
        raise ValueError(f"Failed to hash password: {str(e)}")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain text password against a hashed password.

    Uses constant-time comparison to prevent timing attacks.

    Args:
        plain_password: Plain text password to verify
        hashed_password: Hashed password from database

    Returns:
        True if password matches, False otherwise

    Example:
        is_valid = verify_password("user_input", stored_hash)
        if is_valid:
            # Password is correct
            pass
    """
    if not plain_password or not hashed_password:
        return False

    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        logger.error(f"Password verification failed: {str(e)}")
        return False


def validate_password_strength(password: str, min_length: int = 6) -> tuple[bool, str]:
    """
    Validate password strength with kid-friendly requirements.

    For a kids' app, we keep requirements simple but secure:
    - Minimum length (default: 6 characters)
    - Not too complex to remember

    Args:
        password: Password to validate
        min_length: Minimum password length (default: 6)

    Returns:
        Tuple of (is_valid: bool, message: str)

    Example:
        is_valid, message = validate_password_strength("abc123")
        if not is_valid:
            print(message)  # "Password is too short"
    """
    if not password:
        return False, "Password cannot be empty"

    if len(password) < min_length:
        return False, f"Password must be at least {min_length} characters long"

    # Optional: Add more rules for stronger security
    # For kids, we keep it simple - just length requirement
    # You can add more rules here if needed:
    # - Must contain at least one number
    # - Must contain at least one letter
    # etc.

    return True, "Password is valid"
