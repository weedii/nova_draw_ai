"""
Encryption decorators for automatic field encryption/decryption.
Provides transparent encryption for sensitive database fields.

Supports async SQLAlchemy operations.
"""

from typing import Type, Any, List, Set
from sqlalchemy import event
from sqlalchemy.orm import InstanceState
from .encryption import encrypt_value, decrypt_value


def encrypted_field(*field_names: str) -> Type[Any]:
    """
    Decorator to automatically encrypt/decrypt specified fields in a SQLAlchemy model.

    The decorator:
    1. Encrypts field values when setting them
    2. Decrypts field values when getting them
    3. Handles database storage transparently
    4. Works with existing CRUD operations

    Args:
        *field_names: Names of fields to encrypt/decrypt

    Usage:
        @encrypted_field('wallet_address', 'iban')
        @crud_enabled
        @auditable
        class UserPaymentMethod(Base):
            __tablename__ = "user_payment_methods"

            wallet_address = Column(String)  # Automatically encrypted
            iban = Column(String)            # Automatically encrypted
            currency = Column(String)        # Not encrypted

        # Usage (encryption/decryption is transparent):
        payment = await UserPaymentMethod.create(
            db,
            wallet_address="1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",  # Encrypted in DB
            iban="GB82 WEST 1234 5698 7654 32"                    # Encrypted in DB
        )

        print(payment.wallet_address)  # Prints decrypted value
        print(payment.iban)           # Prints decrypted value

    Features:
        - Transparent encryption/decryption
        - Works with all CRUD operations
        - Handles None values gracefully
        - Backward compatible with existing data
        - Secure AES encryption using Fernet
    """

    def decorator(cls: Type[Any]) -> Type[Any]:
        """Apply encryption to the specified fields."""

        # Store encrypted field names on the class
        cls._encrypted_fields = set(field_names)

        # Create property descriptors for each encrypted field
        for field_name in field_names:
            _create_encrypted_property(cls, field_name)

        # Set up SQLAlchemy event listeners
        _setup_encryption_events(cls)

        return cls

    return decorator


def _create_encrypted_property(cls: Type[Any], field_name: str) -> None:
    """
    Create a property descriptor for an encrypted field.

    This replaces the original field with a property that automatically
    encrypts on set and decrypts on get.
    """

    # Store the original column
    original_column = getattr(cls, field_name, None)

    # Create private attribute name for storing encrypted value
    private_attr = f"_encrypted_{field_name}"

    def getter(self) -> str:
        """Get and decrypt the field value."""
        # Get the encrypted value from the private attribute
        encrypted_value = getattr(self, private_attr, None)

        # If no encrypted value, try to get from the original attribute
        if encrypted_value is None and hasattr(self, f"_{field_name}"):
            encrypted_value = getattr(self, f"_{field_name}")

        # Decrypt and return
        return decrypt_value(encrypted_value)

    def setter(self, value: str) -> None:
        """Encrypt and set the field value."""
        if value is None:
            # Handle None values
            setattr(self, private_attr, None)
            if hasattr(self, f"_{field_name}"):
                setattr(self, f"_{field_name}", None)
        else:
            # Encrypt the value
            encrypted_value = encrypt_value(str(value))
            setattr(self, private_attr, encrypted_value)

            # Also set the original column attribute for database storage
            if hasattr(self, f"_{field_name}"):
                setattr(self, f"_{field_name}", encrypted_value)

    # Create the property
    encrypted_property = property(getter, setter)

    # Replace the original attribute with our encrypted property
    setattr(cls, field_name, encrypted_property)

    # Keep reference to original column
    if original_column is not None:
        setattr(cls, f"_{field_name}_column", original_column)


def _setup_encryption_events(cls: Type[Any]) -> None:
    """
    Set up SQLAlchemy event listeners for encryption/decryption.

    These events ensure that data is encrypted before database operations
    and decrypted after loading from the database.
    """

    @event.listens_for(cls, "before_insert")
    def encrypt_before_insert(mapper, connection, target):
        """Encrypt fields before inserting into database."""
        _encrypt_fields_for_db(target)

    @event.listens_for(cls, "before_update")
    def encrypt_before_update(mapper, connection, target):
        """Encrypt fields before updating in database."""
        _encrypt_fields_for_db(target)

    @event.listens_for(cls, "load")
    def decrypt_after_load(target, context):
        """Decrypt fields after loading from database."""
        _decrypt_fields_from_db(target)


def _encrypt_fields_for_db(instance: Any) -> None:
    """
    Encrypt all encrypted fields before database operations.

    This ensures that the actual database columns contain encrypted values.
    """
    if not hasattr(instance, "_encrypted_fields"):
        return

    for field_name in instance._encrypted_fields:
        # Get the current value (which should be plain text)
        plain_value = getattr(instance, f"_encrypted_{field_name}", None)

        if plain_value is not None:
            # Ensure it's encrypted for database storage
            encrypted_value = encrypt_value(plain_value) if plain_value else None

            # Set the database column directly
            if hasattr(instance, f"_{field_name}"):
                setattr(instance, f"_{field_name}", encrypted_value)


def _decrypt_fields_from_db(instance: Any) -> None:
    """
    Set up decryption for fields loaded from database.

    This prepares the instance so that accessing encrypted fields
    will return decrypted values.
    """
    if not hasattr(instance, "_encrypted_fields"):
        return

    for field_name in instance._encrypted_fields:
        # Get the encrypted value from database column
        if hasattr(instance, f"_{field_name}"):
            encrypted_value = getattr(instance, f"_{field_name}")
            # Store it in our private encrypted attribute
            setattr(instance, f"_encrypted_{field_name}", encrypted_value)


# Utility functions for manual encryption/decryption
def encrypt_field_value(value: str) -> str:
    """
    Manually encrypt a field value.

    Args:
        value: Plain text value to encrypt

    Returns:
        Encrypted value

    Example:
        encrypted_iban = encrypt_field_value("GB82 WEST 1234 5698 7654 32")
    """
    return encrypt_value(value)


def decrypt_field_value(encrypted_value: str) -> str:
    """
    Manually decrypt a field value.

    Args:
        encrypted_value: Encrypted value to decrypt

    Returns:
        Plain text value

    Example:
        plain_iban = decrypt_field_value(encrypted_iban)
    """
    return decrypt_value(encrypted_value)
