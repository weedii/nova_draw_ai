# Nova Draw AI Backend Architecture

## Overview

The Nova Draw AI backend follows a **three-layer architecture pattern** that ensures clean separation of concerns, maintainability, and scalability.

```
┌─────────────────────────────────────────────────────────────┐
│                    HTTP Request                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │   ENDPOINT LAYER (FastAPI)     │
        │  - Request validation          │
        │  - File handling               │
        │  - HTTP response formatting    │
        │  - Exception handling          │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │   SERVICE LAYER (Business)     │
        │  - Business logic              │
        │  - Data validation             │
        │  - AI/ML operations            │
        │  - Database coordination       │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  REPOSITORY LAYER (Database)   │
        │  - Custom queries              │
        │  - Data access patterns        │
        │  - Model operations            │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │    Neon PostgreSQL Database    │
        └────────────────────────────────┘
```

---

## Layer Responsibilities

### 1. Endpoint Layer (`src/endpoints/`)

**Responsibility**: Handle HTTP communication

**Responsibilities**:

- ✅ Validate incoming request format (file types, content types)
- ✅ Read and parse uploaded files
- ✅ Call service layer methods
- ✅ Format and return HTTP responses
- ✅ Handle HTTP-specific exceptions
- ✅ Convert between request/response schemas

**What NOT to do**:

- ❌ Business logic
- ❌ Database operations
- ❌ Complex validations
- ❌ Direct repository access

**Example Endpoint Structure**:

```python
from fastapi import APIRouter, HTTPException, Depends, File, UploadFile, Form
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.database import get_db
from src.services.my_service import MyService
from src.schemas import MyRequest, MyResponse
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api", tags=["my-feature"])

@router.post("/my-endpoint", response_model=MyResponse)
async def my_endpoint(
    request: MyRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Brief description of what this endpoint does.
    """

    try:
        my_service = MyService()

        # Check service availability
        if not my_service:
            raise HTTPException(
                status_code=503,
                detail="Service not available. Please configure required API keys.",
            )

        # Delegate all business logic to service layer
        result = await my_service.process_request(
            db=db,
            param1=request.param1,
            param2=request.param2,
        )

        return MyResponse(
            success="true",
            data=result["data"],
            metadata=result["metadata"],
        )

    except ValueError as e:
        # Service validation errors → 400 Bad Request
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Failed to process request: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process request: {str(e)}"
        )
```

---

### 2. Service Layer (`src/services/`)

**Responsibility**: Implement business logic

**Responsibilities**:

- ✅ Validate all inputs (images, audio, language, etc.)
- ✅ Implement business logic (generation, processing, etc.)
- ✅ Coordinate between repositories and external APIs
- ✅ Handle data transformations
- ✅ Raise `ValueError` for validation errors
- ✅ Raise custom exceptions for business logic errors

**What NOT to do**:

- ❌ Handle HTTP requests/responses
- ❌ Return HTTP status codes
- ❌ Access request/response objects directly
- ❌ Handle file uploads (done by endpoint)

**Example Service Structure**:

```python
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Dict, Any
from src.repositories import MyRepository
from src.models import MyModel

logger = logging.getLogger(__name__)

class MyService:
    """Service for my feature operations"""

    def __init__(self):
        """Initialize service with required dependencies"""

        logger.info("Initializing MyService...")
        # Initialize API clients, validate configs, etc.
        logger.info("MyService initialized successfully")

    def validate_input(self, data: str) -> bool:
        """
        Validate input data.

        Args:
            data: Input to validate

        Returns:
            True if valid, False otherwise

        Raises:
            ValueError: If validation fails
        """

        if not data:
            raise ValueError("Data cannot be empty")
        if len(data) > 1000:
            raise ValueError("Data too long (max 1000 characters)")
        return True

    async def process_data(
        self,
        db: AsyncSession,
        input_data: str,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Process data and save to database.

        Args:
            db: Async database session
            input_data: Data to process
            user_id: UUID of the user

        Returns:
            Dictionary with processed results

        Raises:
            ValueError: If validation fails
        """

        try:
            # Step 1: Validate input
            self.validate_input(input_data)
            logger.info(f"Input validation passed")

            # Step 2: Process data
            processed_result = self._process_logic(input_data)
            logger.info(f"Data processed successfully")

            # Step 3: Save to database using model
            saved_record = await MyModel.create(
                db,
                user_id=user_id,
                data=processed_result,
            )
            logger.info(f"Record saved to database: {saved_record.id}")

            # Step 4: Return results
            return {
                "record_id": str(saved_record.id),
                "result": processed_result,
                "timestamp": saved_record.created_at,
            }

        except ValueError:
            # Re-raise validation errors
            raise
        except Exception as e:
            logger.error(f"Failed to process data: {str(e)}")
            raise ValueError(f"Processing failed: {str(e)}")

    def _process_logic(self, data: str) -> str:
        """
        Internal method for processing logic.

        Args:
            data: Data to process

        Returns:
            Processed data
        """

        # Your business logic here
        return data.upper()
```

---

