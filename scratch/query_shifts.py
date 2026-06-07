import os
import sys
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv("/Users/leducvu/phanmemquanlinhakhoa/Backend/.env")

db_url = os.getenv("DB_URL")
if not db_url:
    print("DB_URL not found")
    sys.exit(1)

engine = create_engine(db_url)
with engine.connect() as conn:
    print("--- WORK SHIFTS ---")
    res = conn.execute(text("SELECT id, shift_code, shift_name, start_time, end_time, status FROM work_shifts"))
    for row in res.mappings():
        print(row)
    
    print("\n--- SAMPLE DOCTOR WORK SCHEDULES ---")
    res = conn.execute(text("SELECT id, doctor_uuid, work_shift_id, work_date, max_patients, current_patients, status FROM doctor_work_schedules LIMIT 5"))
    for row in res.mappings():
        print(row)
