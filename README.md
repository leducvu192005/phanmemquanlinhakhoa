# Dental Clinic Management System

A full-stack dental clinic management system for handling users, roles, appointments, patients, services, pricing, doctor schedules, and patient appointment booking.

The project uses:

- **Frontend:** Flutter for mobile and web
- **Backend:** FastAPI
- **Database:** Supabase PostgreSQL
- **Authentication:** Supabase Auth or backend-issued JWT tokens
- **Authorization:** Role-based access control for Admin, Staff, Doctor, and Patient users

## Table of Contents

- [Project Goals](#project-goals)
- [System Roles](#system-roles)
- [Architecture Overview](#architecture-overview)
- [Folder Structure](#folder-structure)
- [Database Design Overview](#database-design-overview)
- [Role-Based Access Control](#role-based-access-control)
- [API Structure](#api-structure)
- [Real API Examples](#real-api-examples)
- [Development Setup](#development-setup)
- [How to Run the Backend](#how-to-run-the-backend)
- [How to Run the Frontend](#how-to-run-the-frontend)
- [Development Workflow](#development-workflow)
- [Task Division for a 2-Person Team](#task-division-for-a-2-person-team)
- [Testing Guide](#testing-guide)
- [Deployment Notes](#deployment-notes)

## Project Goals

The system is designed to help a dental clinic manage its daily operations in one application.

Main goals:

- Allow patients to book dental appointments online.
- Allow staff to manage patients, appointments, services, and pricing.
- Allow doctors to view schedules and create medical records.
- Allow admins to manage users and role permissions.
- Store clinic data in a structured PostgreSQL database using Supabase.
- Provide a clean API layer using FastAPI.
- Support Flutter mobile and Flutter web from the same codebase.

## System Roles

### Admin

Admins manage the system and user access.

Responsibilities:

- Create, update, deactivate, and delete users.
- Assign roles to users.
- View all system data.
- Manage clinic-level settings.
- Audit user activity when needed.

Typical screens:

- User management
- Role management
- Dashboard
- Clinic settings

### Staff

Staff members handle clinic operations.

Responsibilities:

- Create and update patient profiles.
- Create, reschedule, cancel, and confirm appointments.
- Manage dental services.
- Manage service prices.
- View doctor availability.
- Handle appointment status changes.

Typical screens:

- Appointment calendar
- Patient list
- Patient detail
- Service and pricing management

### Doctor

Doctors use the system mainly for schedule and treatment documentation.

Responsibilities:

- View personal appointment schedule.
- View assigned patient information.
- Create medical records.
- Add diagnosis, treatment notes, prescriptions, and follow-up instructions.
- Update appointment treatment status.

Typical screens:

- My schedule
- Appointment detail
- Medical record form
- Patient treatment history

### Patient

Patients use the app to book and track their appointments.

Responsibilities:

- Register or log in.
- View available services.
- Book appointments.
- View appointment history.
- Cancel appointments if clinic policy allows.
- Update basic personal information.

Typical screens:

- Service list
- Book appointment
- My appointments
- Profile

## Architecture Overview

The application follows a simple client-server architecture.

```text
Flutter App
Mobile + Web
    |
    | HTTPS REST API
    v
FastAPI Backend
Authentication, validation, business rules, RBAC
    |
    | SQL queries / Supabase client
    v
Supabase PostgreSQL
Users, roles, patients, appointments, services, records
```

### Frontend Layer

Flutter is responsible for:

- Displaying screens for each role.
- Calling backend REST APIs.
- Storing the access token locally after login.
- Showing or hiding UI features based on the current user's role.
- Validating simple form input before sending requests.

Recommended frontend state management options:

- `provider`
- `riverpod`
- `bloc`

For this project, beginners can start with `provider` or `riverpod` because they are easier to organize as the app grows.

### Backend Layer

FastAPI is responsible for:

- Receiving requests from the Flutter app.
- Validating request data with Pydantic schemas.
- Checking authentication tokens.
- Enforcing role-based access rules.
- Running business logic.
- Reading and writing data in Supabase PostgreSQL.
- Returning consistent JSON responses.

The backend should be the main place where permission checks happen. The frontend can hide buttons, but the backend must still protect every restricted endpoint.

### Database Layer

Supabase PostgreSQL stores the application data.

Supabase can provide:

- PostgreSQL database
- Authentication
- Row Level Security policies
- Storage, if the clinic later needs files such as X-rays or documents
- Dashboard for inspecting tables

## Folder Structure

Current repository layout:

```text
.
├── Backend/
├── flutter_application_1/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   └── main.dart
│   ├── test/
│   ├── web/
│   ├── pubspec.yaml
│   └── README.md
└── README.md
```

Recommended final project structure:

```text
.
├── Backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   └── rbac.py
│   │   ├── db/
│   │   │   ├── supabase.py
│   │   │   └── migrations/
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── patient.py
│   │   │   ├── appointment.py
│   │   │   ├── service.py
│   │   │   └── medical_record.py
│   │   ├── schemas/
│   │   │   ├── auth.py
│   │   │   ├── user.py
│   │   │   ├── patient.py
│   │   │   ├── appointment.py
│   │   │   ├── service.py
│   │   │   └── medical_record.py
│   │   ├── routers/
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   ├── patients.py
│   │   │   ├── appointments.py
│   │   │   ├── services.py
│   │   │   └── medical_records.py
│   │   └── services/
│   │       ├── user_service.py
│   │       ├── appointment_service.py
│   │       └── medical_record_service.py
│   ├── tests/
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
│
├── flutter_application_1/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   ├── routing/
│   │   │   ├── theme/
│   │   │   └── utils/
│   │   ├── data/
│   │   │   ├── api/
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── auth_api.dart
│   │   │   │   ├── appointment_api.dart
│   │   │   │   └── patient_api.dart
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── admin/
│   │   │   ├── staff/
│   │   │   ├── doctor/
│   │   │   └── patient/
│   │   └── shared/
│   │       ├── widgets/
│   │       └── providers/
│   ├── test/
│   ├── web/
│   └── pubspec.yaml
│
└── README.md
```

## Database Design Overview

The database should be normalized enough to avoid duplicate data, but simple enough for a beginner team to maintain.

### Main Tables

### `users`

Stores application users and links them to roles.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `email` | `text` | Unique login email |
| `full_name` | `text` | User display name |
| `phone` | `text` | Contact number |
| `role` | `text` | `admin`, `staff`, `doctor`, or `patient` |
| `is_active` | `boolean` | Whether user can access the system |
| `created_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update time |

### `patients`

Stores patient-specific information.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | Optional link to `users.id` |
| `full_name` | `text` | Patient name |
| `date_of_birth` | `date` | Date of birth |
| `gender` | `text` | Gender |
| `phone` | `text` | Phone number |
| `address` | `text` | Address |
| `allergies` | `text` | Known allergies |
| `medical_notes` | `text` | General health notes |
| `created_at` | `timestamp` | Creation time |

### `doctors`

Stores doctor profile data.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | Link to `users.id` |
| `specialization` | `text` | Example: orthodontics, surgery, general dentistry |
| `license_number` | `text` | Doctor license number |
| `is_available` | `boolean` | Whether doctor can receive appointments |

### `services`

Stores dental services and prices.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `name` | `text` | Service name |
| `description` | `text` | Service description |
| `duration_minutes` | `integer` | Expected appointment duration |
| `price` | `numeric` | Current service price |
| `is_active` | `boolean` | Whether service is bookable |

### `appointments`

Stores appointment bookings.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `patient_id` | `uuid` | Link to `patients.id` |
| `doctor_id` | `uuid` | Link to `doctors.id` |
| `service_id` | `uuid` | Link to `services.id` |
| `appointment_time` | `timestamp` | Scheduled start time |
| `status` | `text` | `pending`, `confirmed`, `completed`, `cancelled`, `no_show` |
| `reason` | `text` | Patient reason or complaint |
| `created_by` | `uuid` | User who created the appointment |
| `created_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update time |

### `medical_records`

Stores doctor-created clinical records.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `appointment_id` | `uuid` | Link to `appointments.id` |
| `patient_id` | `uuid` | Link to `patients.id` |
| `doctor_id` | `uuid` | Link to `doctors.id` |
| `diagnosis` | `text` | Diagnosis |
| `treatment` | `text` | Treatment performed |
| `prescription` | `text` | Medication instructions |
| `notes` | `text` | Additional notes |
| `follow_up_date` | `date` | Optional follow-up date |
| `created_at` | `timestamp` | Creation time |

### `audit_logs`

Tracks important actions.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | User who performed the action |
| `action` | `text` | Example: `CREATE_APPOINTMENT` |
| `entity_type` | `text` | Example: `appointment` |
| `entity_id` | `uuid` | ID of affected record |
| `created_at` | `timestamp` | Action time |

### Relationships

```text
users 1--1 doctors
users 1--1 patients
patients 1--many appointments
doctors 1--many appointments
services 1--many appointments
appointments 1--1 medical_records
patients 1--many medical_records
doctors 1--many medical_records
users 1--many audit_logs
```

### Example SQL Schema

```sql
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  full_name text not null,
  phone text,
  role text not null check (role in ('admin', 'staff', 'doctor', 'patient')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table patients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  full_name text not null,
  date_of_birth date,
  gender text,
  phone text,
  address text,
  allergies text,
  medical_notes text,
  created_at timestamptz not null default now()
);

create table doctors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  specialization text,
  license_number text,
  is_available boolean not null default true
);

create table services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  duration_minutes integer not null default 30,
  price numeric(12, 2) not null default 0,
  is_active boolean not null default true
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete restrict,
  service_id uuid not null references services(id) on delete restrict,
  appointment_time timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
  reason text,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table medical_records (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid unique not null references appointments(id) on delete cascade,
  patient_id uuid not null references patients(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete restrict,
  diagnosis text not null,
  treatment text not null,
  prescription text,
  notes text,
  follow_up_date date,
  created_at timestamptz not null default now()
);
```

## Role-Based Access Control

Role-based access control decides what each user can do.

### Permission Matrix

| Feature | Admin | Staff | Doctor | Patient |
| --- | --- | --- | --- | --- |
| Manage users | Yes | No | No | No |
| Assign roles | Yes | No | No | No |
| Manage patients | Yes | Yes | View assigned | Own profile only |
| Manage services | Yes | Yes | View only | View only |
| Manage pricing | Yes | Yes | No | No |
| Create appointments | Yes | Yes | No | Yes, for self |
| Update appointment status | Yes | Yes | Limited | Cancel own only |
| View all appointments | Yes | Yes | No | No |
| View doctor schedule | Yes | Yes | Own schedule | No |
| Create medical records | No | No | Yes | No |
| View medical records | Yes | Staff-limited | Own patients | Own records |

### Backend RBAC Example

Use a dependency to require a role before allowing a request.

```python
from fastapi import Depends, HTTPException, status

def require_roles(*allowed_roles: str):
    def checker(current_user = Depends(get_current_user)):
        if current_user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action",
            )
        return current_user
    return checker
```

Example route:

```python
@router.post("/services")
async def create_service(
    payload: ServiceCreate,
    current_user = Depends(require_roles("admin", "staff")),
):
    return service_service.create_service(payload)
```

Important rule:

The frontend can hide restricted buttons, but the backend must always enforce permissions.

## API Structure

Recommended API base URL during local development:

```text
http://localhost:8000/api/v1
```

### Main API Groups

| Group | Prefix | Purpose |
| --- | --- | --- |
| Auth | `/api/v1/auth` | Login, register, current user |
| Users | `/api/v1/users` | Admin user management |
| Patients | `/api/v1/patients` | Patient profiles |
| Doctors | `/api/v1/doctors` | Doctor profiles and availability |
| Services | `/api/v1/services` | Dental services and prices |
| Appointments | `/api/v1/appointments` | Booking and schedule management |
| Medical Records | `/api/v1/medical-records` | Diagnosis and treatment records |

### Suggested Endpoints

### Auth

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `POST` | `/auth/register` | Public | Register a patient account |
| `POST` | `/auth/login` | Public | Log in and receive token |
| `GET` | `/auth/me` | All authenticated users | Get current user profile |
| `POST` | `/auth/logout` | All authenticated users | Log out |

### Users

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `GET` | `/users` | Admin | List users |
| `POST` | `/users` | Admin | Create user |
| `GET` | `/users/{user_id}` | Admin | Get user detail |
| `PATCH` | `/users/{user_id}` | Admin | Update user |
| `PATCH` | `/users/{user_id}/role` | Admin | Change user role |
| `DELETE` | `/users/{user_id}` | Admin | Deactivate user |

### Patients

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `GET` | `/patients` | Admin, Staff | List patients |
| `POST` | `/patients` | Admin, Staff | Create patient |
| `GET` | `/patients/{patient_id}` | Admin, Staff, Doctor, Patient owner | Get patient detail |
| `PATCH` | `/patients/{patient_id}` | Admin, Staff, Patient owner | Update patient |

### Services

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `GET` | `/services` | All authenticated users | List active services |
| `POST` | `/services` | Admin, Staff | Create service |
| `PATCH` | `/services/{service_id}` | Admin, Staff | Update service or price |
| `DELETE` | `/services/{service_id}` | Admin, Staff | Disable service |

### Appointments

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `GET` | `/appointments` | Admin, Staff | List all appointments |
| `POST` | `/appointments` | Admin, Staff, Patient | Create appointment |
| `GET` | `/appointments/my` | Doctor, Patient | List current user's appointments |
| `GET` | `/appointments/{appointment_id}` | Authorized users | Get appointment detail |
| `PATCH` | `/appointments/{appointment_id}` | Admin, Staff | Reschedule or edit appointment |
| `PATCH` | `/appointments/{appointment_id}/status` | Admin, Staff, Doctor | Update appointment status |
| `DELETE` | `/appointments/{appointment_id}` | Admin, Staff, Patient owner | Cancel appointment |

### Medical Records

| Method | Endpoint | Roles | Description |
| --- | --- | --- | --- |
| `GET` | `/medical-records` | Admin, Doctor | List medical records |
| `POST` | `/medical-records` | Doctor | Create medical record |
| `GET` | `/medical-records/{record_id}` | Authorized users | Get medical record detail |
| `PATCH` | `/medical-records/{record_id}` | Doctor owner | Update medical record |

## Real API Examples

The examples below assume the backend is running at:

```text
http://localhost:8000/api/v1
```

### Register a Patient

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@example.com",
    "password": "StrongPassword123",
    "full_name": "Nguyen Van A",
    "phone": "0901234567"
  }'
```

Response:

```json
{
  "id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
  "email": "patient@example.com",
  "full_name": "Nguyen Van A",
  "role": "patient",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Login

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "staff@example.com",
    "password": "StrongPassword123"
  }'
```

Response:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "97f8c930-4f36-4404-8901-3e8b02aa01c6",
    "email": "staff@example.com",
    "full_name": "Clinic Staff",
    "role": "staff"
  }
}
```

### Create a Dental Service

Allowed roles: Admin, Staff.

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/services" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dental Cleaning",
    "description": "Basic teeth cleaning and oral hygiene check",
    "duration_minutes": 30,
    "price": 300000
  }'
```

Response:

```json
{
  "id": "c57a49d5-2eec-407b-9e9e-41fa5c7c6f6d",
  "name": "Dental Cleaning",
  "description": "Basic teeth cleaning and oral hygiene check",
  "duration_minutes": 30,
  "price": 300000,
  "is_active": true
}
```

### Book an Appointment

Allowed roles: Admin, Staff, Patient.

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/appointments" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
    "doctor_id": "f80ec2dc-e97d-4f9a-a0be-860e3e620908",
    "service_id": "c57a49d5-2eec-407b-9e9e-41fa5c7c6f6d",
    "appointment_time": "2026-05-10T09:00:00+07:00",
    "reason": "Tooth pain on lower right side"
  }'
```

Response:

```json
{
  "id": "ad4cf0f4-7c3a-4be4-a8da-d6f690975337",
  "patient_id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
  "doctor_id": "f80ec2dc-e97d-4f9a-a0be-860e3e620908",
  "service_id": "c57a49d5-2eec-407b-9e9e-41fa5c7c6f6d",
  "appointment_time": "2026-05-10T09:00:00+07:00",
  "status": "pending",
  "reason": "Tooth pain on lower right side"
}
```

### Update Appointment Status

Allowed roles: Admin, Staff, Doctor.

Request:

```bash
curl -X PATCH "http://localhost:8000/api/v1/appointments/ad4cf0f4-7c3a-4be4-a8da-d6f690975337/status" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "confirmed"
  }'
```

Response:

```json
{
  "id": "ad4cf0f4-7c3a-4be4-a8da-d6f690975337",
  "status": "confirmed",
  "updated_at": "2026-05-03T15:20:30Z"
}
```

### Create a Medical Record

Allowed roles: Doctor.

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/medical-records" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": "ad4cf0f4-7c3a-4be4-a8da-d6f690975337",
    "patient_id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
    "doctor_id": "f80ec2dc-e97d-4f9a-a0be-860e3e620908",
    "diagnosis": "Dental caries",
    "treatment": "Cavity cleaning and composite filling",
    "prescription": "Ibuprofen 400mg if pain occurs",
    "notes": "Patient should avoid hard food for 24 hours",
    "follow_up_date": "2026-05-24"
  }'
```

Response:

```json
{
  "id": "ef398ba4-5f34-4f9f-b0ad-34fcf875f2f7",
  "appointment_id": "ad4cf0f4-7c3a-4be4-a8da-d6f690975337",
  "patient_id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
  "doctor_id": "f80ec2dc-e97d-4f9a-a0be-860e3e620908",
  "diagnosis": "Dental caries",
  "treatment": "Cavity cleaning and composite filling",
  "prescription": "Ibuprofen 400mg if pain occurs",
  "notes": "Patient should avoid hard food for 24 hours",
  "follow_up_date": "2026-05-24",
  "created_at": "2026-05-03T15:25:00Z"
}
```

### Error Response Format

Use a consistent error format across the backend.

```json
{
  "detail": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to perform this action"
  }
}
```

Common HTTP status codes:

| Status | Meaning |
| --- | --- |
| `200` | Request succeeded |
| `201` | Resource created |
| `400` | Invalid request |
| `401` | Missing or invalid token |
| `403` | User does not have permission |
| `404` | Resource not found |
| `409` | Conflict, such as duplicate appointment time |
| `422` | Validation error |
| `500` | Server error |

## Development Setup

### Required Software

Install the following:

- Flutter SDK
- Dart SDK, included with Flutter
- Python 3.11 or newer
- Git
- Supabase account
- Code editor such as VS Code or Android Studio
- Android Studio emulator or a physical Android device for mobile testing

Check versions:

```bash
flutter --version
python --version
git --version
```

### Supabase Setup

1. Create a Supabase project.
2. Open the SQL Editor in the Supabase dashboard.
3. Run the schema from the [Example SQL Schema](#example-sql-schema) section.
4. Copy the project URL and API keys.
5. Configure environment variables in the backend.

Recommended backend `.env` file:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
JWT_SECRET_KEY=replace-this-with-a-long-random-secret
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

Important:

- Never commit `.env` files.
- Use `.env.example` to document required variables.
- Use the Supabase service role key only on the backend.
- Never put the service role key inside the Flutter app.

## How to Run the Backend

The `Backend` folder is intended to contain the FastAPI application.

### 1. Create a Virtual Environment

Windows PowerShell:

```bash
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

macOS or Linux:

```bash
cd Backend
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install Dependencies

Create `requirements.txt` with:

```txt
fastapi
uvicorn[standard]
python-dotenv
pydantic
supabase
python-jose[cryptography]
passlib[bcrypt]
```

Install:

```bash
pip install -r requirements.txt
```

### 3. Create the FastAPI Entry Point

Recommended file:

```text
Backend/app/main.py
```

Minimal example:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Dental Clinic Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok"}
```

### 4. Run the Backend Server

From the `Backend` folder:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open:

```text
http://localhost:8000/docs
```

FastAPI automatically generates Swagger documentation at `/docs`.

## How to Run the Frontend

The Flutter project is located in:

```text
flutter_application_1
```

### 1. Install Flutter Dependencies

```bash
cd flutter_application_1
flutter pub get
```

### 2. Run on Web

```bash
flutter run -d chrome
```

### 3. Run on Android Emulator

```bash
flutter devices
flutter run -d emulator-5554
```

Use the device ID shown by `flutter devices`.

### 4. Configure API Base URL

Recommended Flutter config file:

```text
flutter_application_1/lib/core/constants/api_constants.dart
```

Example:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
}
```

For Android emulator, use:

```dart
class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
}
```

Why:

- `localhost` inside an Android emulator points to the emulator itself.
- `10.0.2.2` points from the Android emulator to the host computer.

## Development Workflow

Use a simple and consistent workflow.

### 1. Create a Git Branch

```bash
git checkout -b feature/appointment-booking
```

Branch naming examples:

- `feature/auth-login`
- `feature/admin-users`
- `feature/staff-appointments`
- `feature/doctor-medical-records`
- `fix/appointment-status-validation`

### 2. Implement Backend First for Each Feature

For example, appointment booking:

1. Create database table or migration.
2. Create Pydantic request and response schemas.
3. Create FastAPI route.
4. Add role checks.
5. Test the endpoint in Swagger or with `curl`.
6. Share the request and response format with the frontend developer.

### 3. Implement Frontend Screen

For example, appointment booking:

1. Create Dart model.
2. Create API client method.
3. Create repository method.
4. Build form screen.
5. Validate fields.
6. Call backend API.
7. Show loading, success, and error states.

### 4. Test Before Merging

Run backend checks:

```bash
cd Backend
pytest
```

Run frontend checks:

```bash
cd flutter_application_1
flutter analyze
flutter test
```

### 5. Pull Request Checklist

Before merging a branch, check:

- The feature works for the correct role.
- Restricted roles cannot access the feature.
- API request and response examples are updated if changed.
- Database changes are documented.
- No secret keys are committed.
- Flutter screens handle loading and error states.
- Backend returns useful validation errors.

## Task Division for a 2-Person Team

This project can be split between two developers: one backend-focused and one frontend-focused. Both developers should still review API contracts together.

### Developer 1: Backend and Database

Main responsibilities:

- Design Supabase PostgreSQL tables.
- Write SQL migrations.
- Build FastAPI routes.
- Implement authentication.
- Implement role-based access control.
- Validate data with Pydantic schemas.
- Write backend tests.
- Document API behavior.

Suggested task list:

| Priority | Task | Output |
| --- | --- | --- |
| 1 | Supabase schema | Tables for users, patients, doctors, services, appointments, medical records |
| 2 | Auth API | Register, login, current user |
| 3 | RBAC dependency | `require_roles()` helper |
| 4 | User API | Admin user management |
| 5 | Service API | Staff service and pricing management |
| 6 | Patient API | Patient CRUD |
| 7 | Appointment API | Booking, schedule, status updates |
| 8 | Medical record API | Doctor treatment records |
| 9 | Tests | Unit and integration tests |

### Developer 2: Flutter Frontend

Main responsibilities:

- Build role-specific UI screens.
- Create API client layer.
- Store and attach authentication token.
- Build forms and validation.
- Handle loading, empty, success, and error states.
- Implement navigation based on user role.
- Test on mobile and web.

Suggested task list:

| Priority | Task | Output |
| --- | --- | --- |
| 1 | App structure | Routing, theme, shared widgets |
| 2 | Auth UI | Login and patient registration |
| 3 | API client | Reusable HTTP client with bearer token |
| 4 | Role navigation | Admin, Staff, Doctor, Patient home screens |
| 5 | Patient booking | Service selection, doctor selection, date/time form |
| 6 | Staff screens | Appointment, patient, service, pricing management |
| 7 | Doctor screens | Schedule and medical record form |
| 8 | Admin screens | User and role management |
| 9 | Tests | Widget and basic integration tests |

### Shared Responsibilities

Both developers should agree on:

- API endpoint names.
- JSON request and response formats.
- Appointment status values.
- Role permission rules.
- Error response format.
- Database naming conventions.
- Definition of done for each feature.

### Suggested 4-Week Plan

| Week | Backend Developer | Flutter Developer |
| --- | --- | --- |
| Week 1 | Database schema, auth, RBAC | App shell, routing, theme, login UI |
| Week 2 | Users, patients, services APIs | Auth integration, patient and service screens |
| Week 3 | Appointment APIs, schedule rules | Booking flow, staff appointment calendar |
| Week 4 | Medical records, tests, API polish | Doctor screens, admin screens, final testing |

## Testing Guide

### Backend Testing

Recommended tools:

- `pytest`
- FastAPI `TestClient`

Example test:

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

Important backend test cases:

- Patient can register.
- User can login.
- Staff can create services.
- Patient cannot create services.
- Patient can book appointment for self.
- Patient cannot book appointment for another patient.
- Doctor can create medical record for assigned appointment.
- Doctor cannot create medical record for another doctor's appointment.

### Frontend Testing

Recommended Flutter checks:

```bash
flutter analyze
flutter test
```

Important frontend test cases:

- Login form validates empty fields.
- Patient booking form requires service, doctor, date, and time.
- Staff service form validates price.
- Doctor medical record form requires diagnosis and treatment.
- UI shows correct navigation items for each role.

## Deployment Notes

### Backend Deployment

The FastAPI backend can be deployed to:

- Render
- Railway
- Fly.io
- Azure App Service
- AWS Elastic Beanstalk
- Docker-based VPS

Production command example:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

For production, use a process manager or deployment platform that restarts the server automatically.

### Frontend Deployment

Flutter web build:

```bash
cd flutter_application_1
flutter build web
```

The generated web files are located in:

```text
flutter_application_1/build/web
```

These files can be deployed to:

- Firebase Hosting
- Netlify
- Vercel
- Supabase Storage
- Any static web server

### Mobile Build

Android release build:

```bash
cd flutter_application_1
flutter build apk --release
```

iOS release builds require macOS and Xcode:

```bash
flutter build ios --release
```

## Security Notes

- Store passwords securely using Supabase Auth or strong password hashing.
- Never store plain-text passwords.
- Never expose the Supabase service role key in Flutter.
- Validate every request on the backend.
- Enforce RBAC on every protected endpoint.
- Use HTTPS in production.
- Keep audit logs for sensitive actions such as role changes and medical record updates.
- Use database constraints to prevent invalid statuses and broken references.

## Beginner Implementation Order

For a beginner-friendly build process, implement the system in this order:

1. Supabase tables.
2. FastAPI health check.
3. Backend environment configuration.
4. Auth register and login.
5. Flutter login screen.
6. Role-based home navigation.
7. Services API and screens.
8. Patients API and screens.
9. Appointment booking API.
10. Patient booking screen.
11. Staff appointment management.
12. Doctor schedule screen.
13. Medical record API and screen.
14. Admin user management.
15. Tests and deployment.

## Definition of Done

A feature is complete when:

- The database supports the required data.
- The backend endpoint validates input.
- The backend endpoint checks permissions.
- The API is documented with request and response examples.
- The Flutter screen works on web and mobile.
- Loading and error states are handled.
- At least one basic test covers the feature.

## License

This project is intended for educational and internal clinic management use. Add a license file before public release.
#   p h a n m e m q u a n l i n h a k h o a  
 