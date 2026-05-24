from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL=os.getenv("DB_URL")

print(DATABASE_URL)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

try:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
        print("Kết nối thành công")

except Exception as e:
    print(e)