### 3. Repository Layer (`src/repositories/`)

**Responsibility**: Handle database access

**Responsibilities**:

- ✅ Implement custom database queries
- ✅ Provide data access patterns
- ✅ Handle complex filtering and sorting
- ✅ Optimize database queries
- ✅ Return model instances

**What NOT to do**:

- ❌ Business logic
- ❌ Data validation
- ❌ External API calls
- ❌ HTTP operations

**Example Repository Structure**:

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List
from uuid import UUID
from src.models import MyModel

class MyRepository:
    """Repository for MyModel queries"""

    @staticmethod
    async def find_by_user(
        db: AsyncSession,
        user_id: UUID
    ) -> List[MyModel]:
        """
        Find all records for a specific user.

        Args:
            db: Async database session
            user_id: UUID of the user

        Returns:
            List of MyModel instances
        """

        query = select(MyModel).where(MyModel.user_id == user_id)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_id_and_user(
        db: AsyncSession,
        record_id: UUID,
        user_id: UUID
    ) -> Optional[MyModel]:
        """
        Find a specific record by ID and user.

        Args:
            db: Async database session
            record_id: UUID of the record
            user_id: UUID of the user

        Returns:
            MyModel instance or None
        """

        query = select(MyModel).where(
            (MyModel.id == record_id) & (MyModel.user_id == user_id)
        )
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def count_by_user(
        db: AsyncSession,
        user_id: UUID
    ) -> int:
        """
        Count records for a specific user.

        Args:
            db: Async database session
            user_id: UUID of the user

        Returns:
            Number of records
        """

        query = select(func.count(MyModel.id)).where(MyModel.user_id == user_id)
        result = await db.execute(query)
        return result.scalar()
```

---

## Data Flow Example

### Story Generation Flow

```
1. HTTP Request arrives at /api/create-story
   ├─ Endpoint validates file type
   ├─ Endpoint reads file content
   └─ Endpoint calls StoryService.create_story()

2. StoryService.create_story()
   ├─ Validates image format
   ├─ Validates language parameter
   ├─ Calls generate_story() to create story
   ├─ Calls Story.create() to save to database
   └─ Returns {story_id, title, story, generation_time}

3. Story.create() (Model CRUD method)
   ├─ Inserts record into database
   ├─ Returns Story instance with ID
   └─ Triggers @auditable decorator (created_at, updated_at)

4. Endpoint receives result
   ├─ Formats as StoryResponse
   └─ Returns HTTP 200 with response

5. HTTP Response sent to client
```

---

## How to Add a New Feature

### Step 1: Create the Model (if needed)

**File**: `src/models/my_feature.py`

```python
from sqlalchemy import Column, String, Text, Integer
from sqlalchemy.dialects.postgresql import UUID
import uuid
from src.database.db import Base
from src.utils import auditable, crud_enabled

@crud_enabled
@auditable
class MyFeature(Base):
    """MyFeature model"""

    __tablename__ = "my_features"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)

    def __repr__(self):
        return f"<MyFeature(id={self.id}, name={self.name})>"
```

### Step 2: Create the Repository (if needed)

**File**: `src/repositories/my_feature_repository.py`

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List
from uuid import UUID
from src.models import MyFeature

class MyFeatureRepository:
    """Repository for MyFeature queries"""

    @staticmethod
    async def find_by_name(
        db: AsyncSession,
        name: str
    ) -> Optional[MyFeature]:
        """Find feature by name"""
        query = select(MyFeature).where(MyFeature.name == name)
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def find_all_by_user(
        db: AsyncSession,
        user_id: UUID
    ) -> List[MyFeature]:
        """Find all features for a user"""
        query = select(MyFeature).where(MyFeature.user_id == user_id)
        result = await db.execute(query)
        return result.scalars().all()
```

### Step 3: Create the Service

**File**: `src/services/my_feature_service.py`

```python
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Dict, Any
from src.repositories import MyFeatureRepository
from src.models import MyFeature

logger = logging.getLogger(__name__)

class MyFeatureService:
    """Service for my feature operations"""

    def __init__(self):
        logger.info("Initializing MyFeatureService...")
        # Initialize any required dependencies
        logger.info("MyFeatureService initialized successfully")

    async def create_feature(
        self,
        db: AsyncSession,
        name: str,
        description: str,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Create a new feature.

        Raises:
            ValueError: If validation fails
        """
        try:
            # Validate inputs
            if not name or len(name) < 3:
                raise ValueError("Name must be at least 3 characters")

            logger.info(f"Creating feature: {name}")

            # Save to database
            feature = await MyFeature.create(
                db,
                user_id=user_id,
                name=name,
                description=description,
            )

            logger.info(f"Feature created: {feature.id}")

            return {
                "feature_id": str(feature.id),
                "name": feature.name,
                "description": feature.description,
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to create feature: {str(e)}")
            raise ValueError(f"Failed to create feature: {str(e)}")

    async def get_feature(
        self,
        db: AsyncSession,
        feature_id: UUID,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Get a specific feature.

        Raises:
            ValueError: If feature not found
        """
        try:
            feature = await MyFeature.get_by_id(db, feature_id)

            if not feature or feature.user_id != user_id:
                raise ValueError("Feature not found")

            return {
                "feature_id": str(feature.id),
                "name": feature.name,
                "description": feature.description,
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to get feature: {str(e)}")
            raise ValueError(f"Failed to get feature: {str(e)}")
```

