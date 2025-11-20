"""
Utilities package for Nova Draw AI backend.
Includes decorators, encryption, authentication, and helper functions.
"""

# Decorators
from .decorators import (
    timestamped,
    auditable,
    auto_updated,
    creation_tracked,
)

# CRUD decorators
from .crud_decorators import crud_enabled

# Encryption decorators
from .encryption_decorators import (
    encrypted_field,
    encrypt_field_value,
    decrypt_field_value,
)

# Encryption utilities
from .encryption import (
    encrypt_value,
    decrypt_value,
    generate_encryption_key,
)

# JWT utilities
from .jwt import (
    create_access_token,
    create_refresh_token,
    verify_token,
    decode_token_without_verification,
)

# Password utilities
from .password import (
    hash_password,
    verify_password,
    validate_password_strength,
)

# File operations
from .file_operations import (
    sanitize_filename,
    create_session_folder,
    get_session_folder,
)

__all__ = [
    # Decorators
    "timestamped",
    "auditable",
    "auto_updated",
    "creation_tracked",
    # CRUD
    "crud_enabled",
    # Encryption decorators
    "encrypted_field",
    "encrypt_field_value",
    "decrypt_field_value",
    # Encryption utilities
    "encrypt_value",
    "decrypt_value",
    "generate_encryption_key",
    # JWT utilities
    "create_access_token",
    "create_refresh_token",
    "verify_token",
    "decode_token_without_verification",
    # Password utilities
    "hash_password",
    "verify_password",
    "validate_password_strength",
    # File operations
    "sanitize_filename",
    "create_session_folder",
    "get_session_folder",
]
