"""
TutorialService for managing tutorial operations.

Provides business logic for fetching tutorials and their steps.
"""

import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from src.models import Tutorial, TutorialStep as TutorialStepModel
from src.repositories import TutorialRepository
from src.schemas import TutorialStep, TutorialMetadata, FullTutorialResponse

logger = logging.getLogger(__name__)


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

            logger.info(f"Selected tutorial: {tutorial.subject} (ID: {tutorial.id})")

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
                    subject=tutorial.subject,
                    total_steps=tutorial.total_steps,
                ),
                steps=tutorial_steps,
            )

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get tutorial by subject: {str(e)}")
            raise ValueError(f"Failed to load tutorial: {str(e)}")
