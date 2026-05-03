from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional, List
from datetime import datetime, date, time
from enum import Enum


# ═════════════════════════════════════════
#  AUTH
# ═════════════════════════════════════════

class UserRegister(BaseModel):
    email:     EmailStr
    password:  str
    full_name: str
    role:      Optional[str] = "user"

class UserLogin(BaseModel):
    email:    EmailStr
    password: str

class UserOut(BaseModel):
    id:              int
    email:           str
    full_name:       str
    profile_picture: Optional[str] = None
    role:            str
    steps_goal:      int
    sleep_goal_hours: float
    notifications_enabled: bool
    created_at:      datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    full_name:             Optional[str] = None
    profile_picture:       Optional[str] = None
    steps_goal:            Optional[int] = None
    sleep_goal_hours:      Optional[float] = None
    notifications_enabled: Optional[bool] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         UserOut

class UserList(BaseModel):
    users: List[UserOut]


# ═════════════════════════════════════════
#  ENUMS
# ═════════════════════════════════════════

class SupplementTypeEnum(str, Enum):
    vitamin    = "vitamin"
    medication = "medication"
    supplement = "supplement"


# ═════════════════════════════════════════
#  SLEEP SESSIONS
# ═════════════════════════════════════════

class SleepSessionCreate(BaseModel):
    sleep_date:   date
    bedtime:      time
    wake_time:    time
    duration_min: Optional[int] = None   # если None — бэк вычислит из bedtime/wake_time
    wake_ups:     Optional[int] = None
    hrv_score:    Optional[int] = None
    notes:        Optional[str] = None

class SleepSessionOut(SleepSessionCreate):
    id:         int
    user_id:    int
    created_at: datetime

    class Config:
        from_attributes = True

# FIX: добавлена схема статистики для GET /sleep/stats
class SleepStatsOut(BaseModel):
    period_days:      int           # за сколько дней считаем (обычно 7)
    total_sessions:   int           # сколько записей за период
    avg_duration_min: float         # средняя длина сна в минутах
    avg_duration_h:   float         # то же в часах (удобно для UI)
    avg_wake_ups:     float         # среднее пробуждений
    avg_hrv_score:    Optional[float] = None


# ═════════════════════════════════════════
#  SUPPLEMENT SCHEDULE
# ═════════════════════════════════════════

class SupplementScheduleOut(BaseModel):
    id:          int
    day_of_week: int  # 1–7

    class Config:
        from_attributes = True


# ═════════════════════════════════════════
#  SUPPLEMENTS
# ═════════════════════════════════════════

class SupplementCreate(BaseModel):
    name:          str
    type:          SupplementTypeEnum
    dosage:        Optional[str]  = None
    reminder_time: Optional[time] = None
    instructions:   Optional[str] = None # Инструкции
    reminder_times: List[time]
    days_of_week:  List[int]               # 1–7
    start_date:    date
    end_date:      date
    is_active:     bool = True

    # FIX: валидация дней недели — только 1..7
    @field_validator("days_of_week")
    @classmethod
    def validate_days(cls, v: List[int]) -> List[int]:
        if not v:
            raise ValueError("Нужно выбрать хотя бы один день")
        for d in v:
            if d < 1 or d > 7:
                raise ValueError(f"День недели должен быть от 1 до 7, получен: {d}")
        return sorted(set(v))  # убираем дубли и сортируем

    @field_validator("end_date")
    @classmethod
    def validate_dates(cls, end: date, info) -> date:
        start = info.data.get("start_date")
        if start and end < start:
            raise ValueError("end_date не может быть раньше start_date")
        return end

class SupplementOut(BaseModel):
    id:            int
    user_id:       int
    name:          str
    type:          SupplementTypeEnum
    dosage:        Optional[str]  = None
    reminder_time: Optional[time] = None
    reminder_times: Optional[str] = None
    start_date:    date
    end_date:      date
    is_active:     bool
    created_at:    datetime
    schedule:      List[SupplementScheduleOut] = []
    is_taken_today: bool = False
    taken_times_today: List[str] = []
    progress_percent: float = 0.0

    class Config:
        from_attributes = True


# ═════════════════════════════════════════
#  SUPPLEMENT LOGS
# ═════════════════════════════════════════

class SupplementLogCreate(BaseModel):
    log_date: date
    planned_time: str
    taken:    bool = False
    note:     Optional[str] = None

class SupplementLogOut(BaseModel):
    id:            int
    supplement_id: int
    log_date:      date
    taken:         bool
    taken_at:      Optional[datetime] = None
    note:          Optional[str]      = None

    class Config:
        from_attributes = True

# Прогресс-бар курса
# progress_percent = taken_days / total_days_in_course * 100
class SupplementProgress(BaseModel):
    supplement_id:    int
    name:             str
    type:             SupplementTypeEnum
    dosage:           Optional[str] = None
    start_date:       date
    end_date:         date
    total_days:       int      # всего дней в курсе
    taken_days:       int      # сколько дней принял
    missed_days:      int      # total_days - taken_days
    progress_percent: float    # taken_days / total_days * 100


# ═════════════════════════════════════════
#  ACTIVITY LOGS
# ═════════════════════════════════════════

class ActivityLogCreate(BaseModel):
    log_date:         date
    steps:            int = 0
    active_minutes:   Optional[int]   = None
    calories_burned:  Optional[int]   = None
    distance_meters:  Optional[float] = None

class ActivityLogOut(ActivityLogCreate):
    id:        int
    user_id:   int
    synced_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# FIX: bulk синхронизация — iOS отправляет сразу 7 дней одним запросом
class ActivitySyncRequest(BaseModel):
    logs: List[ActivityLogCreate]

    @field_validator("logs")
    @classmethod
    def validate_logs(cls, v: List[ActivityLogCreate]) -> List[ActivityLogCreate]:
        if not v:
            raise ValueError("Список логов не может быть пустым")
        if len(v) > 31:
            raise ValueError("Максимум 31 день за один запрос")
        return v


# ═════════════════════════════════════════
#  RECOMMENDATIONS
# ═════════════════════════════════════════

class RecommendationOut(BaseModel):
    id:             int
    user_id:        int
    category:       Optional[str]   = None
    message:        str
    trigger_metric: Optional[str]   = None
    trigger_value:  Optional[float] = None
    is_read:        bool
    created_at:     datetime

    @model_validator(mode="after")
    def sync_frontend_fields(self) -> "RecommendationOut":
        if self.type is None:
            self.type = self.category
        if self.content is None:
            self.content = self.message
        return self

    class Config:
        from_attributes = True

class RecommendationMarkRead(BaseModel):
    is_read: bool = True


# ═════════════════════════════════════════
#  DASHBOARD  (один endpoint — весь главный экран)
# FIX: новая схема — iOS получает всё за один запрос
# ═════════════════════════════════════════

class DashboardOut(BaseModel):
    # Сон
    sleep_avg_duration_h:  Optional[float] = None   # средний сон за 7 дней в часах
    sleep_avg_wake_ups:    Optional[float] = None   # среднее пробуждений
    sleep_sessions_count:  int = 0                  # записей за последние 7 дней

    # Активность
    steps_today:           int = 0                  # шаги сегодня
    steps_avg_7d:          float = 0.0              # средние шаги за 7 дней

    # Суплементы
    active_supplements:    int = 0                  # сколько активных курсов
    supplements_taken_today: int = 0                # сколько уже приняли сегодня
    supplements_total_today: int = 0                # сколько нужно принять сегодня

    # Рекомендации
    latest_recommendation: Optional[RecommendationOut] = None