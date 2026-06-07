import os
import sys
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load env variables
load_dotenv("/Users/leducvu/phanmemquanlinhakhoa/Backend/.env")

db_url = os.getenv("DB_URL")
if not db_url:
    print("DB_URL not found in env!")
    sys.exit(1)

print(f"Connecting to database...")
engine = create_engine(db_url)

commands = [
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'unpaid' NOT NULL",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50)",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_time TIMESTAMP WITH TIME ZONE",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS discount_amount FLOAT DEFAULT 0.0 NOT NULL",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS total_amount FLOAT DEFAULT 0.0 NOT NULL"
]

with engine.connect() as conn:
    for cmd in commands:
        print(f"Executing: {cmd}")
        conn.execute(text(cmd))
    conn.commit()
    print("Database migration completed successfully!")
