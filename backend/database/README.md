# NovaDraw AI Database

PostgreSQL database setup using SQLAlchemy ORM.

## Structure

```
database/
├── base.py              # Base declarative class
├── session.py           # Database engine and session management
├── __init__.py          # Package exports
└── models/
    ├── __init__.py      # Model exports
    ├── user.py          # User model
    ├── tutorial.py      # Tutorial model
    ├── tutorial_step.py # Tutorial steps model
    ├── drawing.py       # User drawings model
    ├── story.py         # AI-generated stories model
    └── mixins/
        ├── __init__.py
        └── time_mixin.py # Timestamp mixin (created_at, updated_at)
```

## Setup

1. Install PostgreSQL on your system

2. Create the database:
```bash
createdb novadraw_ai
```

3. Configure environment variables in `.env`:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/novadraw_ai
```

4. Install Python dependencies:
```bash
pip install -r requirements.txt
```

5. Initialize the database:
```bash
cd backend
python init_db.py
```

## Models

### User
- Authentication and profile information
- Relationships: drawings, stories

### Tutorial
- Drawing tutorial metadata
- Relationships: steps, drawings

### TutorialStep
- Individual steps for each tutorial
- Relationships: tutorial

### Drawing
- User-uploaded and edited images
- Relationships: user, tutorial, stories

### Story
- AI-generated stories from drawings
- Relationships: user, drawing

## Usage in FastAPI

```python
from database import get_db
from database.models import User
from sqlalchemy.orm import Session

@app.get("/users/{user_id}")
def get_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    return user
```

## Migrations

For database migrations, use Alembic:

```bash
# Initialize Alembic (already done)
alembic init alembic

# Create a migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head
```
