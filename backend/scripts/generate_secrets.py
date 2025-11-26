"""
Generate secure secret keys for .env configuration.

Run this script to generate:
- ENCRYPTION_KEY (Fernet key for encrypting sensitive data)
- JWT_SECRET_KEY (Secret key for signing JWT tokens)

Usage:
    python scripts/generate_secrets.py

Copy the output to your .env file.
"""

import secrets
from cryptography.fernet import Fernet


def generate_encryption_key() -> str:
    """Generate a Fernet encryption key."""
    return Fernet.generate_key().decode()


def generate_jwt_secret() -> str:
    """Generate a secure random secret for JWT signing."""
    return secrets.token_urlsafe(32)


if __name__ == "__main__":
    print("=" * 60)
    print("🔐 Secret Keys Generator for Nova Draw AI")
    print("=" * 60)
    print()
    print("Copy these values to your .env file:")
    print()
    print("-" * 60)
    print(f"ENCRYPTION_KEY={generate_encryption_key()}")
    print(f"JWT_SECRET_KEY={generate_jwt_secret()}")
    print("-" * 60)
    print()
    print("⚠️  Keep these keys secret and never commit them to git!")
    print("=" * 60)
