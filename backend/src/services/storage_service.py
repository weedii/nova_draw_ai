"""
Storage service for managing image uploads to DigitalOcean Spaces (S3-compatible).
Handles uploading, downloading, and managing image URLs.
"""

import logging
import base64
from io import BytesIO
from pathlib import Path
from datetime import datetime
from uuid import UUID
import boto3
from botocore.exceptions import ClientError
from src.core.config import settings

logger = logging.getLogger(__name__)


class StorageService:
    """Service for managing image storage in DigitalOcean Spaces"""

    def __init__(self):
        """Initialize S3 client for DigitalOcean Spaces"""
        logger.info("Initializing StorageService...")

        # Validate required settings
        if not settings.SPACES_KEY:
            raise ValueError("SPACES_KEY is not configured")
        if not settings.SPACES_SECRET:
            raise ValueError("SPACES_SECRET is not configured")
        if not settings.STORAGE_ENDPOINT_URL:
            raise ValueError("STORAGE_ENDPOINT_URL is not configured")

        # Initialize S3 client for DigitalOcean Spaces
        self.s3_client = boto3.client(
            "s3",
            region_name="nyc3",  # DigitalOcean Spaces region
            endpoint_url=settings.STORAGE_ENDPOINT_URL,
            aws_access_key_id=settings.SPACES_KEY,
            aws_secret_access_key=settings.SPACES_SECRET,
        )

        # Bucket name - using app name as bucket
        self.bucket_name = "novadraw"

        logger.info("✅ StorageService initialized successfully")
        logger.info(f"📦 Bucket: {self.bucket_name}")
        logger.info(f"🌐 Endpoint: {settings.STORAGE_ENDPOINT_URL}")

    def _generate_file_key(
        self, user_id: UUID, image_type: str, file_extension: str = "png"
    ) -> str:
        """
        Generate a unique S3 key for storing images.

        Args:
            user_id: UUID of the user
            image_type: Type of image ('original' or 'edited')
            file_extension: File extension (default: 'png')

        Returns:
            S3 key path (e.g., 'users/user-id/original/timestamp.png')
        """

        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        key = f"users/{user_id}/{image_type}/{timestamp}.{file_extension}"
        return key

    def upload_image_from_bytes(
        self, image_bytes: bytes, user_id: UUID, image_type: str = "edited"
    ) -> str:
        """
        Upload an image from bytes to DigitalOcean Spaces.

        Args:
            image_bytes: Raw image bytes
            user_id: UUID of the user
            image_type: Type of image ('original' or 'edited')

        Returns:
            Public URL of the uploaded image

        Raises:
            ValueError: If upload fails
        """

        try:
            # Generate S3 key
            key = self._generate_file_key(user_id, image_type)

            logger.info(f"📤 Uploading image to Spaces: {key}")
            logger.info(f"📊 Image size: {len(image_bytes)} bytes")

            # Upload to S3
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=image_bytes,
                ContentType="image/png",
                ACL="public-read",  # Make image publicly accessible
            )

            # Generate public URL
            # DigitalOcean Spaces URL format: https://bucket.region.cdn.digitaloceanspaces.com/key
            public_url = f"{settings.STORAGE_ENDPOINT_URL}/{self.bucket_name}/{key}"

            logger.info(f"✅ Image uploaded successfully")
            logger.info(f"🔗 Public URL: {public_url}")

            return public_url

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            error_msg = e.response["Error"]["Message"]
            logger.error(f"❌ S3 upload failed: {error_code} - {error_msg}")
            raise ValueError(f"Failed to upload image to storage: {error_msg}")
        except Exception as e:
            logger.error(f"❌ Unexpected error during upload: {str(e)}")
            raise ValueError(f"Unexpected error during image upload: {str(e)}")

    def upload_image_from_base64(
        self, base64_image: str, user_id: UUID, image_type: str = "edited"
    ) -> str:
        """
        Upload an image from base64 string to DigitalOcean Spaces.

        Args:
            base64_image: Base64 encoded image string
            user_id: UUID of the user
            image_type: Type of image ('original' or 'edited')

        Returns:
            Public URL of the uploaded image

        Raises:
            ValueError: If conversion or upload fails
        """

        try:
            # Decode base64 to bytes
            logger.info("🔄 Decoding base64 image...")
            image_bytes = base64.b64decode(base64_image)
            logger.info(f"✅ Decoded {len(image_bytes)} bytes from base64")

            # Upload using bytes method
            return self.upload_image_from_bytes(image_bytes, user_id, image_type)

        except Exception as e:
            logger.error(f"❌ Failed to process base64 image: {str(e)}")
            raise ValueError(f"Failed to process base64 image: {str(e)}")

    def download_image_as_bytes(self, image_url: str) -> bytes:
        """
        Download an image from Spaces and return as bytes.

        Args:
            image_url: Public URL of the image

        Returns:
            Image bytes

        Raises:
            ValueError: If download fails
        """

        try:
            # Extract key from URL
            # URL format: https://bucket.region.cdn.digitaloceanspaces.com/key
            key = image_url.split(f"{self.bucket_name}/", 1)[1]

            logger.info(f"📥 Downloading image from Spaces: {key}")

            # Download from S3
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=key)
            image_bytes = response["Body"].read()

            logger.info(f"✅ Downloaded {len(image_bytes)} bytes")

            return image_bytes

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            logger.error(f"❌ S3 download failed: {error_code}")
            raise ValueError(f"Failed to download image from storage: {error_code}")
        except Exception as e:
            logger.error(f"❌ Unexpected error during download: {str(e)}")
            raise ValueError(f"Unexpected error during image download: {str(e)}")

    def delete_image(self, image_url: str) -> bool:
        """
        Delete an image from Spaces.

        Args:
            image_url: Public URL of the image

        Returns:
            True if deletion successful, False otherwise
        """

        try:
            # Extract key from URL
            key = image_url.split(f"{self.bucket_name}/", 1)[1]

            logger.info(f"🗑️  Deleting image from Spaces: {key}")

            # Delete from S3
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=key)

            logger.info(f"✅ Image deleted successfully")

            return True

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            logger.error(f"❌ S3 deletion failed: {error_code}")
            return False
        except Exception as e:
            logger.error(f"❌ Unexpected error during deletion: {str(e)}")
            return False

    def get_bucket_info(self) -> dict:
        """
        Get information about the Spaces bucket.

        Returns:
            Dictionary with bucket information
        """

        try:
            response = self.s3_client.head_bucket(Bucket=self.bucket_name)
            logger.info(f"✅ Bucket info retrieved: {response}")
            return response
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            logger.error(f"❌ Failed to get bucket info: {error_code}")
            return {}

    def validate_and_extract_user_id(self, image_url: str) -> UUID:
        """
        Validate that a URL is a valid Spaces URL and extract the user_id from it.

        URL format: https://bucket.region.cdn.digitaloceanspaces.com/users/{user_id}/...

        Args:
            image_url: URL to validate

        Returns:
            UUID of the user who owns the image

        Raises:
            ValueError: If URL is invalid or doesn't belong to Spaces
        """

        try:
            # Check if URL contains the bucket name
            if self.bucket_name not in image_url:
                raise ValueError(f"URL does not belong to {self.bucket_name} bucket")

            # Extract the key from URL
            key = image_url.split(f"{self.bucket_name}/", 1)[1]

            # Parse the key to extract user_id
            # Key format: users/{user_id}/original/... or users/{user_id}/edited/...
            parts = key.split("/")

            if len(parts) < 2 or parts[0] != "users":
                raise ValueError("Invalid image URL format")

            user_id_str = parts[1]

            # Validate that it's a valid UUID
            user_id = UUID(user_id_str)

            logger.info(f"✅ URL validated. User ID: {user_id}")

            return user_id

        except ValueError as e:
            logger.error(f"❌ URL validation failed: {str(e)}")
            raise ValueError(f"Invalid image URL: {str(e)}")
        except Exception as e:
            logger.error(f"❌ Unexpected error during URL validation: {str(e)}")
            raise ValueError(f"Failed to validate image URL: {str(e)}")
