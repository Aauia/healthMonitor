from sqlalchemy import (
    Column, Integer, String, DateTime, Float,
    Text, ForeignKey, Boolean, Date, Time, Enum,
    UniqueConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from src.database import Base


# ─────────────────────────────────────────
#  ENUM
# ─────────────────────────────────────────

class SupplementType(str, enum.Enum):
    vitamin    = "vitamin"
    medication = "medication"
    supplement = "supplement"


# ─────────────────────────────────────────
#  USER
# ─────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String, unique=True, index=True, nullable=False)
    password        = Column(String, nullable=False)
    full_name       = Column(String, nullable=False)
    profile_picture = Column(Text, nullable=True)
    role            = Column(String, default="user")
    
    # Goals and preferences
    steps_goal            = Column(Integer, default=10000)
    sleep_goal_hours      = Column(Float,   default=8.0)
    notifications_enabled = Column(Boolean, default=True)

    created_at      = Column(DateTime(timezone=True), server_default=func.now())

    sleep_sessions  = relationship("SleepSession",   back_populates="user", cascade="all, delete")
    supplements     = relationship("Supplement",     back_populates="user", cascade="all, delete")
    activity_logs   = relationship("ActivityLog",    back_populates="user", cascade="all, delete")
    recommendations = relationship("Recommendation", back_populates="user", cascade="all, delete")
    # FIX: добавлена прямая связь для быстрых запросов логов без двойного JOIN
    supplement_logs = relationship("SupplementLog",  back_populates="user", cascade="all, delete")


# ─────────────────────────────────────────
#  SLEEP SESSIONS
# ─────────────────────────────────────────

class SleepSession(Base):
    __tablename__ = "sleep_sessions"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False)

    sleep_date   = Column(Date, nullable=False)
    bedtime      = Column(Time, nullable=False)
    wake_time    = Column(Time, nullable=False)
    duration_min = Column(Integer, nullable=True)   # вычисляется на бэке при сохранении
    wake_ups     = Column(Integer, nullable=True)
    hrv_score    = Column(Integer, nullable=True)
    notes        = Column(Text, nullable=True)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="sleep_sessions")

    # FIX: одна запись на ночь — дубли невозможны
    __table_args__ = (
        UniqueConstraint("user_id", "sleep_date", name="uq_sleep_user_date"),
    )


# ─────────────────────────────────────────
#  SUPPLEMENTS
# ─────────────────────────────────────────
class Supplement(Base):
    __tablename__ = "supplements"

    id            = Column(Integer, primary_key=True, index=True)
    user_id       = Column(Integer, ForeignKey("users.id"), nullable=False)
    name          = Column(String, nullable=False)
    type          = Column(Enum(SupplementType), nullable=False)
    dosage        = Column(String, nullable=True)
    
    # Новые поля:
    instructions   = Column(Text, nullable=True) # Как принимать
    # Храним времена как строку "08:00,20:00" для простоты или JSON
    reminder_times = Column(String, nullable=True) 

    start_date    = Column(Date, nullable=False)
    end_date      = Column(Date, nullable=False)
    is_active     = Column(Boolean, default=True)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())
    
    # Связи остаются те же
    user     = relationship("User", back_populates="supplements")
    schedule = relationship("SupplementSchedule", back_populates="supplement", cascade="all, delete")
    logs     = relationship("SupplementLog", back_populates="supplement", cascade="all, delete")


# ─────────────────────────────────────────
#  SUPPLEMENT SCHEDULE (дни недели 1–7)
# ─────────────────────────────────────────

class SupplementSchedule(Base):
    __tablename__ = "supplement_schedule"

    id            = Column(Integer, primary_key=True, index=True)
    supplement_id = Column(Integer, ForeignKey("supplements.id"), nullable=False)
    day_of_week   = Column(Integer, nullable=False)  # 1=пн … 7=вс

    supplement = relationship("Supplement", back_populates="schedule")

    # один день = одна запись на суплемент
    __table_args__ = (
        UniqueConstraint("supplement_id", "day_of_week", name="uq_schedule_supplement_day"),
    )


# ─────────────────────────────────────────
#  SUPPLEMENT LOGS
# ─────────────────────────────────────────

class SupplementLog(Base):
    __tablename__ = "supplement_logs"

    id            = Column(Integer, primary_key=True, index=True)
    supplement_id = Column(Integer, ForeignKey("supplements.id"), nullable=False)
    user_id       = Column(Integer, ForeignKey("users.id"), nullable=False)

    log_date  = Column(Date, nullable=False)
    # Удаляем уникальность только по дате, добавляем время или порядковый номер приема
    planned_time = Column(Time, nullable=True) # Чтобы отличить утренний прием от вечернего
    
    taken     = Column(Boolean, default=False)
    taken_at  = Column(DateTime(timezone=True), nullable=True)
    note      = Column(Text, nullable=True)

    # Уникальность теперь: (лекарство + дата + запланированное время)
    __table_args__ = (
        UniqueConstraint("supplement_id", "log_date", "planned_time", name="uq_log_time"),
    )

    user = relationship("User", back_populates="supplement_logs")
    supplement = relationship("Supplement", back_populates="logs")


# ─────────────────────────────────────────
#  ACTIVITY LOGS
# ─────────────────────────────────────────

class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id               = Column(Integer, primary_key=True, index=True)
    user_id          = Column(Integer, ForeignKey("users.id"), nullable=False)

    log_date         = Column(Date, nullable=False)
    steps            = Column(Integer, default=0)
    active_minutes   = Column(Integer, nullable=True)
    calories_burned  = Column(Integer, nullable=True)
    distance_meters  = Column(Float, nullable=True)
    synced_at        = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="activity_logs")

    __table_args__ = (
        UniqueConstraint("user_id", "log_date", name="uq_activity_user_date"),
    )


# ─────────────────────────────────────────
#  RECOMMENDATIONS
# ─────────────────────────────────────────

class Recommendation(Base):
    __tablename__ = "recommendations"

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id"), nullable=False)

    category       = Column(String, nullable=True)      # 'sleep' | 'activity' | 'supplement'
    message        = Column(Text, nullable=False)
    trigger_metric = Column(String, nullable=True)      # 'duration_min' | 'wake_ups' | 'steps'
    trigger_value  = Column(Float, nullable=True)
    is_read        = Column(Boolean, default=False)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="recommendations")