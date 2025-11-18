# 🏷️ Nova Draw AI - Decorators Guide

Simple, powerful decorators to enhance your SQLAlchemy models without complexity.

## 📋 Available Decorators

### 🕒 **Timestamp Decorators**

#### `@timestamped`

Adds basic timestamp tracking.

```python
@timestamped
class Invoice(Base):
    # Gets: created_at, updated_at
    pass

# Usage:
invoice = await Invoice.create(db, amount=100)
print(invoice.created_at)  # 2024-01-15 10:30:00
print(invoice.updated_at)  # 2024-01-15 10:30:00
```

#### `@auto_updated`

Enhanced timestamps with automatic updates.

```python
@auto_updated
class MarginSetting(Base):
    # Gets: created_at, updated_at (auto-updates on ANY change)
    pass
```

#### `@creation_tracked`

Only tracks creation time (for immutable records).

```python
@creation_tracked
class AuditLog(Base):
    # Gets: created_at (only)
    pass
```

---

#### `@auditable`

Audit trail with timestamps (created_at, updated_at).

```python
@auditable
class User(Base):
    # Gets: created_at, updated_at
    pass

# RECOMMENDED for most business models
```

---

### 💾 **CRUD Operations Decorator**

#### `@crud_enabled`

Automatic CRUD operations for any model.

```python
@crud_enabled
@auditable
class Transaction(Base):
    __tablename__ = "transactions"
    # Your fields here

# Gets 8 automatic async methods:
user = await User.create(db, email="test@test.com")              # Create
user = await User.get_by_id(db, user_id)                        # Read by ID
users = await User.get_all(db)                                  # Read all
paginated = await User.get_paginated(db, page=1, limit=10)     # Paginated
updated = await User.update(db, user_id, {"email": "new@test"}) # Update
success = await User.delete(db, user_id)                        # Delete (hard delete)
count = await User.count(db)                                    # Count
exists = await User.exists(db, user_id)                         # Exists check
```

**Features:**

- ✅ Hard delete (permanent removal from database)
- ✅ Auto-updates timestamps
- ✅ Built-in pagination
- ✅ Works with all other decorators
- ✅ Async-compatible for FastAPI

---

## 🎯 Decorator Combinations

### **Recommended Combinations:**

```python
# Most business models (audit trail with timestamps)
@crud_enabled
@auditable
class User(Base):
    pass

# Configuration models (frequently updated)
@crud_enabled
@auto_updated
class Settings(Base):
    pass

# Log/Event models (immutable, creation time only)
@crud_enabled
@creation_tracked
class EventLog(Base):
    pass

# Simple models (basic timestamp tracking)
@crud_enabled
@timestamped
class SimpleModel(Base):
    pass
```

---

## 🚀 Quick Start Examples

### **User Management:**

```python
@crud_enabled
@auditable
class User(Base):
    __tablename__ = "users"

    id = Column(UUID, primary_key=True)
    email = Column(String)
    # Gets: created_at, updated_at + 8 CRUD methods

# Usage:
user = await User.create(db, email="john@example.com")
user = await User.get_by_id(db, user_id)
await User.delete(db, user_id)  # Hard delete (permanent)
```

### **Drawing Management:**

```python
@crud_enabled
@auditable
class Drawing(Base):
    __tablename__ = "drawings"

    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"))
    uploaded_image_url = Column(String)

# Usage:
drawing = await Drawing.create(db, user_id=user_id, uploaded_image_url=url)
drawings = await Drawing.get_paginated(db, page=1, limit=10)
await Drawing.update(db, drawing_id, {"uploaded_image_url": new_url})
```

### **Story Generation:**

```python
@crud_enabled
@auditable
class Story(Base):
    __tablename__ = "stories"

    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"))
    title = Column(String)
    story_text_en = Column(String)
    story_text_de = Column(String)

# Usage:
story = await Story.create(
    db,
    user_id=user_id,
    title="My Adventure",
    story_text_en="Once upon a time...",
    story_text_de="Es war einmal..."
)
stories = await Story.get_all(db)
```

---

## 💡 Best Practices

### ✅ **Do:**

- Use `@crud_enabled` on ALL models (eliminates 90% of boilerplate)
- Use `@auditable` for business-critical data (timestamps only)
- Stack decorators for combined functionality
- Use repositories for complex queries
- Always use async/await with decorator methods
- Use hard delete (permanent removal) for all data

### ❌ **Don't:**

- Mix multiple timestamp decorators on same model
- Use `@auditable` on high-volume log tables (use `@creation_tracked`)
- Forget to await async methods
- Create CRUD methods manually when `@crud_enabled` exists
- Bypass decorators for basic operations
- Attempt to use soft delete (not supported)

---

## 📖 Repository Pattern

For queries beyond basic CRUD, use the repository pattern:

```python
# Basic CRUD (use decorators)
user = await User.get_by_id(db, user_id)

# Complex queries (use repositories)
user = await UserRepository.find_by_email(db, email)
users = await UserRepository.get_active_users(db)
```

Available repositories:

- `UserRepository` - User-specific queries
- `TutorialRepository` - Tutorial-specific queries
- `DrawingRepository` - Drawing-specific queries
- `StoryRepository` - Story-specific queries

---

## 🔧 Environment Setup

### **For Encryption (Optional):**

```bash
# .env file
ENCRYPTION_KEY=your-base64-encryption-key
# or
APP_SECRET=your-app-secret-for-key-derivation
```

### **Database Connection:**

```python
# Already configured in src/database/db.py
from database import get_db
```

---

## 📝 Async Usage in FastAPI

All decorator methods are async and work seamlessly with FastAPI:

```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models import User

router = APIRouter()

@router.post("/users/")
async def create_user(
    email: str,
    password: str,
    db: AsyncSession = Depends(get_db)
):
    # Using decorator CRUD method
    user = await User.create(db, email=email, password=password)
    return user

@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    # Using decorator CRUD method
    user = await User.get_by_id(db, user_id)
    return user

@router.get("/users/")
async def list_users(
    page: int = 1,
    limit: int = 10,
    db: AsyncSession = Depends(get_db)
):
    # Using decorator pagination
    result = await User.get_paginated(db, page=page, limit=limit)
    return result
```

---

## 🎉 Summary

**These decorators give you:**

- 🚀 **90% less boilerplate code**
- 🛡️ **Automatic audit trails (timestamps)**
- 💾 **Hard delete (permanent removal)**
- ⚡ **Fast development**
- 🔧 **Simple maintenance**
- 🔄 **Async-first design**

**Perfect for building scalable, maintainable FastAPI applications!**
