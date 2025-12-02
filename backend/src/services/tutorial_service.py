"""
TutorialService for managing tutorial operations.

Provides business logic for fetching tutorials and their steps.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from src.models import Tutorial, TutorialStep as TutorialStepModel
from src.repositories import TutorialRepository
from src.schemas import (
    TutorialStep,
    TutorialMetadata,
    FullTutorialResponse,
    TutorialDrawingResponse,
    CategoryWithNestedDrawingsResponse,
    AllCategoriesWithDrawingsResponse,
)
from src.core.logger import logger


class TutorialService:
    """Service for tutorial operations"""

    @staticmethod
    async def get_tutorial_by_subject(
        db: AsyncSession, subject: str
    ) -> FullTutorialResponse:
        """
        Get a random tutorial by subject with all its steps.

        Flow:
        1. Find a random tutorial by subject
        2. Load all steps for that tutorial
        3. Convert to response format
        4. Return tutorial with steps

        Args:
            db: Async database session
            subject: Tutorial subject name

        Returns:
            FullTutorialResponse with tutorial metadata and steps

        Raises:
            ValueError: If subject not found or no steps available
        """

        try:
            # Step 1: Find a random tutorial by subject
            tutorial = await TutorialRepository.find_by_subject(db, subject)

            if not tutorial:
                raise ValueError(
                    f"Subject '{subject}' not found in database. Please check the available subjects."
                )

            logger.info(f"Selected tutorial: {tutorial.subject_en} (ID: {tutorial.id})")

            # Step 2: Get all steps for this specific tutorial
            query = (
                select(TutorialStepModel)
                .where(TutorialStepModel.tutorial_id == tutorial.id)
                .order_by(TutorialStepModel.step_number)
            )
            result = await db.execute(query)
            tutorial_steps_data = result.scalars().all()

            if not tutorial_steps_data:
                logger.warning(f"No steps found for tutorial {tutorial.id}")
                raise ValueError(f"No steps found for tutorial '{subject}'")

            logger.info(f"Found {len(tutorial_steps_data)} steps for tutorial")

            # Step 3: Convert to the expected response format
            tutorial_steps = []
            for step_data in tutorial_steps_data:
                tutorial_steps.append(
                    TutorialStep(
                        step_en=step_data.instruction_en,
                        step_de=step_data.instruction_de,
                        step_img=step_data.image_url,
                    )
                )

            # Step 4: Return tutorial with all its steps
            return FullTutorialResponse(
                success="true",
                metadata=TutorialMetadata(
                    tutorial_id=str(tutorial.id),
                    subject_en=tutorial.subject_en,
                    subject_de=tutorial.subject_de,
                    total_steps=tutorial.total_steps,
                ),
                steps=tutorial_steps,
            )

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get tutorial by subject: {str(e)}")
            raise ValueError(f"Failed to load tutorial: {str(e)}")

    @staticmethod
    async def get_all_categories_with_nested_drawings(
        db: AsyncSession,
    ) -> "AllCategoriesWithDrawingsResponse":
        """
        Get all categories with their nested drawings.

        This method queries all tutorials, groups them by category, and returns
        a nested structure with categories containing their drawings.

        Drawings are deduplicated by subject - each unique subject appears only once
        per category, even if multiple tutorials exist for the same subject.

        Args:
            db: Async database session

        Returns:
            AllCategoriesWithDrawingsResponse with nested category/drawing structure

        Raises:
            ValueError: If no tutorials found or database error

        Example:
            response = await TutorialService.get_all_categories_with_nested_drawings(db)
        """

        try:
            logger.info("Fetching all tutorials grouped by category")

            # Get all tutorials ordered by category
            tutorials = await TutorialRepository.get_all_tutorials_grouped_by_category(
                db
            )

            if not tutorials:
                logger.warning("No tutorials found in database")
                raise ValueError("No tutorials available")

            logger.info(f"Found {len(tutorials)} tutorials")

            # Group tutorials by category and deduplicate drawings by subject
            categories_dict = {}
            for tutorial in tutorials:
                category_key = f"{tutorial.category_en}|{tutorial.category_de}"

                if category_key not in categories_dict:
                    categories_dict[category_key] = {
                        "category_en": tutorial.category_en,
                        "category_de": tutorial.category_de,
                        "description_en": None,
                        "description_de": None,
                        "emoji": tutorial.category_emoji,
                        "color": tutorial.category_color,
                        "drawings": {},  # Use dict to track unique subjects
                        "drawings_list": [],  # Maintain order
                    }

                # Add drawing to category only if subject not already present
                subject_key = f"{tutorial.subject_en}|{tutorial.subject_de}"
                if subject_key not in categories_dict[category_key]["drawings"]:
                    drawing = TutorialDrawingResponse(
                        subject_en=tutorial.subject_en,
                        subject_de=tutorial.subject_de,
                        emoji=tutorial.subject_emoji,
                        total_steps=tutorial.total_steps,
                        thumbnail_url=tutorial.thumbnail_url,
                        description_en=tutorial.description_en,
                        description_de=tutorial.description_de,
                    )
                    categories_dict[category_key]["drawings"][subject_key] = drawing
                    categories_dict[category_key]["drawings_list"].append(drawing)

            # Convert to response format
            categories_list = [
                CategoryWithNestedDrawingsResponse(
                    category_en=cat_data["category_en"],
                    category_de=cat_data["category_de"],
                    description_en=cat_data["description_en"],
                    description_de=cat_data["description_de"],
                    emoji=cat_data["emoji"],
                    color=cat_data["color"],
                    drawings=cat_data["drawings_list"],
                )
                for cat_data in categories_dict.values()
            ]

            logger.info(f"Returning {len(categories_list)} categories")

            return AllCategoriesWithDrawingsResponse(
                success=True, data=categories_list, count=len(categories_list)
            )

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get categories with drawings: {str(e)}")
            raise ValueError(f"Failed to load categories: {str(e)}")

    @staticmethod
    async def get_all_drawings_for_category(
        db: AsyncSession, category: str
    ) -> List["TutorialDrawingResponse"]:
        """
        Get all drawings for a specific category.

        Drawings are deduplicated by subject - each unique subject appears only once,
        even if multiple tutorials exist for the same subject.

        Args:
            db: Async database session
            category: Category name to filter by

        Returns:
            List of TutorialDrawingResponse objects

        Raises:
            ValueError: If category not found or no drawings available

        Example:
            drawings = await TutorialService.get_all_drawings_for_category(db, "Animals")
        """

        try:
            logger.info(f"Fetching drawings for category '{category}'")

            # Get all tutorials for this category
            tutorials = await TutorialRepository.get_all_tutorials_for_category(
                db, category
            )

            if not tutorials:
                logger.warning(f"No tutorials found for category '{category}'")
                raise ValueError(f"No drawings found in category '{category}'")

            logger.info(f"Found {len(tutorials)} tutorials in category '{category}'")

            # Deduplicate drawings by subject - keep only first occurrence
            seen_subjects = set()
            drawings = []
            for tutorial in tutorials:
                subject_key = f"{tutorial.subject_en}|{tutorial.subject_de}"
                if subject_key not in seen_subjects:
                    drawing = TutorialDrawingResponse(
                        subject_en=tutorial.subject_en,
                        subject_de=tutorial.subject_de,
                        emoji=tutorial.subject_emoji,
                        total_steps=tutorial.total_steps,
                        thumbnail_url=tutorial.thumbnail_url,
                        description_en=tutorial.description_en,
                        description_de=tutorial.description_de,
                    )
                    drawings.append(drawing)
                    seen_subjects.add(subject_key)

            logger.info(
                f"Returning {len(drawings)} unique drawings from {len(tutorials)} tutorials"
            )

            return drawings

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get drawings for category '{category}': {str(e)}")
            raise ValueError(f"Failed to load drawings: {str(e)}")
