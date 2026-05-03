import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL").replace("postgresql+asyncpg://", "postgresql://")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

from src import models, schemas

# user id 1
supplements = db.query(models.Supplement).filter(models.Supplement.user_id == 1).all()
for s in supplements:
    out = schemas.SupplementOut.model_validate(s)
    print(out.model_dump_json(indent=2))

