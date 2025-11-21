"""
EditOptionService for managing edit option operations.

Provides business logic for fetching and managing edit options.
This service layer handles:
- Validation of input data
- Complex queries and transformations
- Error handling and logging
- Business rule enforcement

Why this service exists:
- Separates business logic from API endpoints
- Provides reusable methods for multiple endpoints
- Centralizes error handling and validation
- Makes testing easier
"""

import logging
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from src.models import EditOption
from src.repositories import EditOptionRepository
from src.schemas import EditOptionRead, EditOptionsListResponse

logger = logging.getLogger(__name__)


class EditOptionService:
    """Service for edit option operations"""

    @staticmethod
    async def get_edit_options_by_subject(
        db: AsyncSession, category: str, subject: str
    ) -> EditOptionsListResponse:
        """
        Get all edit options for a specific category and subject.

        This is the main method called when a kid selects a subject and needs
        to see all available edit options for that subject.

        Flow:
        1. Validate that category and subject exist
        2. Query all edit options for this category/subject
        3. Convert to response format
        4. Return with success status

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals')
            subject: Subject name (e.g., 'dog')

        Returns:
            EditOptionsListResponse with list of edit options

        Raises:
            ValueError: If category/subject not found or no options available

        Example:
            response = await EditOptionService.get_edit_options_by_subject(
                db, "Animals", "dog"
            )
        """
        try:
            # Step 1: Validate that the category/subject combination exists
            exists = await EditOptionRepository.subject_exists_in_category(
                db, category, subject
            )
            if not exists:
                logger.warning(
                    f"No edit options found for category='{category}', subject='{subject}'"
                )
                raise ValueError(
                    f"No edit options found for subject '{subject}' in category '{category}'"
                )

            logger.info(f"Fetching edit options for {category}/{subject}")

            # Step 2: Query all edit options for this category/subject
            edit_options = await EditOptionRepository.find_by_category_and_subject(
                db, category, subject
            )

            if not edit_options:
                logger.warning(f"Database returned empty list for {category}/{subject}")
                raise ValueError(
                    f"No edit options available for '{subject}' in '{category}'"
                )

            logger.info(
                f"Found {len(edit_options)} edit options for {category}/{subject}"
            )

            # Step 3: Convert to response format
            options_data = [
                EditOptionRead(
                    id=str(option.id),
                    category=option.category,
                    subject=option.subject,
                    title_en=option.title_en,
                    title_de=option.title_de,
                    description_en=option.description_en,
                    description_de=option.description_de,
                    prompt_en=option.prompt_en,
                    prompt_de=option.prompt_de,
                    icon=option.icon,
                    created_at=option.created_at,
                    updated_at=option.updated_at,
                )
                for option in edit_options
            ]

            # Step 4: Return with success status
            return EditOptionsListResponse(
                success=True, data=options_data, count=len(options_data)
            )

        except ValueError:
            raise
        except Exception as e:
            logger.error(
                f"Failed to get edit options for {category}/{subject}: {str(e)}"
            )
            raise ValueError(f"Failed to load edit options: {str(e)}")

    @staticmethod
    async def get_categories(db: AsyncSession) -> EditOptionsListResponse:
        """
        Get all unique categories that have edit options.

        Used for displaying available categories to the user.

        Args:
            db: Async database session

        Returns:
            EditOptionsListResponse with list of category names

        Raises:
            ValueError: If no categories found

        Example:
            response = await EditOptionService.get_categories(db)
        """
        try:
            logger.info("Fetching all categories")

            categories = await EditOptionRepository.get_all_categories(db)

            if not categories:
                logger.warning("No categories found in database")
                raise ValueError("No categories available")

            logger.info(f"Found {len(categories)} categories")

            # Return categories as strings (not EditOptionRead objects)
            # This is a simplified response for category listing
            return {
                "success": True,
                "data": categories,
                "count": len(categories),
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get categories: {str(e)}")
            raise ValueError(f"Failed to load categories: {str(e)}")

    @staticmethod
    async def get_subjects_by_category(
        db: AsyncSession, category: str
    ) -> EditOptionsListResponse:
        """
        Get all unique subjects in a specific category.

        Used for displaying available subjects when a category is selected.

        Args:
            db: Async database session
            category: Category name

        Returns:
            EditOptionsListResponse with list of subject names

        Raises:
            ValueError: If category not found or no subjects available

        Example:
            response = await EditOptionService.get_subjects_by_category(db, "Animals")
        """
        try:
            logger.info(f"Fetching subjects for category '{category}'")

            # Validate category exists
            exists = await EditOptionRepository.category_exists(db, category)
            if not exists:
                logger.warning(f"Category '{category}' not found")
                raise ValueError(f"Category '{category}' not found")

            subjects = await EditOptionRepository.get_subjects_by_category(db, category)

            if not subjects:
                logger.warning(f"No subjects found for category '{category}'")
                raise ValueError(f"No subjects available in category '{category}'")

            logger.info(f"Found {len(subjects)} subjects in category '{category}'")

            # Return subjects as strings
            return {
                "success": True,
                "data": subjects,
                "count": len(subjects),
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get subjects for category '{category}': {str(e)}")
            raise ValueError(f"Failed to load subjects: {str(e)}")
