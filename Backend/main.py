from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from db import engine, SessionLocal

load_dotenv()

from models import Base, User
from schemas import UserCreate, UserOut, TokenOut, LoginSchema
from auth import get_password_hash, verify_password, create_access_token

Base.metadata.create_all(bind=engine)

app = FastAPI()

# Allow CORS for development (adjust origins in production)
app.add_middleware(
	CORSMiddleware,
	allow_origins=["*"],
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)


@app.post("/auth/register", response_model=UserOut, status_code=201)
def register(user_in: UserCreate):
	db = SessionLocal()
	try:
		# check existing
		existing = db.query(User).filter(User.email == user_in.email).first()
		if existing:
			raise HTTPException(status_code=400, detail="Email already registered")

		hashed = get_password_hash(user_in.password)
		user = User(
			email=user_in.email,
			full_name=user_in.full_name or '',
			password=hashed,
			phone=user_in.phone,
			role=user_in.role or 'user',
		)
		db.add(user)
		db.commit()
		db.refresh(user)
		return user
	finally:
		db.close()


@app.post("/auth/login", response_model=TokenOut)
def login(data: LoginSchema):
	db = SessionLocal()
	try:
		user = db.query(User).filter(User.email == data.email).first()
		if not user or not verify_password(data.password, user.password):
			raise HTTPException(status_code=401, detail="Invalid credentials")

		token = create_access_token({"sub": str(user.id), "role": user.role})
		return {"access_token": token, "token_type": "bearer", "role": user.role}
	finally:
		db.close()

# include additional routers
from routers import admin_router

app.include_router(admin_router.router, prefix="/admin")
