"""
Database initialization script
Run this to create all tables in the database
"""
from database import init_db
from database.models import User, Tutorial, TutorialStep, Drawing, Story

if __name__ == "__main__":
    print("Creating database tables...")
    init_db()
    print("✓ Database tables created successfully!")
    print("\nTables created:")
    print("  - users")
    print("  - tutorials")
    print("  - tutorial_steps")
    print("  - drawings")
    print("  - stories")
