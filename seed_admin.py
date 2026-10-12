"""
Seed script to create initial admin user.
Run: python seed_admin.py
"""
from backend.database import SessionLocal, User
from backend.auth import get_password_hash

def create_admin_user():
    db = SessionLocal()
    try:
        # Check if admin already exists
        existing = db.query(User).filter(User.username == "admin").first()
        if existing:
            print("Admin user already exists")
            return
        
        # Create admin user
        admin = User(
            username="admin",
            hashed_password=get_password_hash("admin123"),  # Change this in production!
            role="admin",
            is_active=True
        )
        db.add(admin)
        db.commit()
        print("Admin user created successfully")
        print("Username: admin")
        print("Password: admin123")
        print("IMPORTANT: Change the password in production!")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin_user()
