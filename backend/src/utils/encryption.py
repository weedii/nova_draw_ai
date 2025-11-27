"""
Encryption utilities for securing sensitive data.
Uses Fernet (AES 128 in CBC mode) for symmetric encryption.
"""

import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from src.core.config import settings
from src.core.logger import logger


def _get_encryption_key() -> bytes:
    """
    Get or generate the encryption key from environment variables.

    Tries multiple sources:
    1. ENCRYPTION_KEY environment variable (base64 encoded)
    2. APP_SECRET environment variable (derives key using PBKDF2)
    3. Generates a new key if neither is set

    Returns:
        Base64 encoded encryption key
    """
    # Try to get explicit encryption key
    encryption_key = settings.ENCRYPTION_KEY
    if encryption_key:
        try:
            # The key is already in the correct format, just encode it to bytes
            return encryption_key.encode("utf-8")
        except Exception as e:
            logger.warning(f"Failed to process ENCRYPTION_KEY: {e}")

    # Generate a new key if nothing is configured
    logger.warning(
        "No ENCRYPTION_KEY found. Generating a new key. "
        "This key will NOT persist across restarts. "
        "Set ENCRYPTION_KEY in .env for production."
    )
    return Fernet.generate_key()


# Initialize cipher with the key
_CIPHER_KEY = _get_encryption_key()
_CIPHER = Fernet(_CIPHER_KEY)


def encrypt_value(value: str) -> str:
    """
    Encrypt a string value using Fernet encryption.

    Args:
        value: Plain text value to encrypt

    Returns:
        Encrypted value (base64 encoded)

    Raises:
        ValueError: If encryption fails

    Example:
        encrypted = encrypt_value("sensitive_data")
    """
    if value is None:
        return None

    try:
        # Convert to bytes, encrypt, and return as string
        encrypted_bytes = _CIPHER.encrypt(value.encode())
        return encrypted_bytes.decode()
    except Exception as e:
        logger.error(f"Encryption failed: {e}")
        raise ValueError(f"Failed to encrypt value: {str(e)}")


def decrypt_value(encrypted_value: str) -> str:
    """
    Decrypt a string value using Fernet encryption.

    Args:
        encrypted_value: Encrypted value (base64 encoded)

    Returns:
        Plain text value

    Raises:
        ValueError: If decryption fails

    Example:
        decrypted = decrypt_value(encrypted)
    """
    if encrypted_value is None:
        return None

    try:
        # Convert to bytes, decrypt, and return as string
        decrypted_bytes = _CIPHER.decrypt(encrypted_value.encode())
        return decrypted_bytes.decode()
    except Exception as e:
        logger.error(f"Decryption failed: {e}")
        raise ValueError(f"Failed to decrypt value: {str(e)}")


def generate_encryption_key() -> str:
    """
    Generate a new encryption key for use in .env file.

    Returns:
        Base64 encoded encryption key

    Example:
        key = generate_encryption_key()
        print(f"ENCRYPTION_KEY={key}")
    """
    key = Fernet.generate_key()
    return key.decode()