### Step 4: Create the Endpoint

**File**: `src/endpoints/my_feature.py`

```python
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.schemas import MyFeatureRequest, MyFeatureResponse
from src.services.my_feature_service import MyFeatureService
from src.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api", tags=["my-feature"])

@router.post("/create-feature", response_model=MyFeatureResponse)
async def create_feature(
    request: MyFeatureRequest,
    db: AsyncSession = Depends(get_db)
):
    """Create a new feature"""

    try:
        # Initialize service
        my_feature_service = MyFeatureService()

        if not my_feature_service:
            raise HTTPException(
                status_code=503,
                detail="Feature service not available.",
            )

        result = await my_feature_service.create_feature(
            db=db,
            name=request.name,
            description=request.description,
            user_id=UUID(request.user_id),
        )

        return MyFeatureResponse(
            success="true",
            feature_id=result["feature_id"],
            name=result["name"],
            description=result["description"],
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create feature: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create feature: {str(e)}"
        )

@router.get("/feature/{feature_id}", response_model=MyFeatureResponse)
async def get_feature(
    feature_id: str,
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get a specific feature"""

    try:
        if not my_feature_service:
            raise HTTPException(
                status_code=503,
                detail="Feature service not available.",
            )

        result = await my_feature_service.get_feature(
            db=db,
            feature_id=UUID(feature_id),
            user_id=UUID(user_id),
        )

        return MyFeatureResponse(
            success="true",
            feature_id=result["feature_id"],
            name=result["name"],
            description=result["description"],
        )

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get feature: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get feature: {str(e)}"
        )
```

### Step 5: Create Request/Response Schemas

**File**: `src/schemas/my_feature.py`

```python
from pydantic import BaseModel
from typing import Optional

class MyFeatureRequest(BaseModel):
    """Request schema for creating a feature"""

    user_id: str
    name: str
    description: Optional[str] = None

class MyFeatureResponse(BaseModel):
    """Response schema for feature operations"""

    success: str
    feature_id: str
    name: str
    description: Optional[str] = None
```

### Step 6: Register the Endpoint

**File**: `src/endpoints/__init__.py`

```python
from . import health, tutorial, story, image, my_feature

__all__ = ["health", "tutorial", "story", "image", "my_feature"]
```

**File**: `src/main.py`

```python
from src.endpoints import health, tutorial, image, story, my_feature

app.include_router(health.router)
app.include_router(tutorial.router)
app.include_router(story.router)
app.include_router(image.router)
app.include_router(my_feature.router)
```

---

## Key Principles

### 1. **Single Responsibility**

Each layer has one job:

- Endpoints: HTTP communication
- Services: Business logic
- Repositories: Database access

### 2. **Error Handling**

- Services raise `ValueError` for validation errors
- Endpoints catch `ValueError` and return 400
- Endpoints catch other exceptions and return 500

### 3. **Async/Await**

All database operations are async:

```python
# ✅ Correct
result = await MyModel.create(db, ...)
result = await repository.find_by_id(db, id)

# ❌ Wrong
result = MyModel.create(db, ...)  # Missing await
```

### 4. **Logging**

Use logging at service layer:

```python
logger.info("Starting process...")
logger.error("Process failed: {error}")
```

### 5. **Type Hints**

Always use type hints:

```python
# ✅ Correct
async def process(db: AsyncSession, user_id: UUID) -> Dict[str, Any]:
    pass

# ❌ Wrong
async def process(db, user_id):
    pass
```

### 6. **Documentation**

Document all public methods:

```python
def my_method(param: str) -> bool:
    """
    Brief description.

    Args:
        param: Description of param

    Returns:
        Description of return value

    Raises:
        ValueError: When validation fails
    """
    pass
```

---

## Testing the Flow

### 1. Test Service in Isolation

```python
# Test service without HTTP layer
service = MyFeatureService()
result = await service.create_feature(db, "test", "description", user_id)
assert result["feature_id"] is not None
```

### 2. Test Endpoint with Mock Service

```python
# Test endpoint with mocked service
client = TestClient(app)
response = client.post("/api/create-feature", json={...})
assert response.status_code == 200
```

### 3. Integration Test

```python
# Test full flow with real database
response = client.post("/api/create-feature", json={...})
assert response.status_code == 200
# Verify data in database
```

---

## Summary

| Layer          | Responsibility  | Example                                           |
| -------------- | --------------- | ------------------------------------------------- |
| **Endpoint**   | HTTP handling   | Validate file type, call service, return response |
| **Service**    | Business logic  | Validate data, process, coordinate operations     |
| **Repository** | Database access | Custom queries, data access patterns              |

Follow this structure for all new features to maintain consistency and scalability!
