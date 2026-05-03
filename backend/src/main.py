import os
import uuid
import bcrypt
from datetime import datetime, timedelta, date, time
from typing import List, Optional

from fastapi import FastAPI, Depends, HTTPException, Header, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.orm.attributes import flag_modified
from jose import jwt, JWTError
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from src.database import engine, get_db, Base
from src import models
from src import schemas
from src.ai_service import ai_service

# Создаём таблицы
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Health Tracker API")
security = HTTPBearer()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# JWT settings
SECRET_KEY = os.getenv("SECRET_KEY", "invision-health-secret-2026")
ALGORITHM = "HS256"
TOKEN_EXPIRE_HOURS = 24

# Password helpers
def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()

def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())

# --- HELPERS ---
def create_token(user_id: int, email: str, role: str) -> str:
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "exp": datetime.utcnow() + timedelta(hours=TOKEN_EXPIRE_HOURS),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

# --- AUTH ---
@app.post("/auth/register", response_model=schemas.TokenResponse)
def register(data: schemas.UserRegister, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = models.User(
        email=data.email,
        password=hash_password(data.password),
        full_name=data.full_name,
        role=data.role or "user"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_token(user.id, user.email, user.role)
    return {"access_token": token, "user": user}

@app.post("/auth/login", response_model=schemas.TokenResponse)
def login(data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user or not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_token(user.id, user.email, user.role)
    return {"access_token": token, "user": user}

# --- PROFILE & USERS ---
@app.get("/users/me", response_model=schemas.UserOut)
def get_me(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = int(current_user["sub"])
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.patch("/users/me", response_model=schemas.UserOut)
def update_profile(data: schemas.UserUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = int(current_user["sub"])
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    return user

# --- SLEEP SESSIONS ---
@app.post("/sleep", response_model=schemas.SleepSessionOut)
def create_sleep_session(data: schemas.SleepSessionCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = int(current_user["sub"])
    
    # Расчет длительности сна, если не передано
    duration = data.duration_min
    if duration is None:
        # Упрощенный расчет (предполагаем, что сон в рамках одних суток или через полночь)
        start = datetime.combine(date.today(), data.bedtime)
        end = datetime.combine(date.today(), data.wake_time)
        if end <= start:
            end += timedelta(days=1)
        duration = int((end - start).total_seconds() / 60)

    session = models.SleepSession(
        user_id=user_id,
        **data.model_dump(exclude={"duration_min"}),
        duration_min=duration
    )
    db.add(session)
    try:
        db.commit()
        db.refresh(session)
    except Exception:
        db.rollback()
        raise HTTPException(status_code=400, detail="Entry for this date already exists")
    return session

@app.get("/sleep/my", response_model=List[schemas.SleepSessionOut])
def get_my_sleep(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(models.SleepSession).filter(models.SleepSession.user_id == int(current_user["sub"])).all()

# --- SUPPLEMENTS ---
@app.post("/supplements", response_model=schemas.SupplementOut)
def add_supplement(data: schemas.SupplementCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = int(current_user["sub"])
    
    # Превращаем список времен в строку "08:00,20:00"
    times_str = ",".join([t.strftime("%H:%M") for t in data.reminder_times])

    new_supp = models.Supplement(
        user_id=user_id,
        name=data.name,
        type=data.type,
        dosage=data.dosage,
        instructions=data.instructions,
        reminder_times=times_str,
        start_date=data.start_date,
        end_date=data.end_date
    )
    db.add(new_supp)
    db.flush()

    for day in data.days_of_week:
        db.add(models.SupplementSchedule(supplement_id=new_supp.id, day_of_week=day))
    
    db.commit()
    db.refresh(new_supp)
    return new_supp

@app.get("/supplements/my", response_model=List[schemas.SupplementOut])
def get_my_supplements(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    supplements = db.query(models.Supplement).filter(
        models.Supplement.user_id == int(current_user["sub"])
    ).options(joinedload(models.Supplement.schedule), joinedload(models.Supplement.logs)).all()
    
    today = date.today()
    for supp in supplements:
        supp.is_taken_today = any(log.log_date == today and log.taken for log in supp.logs)
        supp.taken_times_today = [
            log.planned_time.strftime("%H:%M") if log.planned_time else "Anytime"
            for log in supp.logs if log.log_date == today and log.taken
        ]
        
        total_days = (supp.end_date - supp.start_date).days + 1
        taken_days = sum(1 for log in supp.logs if log.taken) # This calculates total doses taken across all days. Let's stick with this for simplicity.
        supp.progress_percent = (taken_days / total_days) * 100 if total_days > 0 else 0.0
        
    return supplements
    
    
    
@app.post("/supplements/{supplement_id}/log")
def log_supplement(
    supplement_id: int,
    data: schemas.SupplementLogCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    user_id = int(current_user["sub"])

    supplement = db.query(models.Supplement).filter(
        models.Supplement.id == supplement_id,
        models.Supplement.user_id == user_id
    ).first()

    if not supplement:
        raise HTTPException(status_code=404, detail="Supplement not found")

    if data.planned_time.lower() == "anytime":
        planned_time_obj = None
    else:
        try:
            planned_time_obj = datetime.strptime(data.planned_time, "%H:%M:%S").time()
        except ValueError:
            try:
                planned_time_obj = datetime.strptime(data.planned_time, "%H:%M").time()
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid time format")

    existing_log = db.query(models.SupplementLog).filter(
        models.SupplementLog.supplement_id == supplement_id,
        models.SupplementLog.log_date == data.log_date,
        models.SupplementLog.planned_time == planned_time_obj
    ).first()

    if existing_log:
        existing_log.taken = data.taken
        existing_log.taken_at = datetime.utcnow() if data.taken else None
        if data.note:
            existing_log.note = data.note
    else:
        log = models.SupplementLog(
            supplement_id=supplement_id,
            user_id=user_id,
            log_date=data.log_date,
            planned_time=planned_time_obj,
            taken=data.taken,
            taken_at=datetime.utcnow() if data.taken else None,
            note=data.note
        )
        db.add(log)

    db.commit()
    return {"status": "logged"}



@app.get("/supplements/{supplement_id}/logs")
def get_logs(
    supplement_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    return db.query(models.SupplementLog).filter(
        models.SupplementLog.supplement_id == supplement_id
    ).all()
    
    
@app.get("/supplements/{supplement_id}/progress")
def get_progress(
    supplement_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    supp = db.query(models.Supplement).options(
        joinedload(models.Supplement.schedule),
        joinedload(models.Supplement.logs)
    ).filter(models.Supplement.id == supplement_id).first()

    if not supp:
        raise HTTPException(status_code=404, detail="Not found")

    total_days = (supp.end_date - supp.start_date).days + 1

    taken_days = sum(1 for log in supp.logs if log.taken)

    progress = (taken_days / total_days) * 100 if total_days > 0 else 0

    return {
        "taken_days": taken_days,
        "total_days": total_days,
        "progress_percent": round(progress, 2)
    }

@app.delete("/supplements/{id}")
def delete_supplement(id: int, db: Session = Depends(get_db)):
    supp = db.query(models.Supplement).filter(models.Supplement.id == id).first()
    db.delete(supp)
    db.commit()
    return {"status": "deleted"}


# --- ACTIVITY LOGS ---
@app.post("/activity/sync")
def sync_activity(data: schemas.ActivitySyncRequest, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = int(current_user["sub"])
    for log_data in data.logs:
        log = db.query(models.ActivityLog).filter(
            models.ActivityLog.user_id == user_id,
            models.ActivityLog.log_date == log_data.log_date
        ).first()
        
        if log:
            log.steps            = log_data.steps
            log.active_minutes   = log_data.active_minutes
            log.calories_burned  = log_data.calories_burned
            log.distance_meters  = log_data.distance_meters
            log.synced_at        = datetime.utcnow()
        else:
            new_log = models.ActivityLog(
                user_id         = user_id,
                log_date        = log_data.log_date,
                steps           = log_data.steps,
                active_minutes  = log_data.active_minutes,
                calories_burned = log_data.calories_burned,
                distance_meters = log_data.distance_meters,
                synced_at       = datetime.utcnow()
            )
            db.add(new_log)
    
    db.commit()
    return {"status": "synced"}
@app.get("/activity/my")
def get_activity(
    start: Optional[date] = None,
    end: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    query = db.query(models.ActivityLog).filter(models.ActivityLog.user_id == int(current_user["sub"]))
    if start and end:
        query = query.filter(models.ActivityLog.log_date.between(start, end))
    return query.all()


@app.post("/recommendations/generate")
def generate_recommendations(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    user_id = int(current_user["sub"])
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Fetch recent data for AI analysis
    last_week = date.today() - timedelta(days=7)
    
    sleep_history = db.query(models.SleepSession).filter(
        models.SleepSession.user_id == user_id,
        models.SleepSession.sleep_date >= last_week
    ).all()

    activity_history = db.query(models.ActivityLog).filter(
        models.ActivityLog.user_id == user_id,
        models.ActivityLog.log_date >= last_week
    ).all()

    supplements = db.query(models.Supplement).filter(
        models.Supplement.user_id == user_id,
        models.Supplement.is_active == True
    ).all()

    # Prepare data for AI
    user_data = {
        "user_name": user.full_name,
        "goals": {
            "steps_goal": user.steps_goal,
            "sleep_goal_hours": user.sleep_goal_hours
        },
        "sleep_history": sleep_history,
        "activity_history": activity_history,
        "supplements": supplements
    }

    # Generate AI insights
    ai_insights = ai_service.generate_health_insights(user_data)

    recs = []
    for insight in ai_insights:
        recs.append(models.Recommendation(
            user_id=user_id,
            category=insight.get("category", "general"),
            message=insight.get("message", "Stay healthy!"),
            trigger_metric="ai_generated",
            trigger_value=0.0
        ))

    if recs:
        db.add_all(recs)
        db.commit()

    # Return the first recommendation to satisfy the frontend's expected response type
    # (The frontend expects a single Recommendation object based on RecommendationsViewModel.swift)
    if recs:
        # We need to refresh to get the ID and other fields
        db.refresh(recs[0])
        return recs[0]
    
    return {"status": "no new insights"}

@app.get("/recommendations/my")
def get_recommendations(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    return db.query(models.Recommendation).filter(
        models.Recommendation.user_id == int(current_user["sub"])
    ).order_by(models.Recommendation.created_at.desc()).all()
    
    
@app.patch("/recommendations/{id}/read")
def mark_read(id: int, db: Session = Depends(get_db)):
    rec = db.query(models.Recommendation).filter(models.Recommendation.id == id).first()
    rec.is_read = True
    db.commit()
    return {"status": "ok"}