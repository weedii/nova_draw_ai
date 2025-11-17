# NovaDraw AI Database

Async PostgreSQL database setup using SQLAlchemy ORM with Neon and Alembic migrations.

## Architecture

```
backend/
├── core/
│   └── config.py        # Settings loaded from environment
├── database/
│   ├── db.py            # Async engine, session factory, dependencies
│   ├── __init__.py      # Package exports
│   └── README.md        # This file
├── models/
│   ├── base.py          # Declarative base for all ORM models
│   ├── __init__.py      # Model exports
│   ├── user.py          # User model
│   ├── tutorial.py      # Tutorial model
│   ├── tutorial_step.py # Tutorial steps model
│   ├── drawing.py       # User drawings model
│   └── story.py         # AI-generated stories model
├── alembic/
│   ├── env.py           # Alembic configuration (handles migrations)
│   ├── script.py.mako   # Migration template
│   └── versions/        # Migration files (auto-generated)
└── main.py              # FastAPI application
```

## Database Setup

### 1. Create Neon PostgreSQL Database

1. Go to [Neon Console](https://console.neon.tech)
2. Create a new project
3. Create a database (e.g., `novadraw_ai`)
4. Copy the connection string with `sslmode=require`

### 2. Configure Environment Variables

Create or update `.env` in the project root:

```env
# Neon PostgreSQL Connection
# Format: postgresql+asyncpg://user:password@host/dbname?sslmode=require
DATABASE_URL="postgresql+asyncpg://user:password@ep-cool-name.neon.tech/neondb?sslmode=require"

# Server Configuration
HOST="0.0.0.0"
PORT="8000"

# API Keys (optional)
OPENAI_API_KEY=""
GOOGLE_API_KEY=""
```

### 3. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 4. Run Database Migrations

```bash
cd backend
alembic upgrade head
```

This creates all tables defined in the ORM models.

## Database Models

### User

- **Purpose**: User accounts with authentication
- **Fields**: id (UUID), email, password, name, birthdate, created_at, updated_at
- **Relationships**: drawings, stories

### Tutorial

- **Purpose**: Drawing tutorial metadata
- **Fields**: id (UUID), category, subject, total_steps, thumbnail_url, description_en, description_de, created_at, updated_at
- **Relationships**: steps, drawings

### TutorialStep

- **Purpose**: Individual steps within a tutorial
- **Fields**: id (UUID), tutorial_id, step_number, instruction_en, instruction_de, image_url, created_at, updated_at
- **Relationships**: tutorial

### Drawing

- **Purpose**: User-created drawings (uploaded and edited)
- **Fields**: id (UUID), user_id, tutorial_id, uploaded_image_url, edited_images_urls (array), created_at, updated_at
- **Relationships**: user, tutorial, stories

### Story

- **Purpose**: AI-generated stories from drawings
- **Fields**: id (UUID), user_id, title, story_text_en, story_text_de, image_url, drawing_id, is_favorite, generation_time_ms, created_at, updated_at
- **Relationships**: user, drawing

## Using Database in FastAPI

### Async Session Dependency

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
from models import User

@app.get("/users/{user_id}")
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    """Get user by ID"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    return user
```

### Creating Records

```python
@app.post("/users")
async def create_user(email: str, password: str, db: AsyncSession = Depends(get_db)):
    """Create a new user"""
    user = User(email=email, password=password)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
```

### Querying with Relationships

```python
@app.get("/users/{user_id}/drawings")
async def get_user_drawings(user_id: str, db: AsyncSession = Depends(get_db)):
    """Get all drawings for a user"""
    result = await db.execute(
        select(Drawing).where(Drawing.user_id == user_id)
    )
    drawings = result.scalars().all()
    return drawings
```

## Database Migrations with Alembic

### Generate a Migration

When you modify ORM models, generate a migration:

```bash
cd backend
alembic revision --autogenerate -m "add user email index"
```

This creates a new migration file in `alembic/versions/`.

### Review and Apply Migrations

1. Review the generated migration file
2. Apply it to the database:

```bash
alembic upgrade head
```

### Rollback a Migration

```bash
# Rollback one migration
alembic downgrade -1

# Rollback to a specific revision
alembic downgrade <revision_id>
```

### View Migration History

```bash
alembic history
```

## Running with Docker

The `docker-compose.yml` automatically loads `.env` and passes `DATABASE_URL` to the container:

```bash
docker-compose up
```

The backend container connects to Neon PostgreSQL (no local database needed).

## Development Tips

### Enable SQL Query Logging

In `database/db.py`, set `echo=True` to log all SQL queries:

```python
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    echo=True,  # Set to True for debugging
)
```

### Reset Database (Development Only)

```python
# In a script or Python shell
from database import cleanup_db, init_db
import asyncio

async def reset():
    await cleanup_db()
    await init_db()

asyncio.run(reset())
```

### Test Database Connection

```bash
cd backend
python -c "from core.config import settings; print(settings.DATABASE_URL)"
```

## Troubleshooting

### Connection Refused

- Verify `DATABASE_URL` is correct
- Check Neon project is active
- Ensure `sslmode=require` is in the connection string

### Migration Conflicts

- Check `alembic/versions/` for conflicting migrations
- Use `alembic history` to view the migration chain

### Async Errors

- Ensure all database operations use `await`
- Use `AsyncSession` from `sqlalchemy.ext.asyncio`
- Don't mix sync and async database code
