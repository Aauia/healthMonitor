import sys
import os
from datetime import date, timedelta, time

# Add backend to path
sys.path.append("/Users/aiaulymabduohapova/Desktop/healthMonitor/backend")

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from src.main import app, get_db
from src.database import Base
from src import models

# Use a temporary in-memory database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_recommendations.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_generate_recommendations():
    db = TestingSessionLocal()
    
    # 1. Create a mock user
    import time as pytime
    unique_email = f"test_{int(pytime.time())}@example.com"
    user = models.User(
        email=unique_email,
        password="hashed_password",
        full_name="John Doe",
        steps_goal=10000,
        sleep_goal_hours=8.0
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # 2. Add some mock data
    # Sleep session (6 hours - below goal)
    sleep = models.SleepSession(
        user_id=user.id,
        sleep_date=date.today() - timedelta(days=1),
        bedtime=time(23, 0),
        wake_time=time(5, 0),
        duration_min=360 # 6 hours
    )
    sleep.duration_min = 360 # 6 hours
    db.add(sleep)
    
    # Activity log (4000 steps - below goal)
    activity = models.ActivityLog(
        user_id=user.id,
        log_date=date.today() - timedelta(days=1),
        steps=4000
    )
    db.add(activity)
    
    db.commit()

    # 3. Mock authentication (since we use JWT)
    # We'll bypass the get_current_user dependency for this test
    from src.main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: {"sub": str(user.id), "email": user.email, "role": "user"}

    print("Requesting recommendation generation...")
    response = client.post("/recommendations/generate")
    
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.json()}")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "category" in data
    
    print("\nRequesting list of recommendations...")
    response = client.get("/recommendations/my")
    print(f"Status Code: {response.status_code}")
    recs = response.json()
    print(f"Number of recommendations: {len(recs)}")
    for r in recs:
        print(f"- [{r.get('category')}] {r.get('message')}")

    db.close()
    # Clean up
    if os.path.exists("./test_recommendations.db"):
        os.remove("./test_recommendations.db")

if __name__ == "__main__":
    test_generate_recommendations()
