#!/usr/bin/env python3
"""
Utility script to generate a secure encryption key for the application.

Usage:
    python scripts/generate_encryption_key.py
"""

import base64
from cryptography.fernet import Fernet


def generate_encryption_key() -> str:
    """
    Generate a new secure encryption key.

    Returns:
        str: A base64-encoded encryption key suitable for use with Fernet.
    """
    return Fernet.generate_key().decode("utf-8")


if __name__ == "__main__":
    key = generate_encryption_key()
    print("\nGenerated ENCRYPTION_KEY (add this to your .env file):")
    print("-" * 50)
    print(f"ENCRYPTION_KEY={key}")
    print("-" * 50)
    print("\nCopy the line above and add it to your .env file in the project root.")
