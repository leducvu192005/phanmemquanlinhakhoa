# Hệ Thống Quản Lý Phòng Khám Nha Khoa

Đây là tài liệu hướng dẫn đầy đủ cho dự án **Dental Clinic Management System** - hệ thống quản lý phòng khám nha khoa dùng Flutter, FastAPI và Supabase PostgreSQL.

Dự án hướng đến một hệ thống có thể dùng cho phòng khám nha khoa nhỏ hoặc vừa, hỗ trợ quản lý người dùng, bệnh nhân, lịch hẹn, dịch vụ, bảng giá, lịch làm việc của bác sĩ và hồ sơ điều trị.

## Công Nghệ Sử Dụng

| Thành phần | Công nghệ |
| --- | --- |
| Frontend | Flutter, hỗ trợ Mobile và Web |
| Backend | FastAPI |
| Database | Supabase PostgreSQL |
| Authentication | Supabase Auth hoặc JWT do backend cấp |
| Authorization | Role-Based Access Control |
| API Style | REST API |
| API Docs | Swagger UI do FastAPI tự sinh |

## Mục Tiêu Của Dự Án

Hệ thống được xây dựng để giải quyết các nghiệp vụ chính trong phòng khám nha khoa:

- Bệnh nhân có thể đăng ký tài khoản và đặt lịch khám.
- Nhân viên có thể quản lý bệnh nhân, lịch hẹn, dịch vụ và giá dịch vụ.
- Bác sĩ có thể xem lịch làm việc và tạo hồ sơ điều trị.
- Admin có thể quản lý tài khoản người dùng và phân quyền.
- Dữ liệu được lưu trữ tập trung trong Supabase PostgreSQL.
- Backend kiểm soát toàn bộ nghiệp vụ và phân quyền.
- Frontend Flutter có thể chạy trên web, Android và iOS.

## Vai Trò Trong Hệ Thống

Hệ thống có 4 vai trò chính:

```text
Admin
Staff
Doctor
Patient
```

Mỗi vai trò có trách nhiệm và quyền truy cập khác nhau.

## Trách Nhiệm Của Từng Vai Trò

### 1. Admin

Admin là người quản trị cao nhất trong hệ thống.

Admin có trách nhiệm:

- Quản lý tài khoản người dùng.
- Thêm, sửa, khóa hoặc vô hiệu hóa tài khoản.
- Gán vai trò cho người dùng.
- Xem toàn bộ dữ liệu trong hệ thống.
- Quản lý cấu hình chung của phòng khám.
- Theo dõi các thao tác quan trọng thông qua audit log.

Chức năng nên có cho Admin:

- Trang dashboard tổng quan.
- Quản lý người dùng.
- Quản lý vai trò.
- Quản lý trạng thái tài khoản.
- Xem thống kê lịch hẹn, bệnh nhân, bác sĩ.

### 2. Staff

Staff là nhân viên lễ tân hoặc nhân viên vận hành phòng khám.

Staff có trách nhiệm:

- Quản lý danh sách bệnh nhân.
- Tạo hồ sơ bệnh nhân mới.
- Tạo lịch hẹn cho bệnh nhân.
- Xác nhận, hủy hoặc dời lịch hẹn.
- Quản lý danh sách dịch vụ nha khoa.
- Quản lý giá dịch vụ.
- Xem lịch làm việc của bác sĩ.

Chức năng nên có cho Staff:

- Quản lý lịch hẹn.
- Quản lý bệnh nhân.
- Quản lý dịch vụ.
- Quản lý bảng giá.
- Tìm kiếm bệnh nhân theo tên, số điện thoại hoặc mã bệnh nhân.

### 3. Doctor

Doctor là bác sĩ nha khoa sử dụng hệ thống để theo dõi lịch khám và ghi nhận điều trị.

Doctor có trách nhiệm:

- Xem lịch hẹn được phân công.
- Xem thông tin bệnh nhân liên quan đến lịch khám của mình.
- Tạo hồ sơ bệnh án hoặc hồ sơ điều trị.
- Ghi chẩn đoán, phương pháp điều trị, đơn thuốc và ghi chú.
- Cập nhật kết quả khám.
- Đề xuất ngày tái khám.

Chức năng nên có cho Doctor:

- Trang lịch làm việc cá nhân.
- Chi tiết lịch hẹn.
- Chi tiết bệnh nhân.
- Tạo hồ sơ điều trị.
- Xem lịch sử điều trị của bệnh nhân.

### 4. Patient

Patient là bệnh nhân sử dụng ứng dụng để đặt lịch và theo dõi lịch khám.

Patient có trách nhiệm:

- Đăng ký tài khoản.
- Đăng nhập.
- Xem danh sách dịch vụ nha khoa.
- Chọn bác sĩ, dịch vụ, ngày và giờ khám.
- Đặt lịch hẹn.
- Xem lịch hẹn của bản thân.
- Hủy lịch hẹn nếu chính sách phòng khám cho phép.
- Cập nhật thông tin cá nhân.

Chức năng nên có cho Patient:

- Đăng ký, đăng nhập.
- Xem dịch vụ.
- Đặt lịch khám.
- Xem lịch hẹn cá nhân.
- Xem hồ sơ điều trị của bản thân.
- Cập nhật hồ sơ cá nhân.

## Kiến Trúc Tổng Quan

Hệ thống sử dụng mô hình client-server.

```text
Flutter App
Mobile + Web
    |
    | Gửi HTTP request qua REST API
    v
FastAPI Backend
Xử lý đăng nhập, nghiệp vụ, kiểm tra phân quyền
    |
    | Truy vấn dữ liệu
    v
Supabase PostgreSQL
Lưu users, patients, doctors, appointments, services, medical_records
```

### Luồng Hoạt Động Cơ Bản

Ví dụ bệnh nhân đặt lịch:

```text
1. Patient đăng nhập trên Flutter app
2. Flutter lưu access token
3. Patient chọn dịch vụ, bác sĩ, ngày giờ
4. Flutter gửi request POST /appointments lên FastAPI
5. FastAPI kiểm tra token
6. FastAPI kiểm tra role patient
7. FastAPI kiểm tra bệnh nhân có được đặt lịch cho chính mình không
8. FastAPI kiểm tra bác sĩ có trống lịch không
9. FastAPI ghi lịch hẹn vào Supabase
10. FastAPI trả kết quả về Flutter
11. Flutter hiển thị đặt lịch thành công
```

## Giải Thích Từng Tầng Kiến Trúc

### Frontend - Flutter

Flutter chịu trách nhiệm hiển thị giao diện và tương tác với người dùng.

Frontend nên làm:

- Hiển thị màn hình theo từng vai trò.
- Gọi API backend.
- Lưu token sau khi đăng nhập.
- Gửi token trong header `Authorization`.
- Validate form cơ bản trước khi gửi request.
- Hiển thị loading, error, empty state và success state.
- Điều hướng người dùng đến đúng dashboard theo role.

Frontend không nên làm:

- Không tự quyết định quyền truy cập quan trọng.
- Không chứa Supabase service role key.
- Không xử lý nghiệp vụ nhạy cảm như phân quyền, đổi role, tạo hồ sơ điều trị trái quyền.

### Backend - FastAPI

FastAPI là tầng xử lý nghiệp vụ chính.

Backend chịu trách nhiệm:

- Nhận request từ Flutter.
- Kiểm tra dữ liệu đầu vào bằng Pydantic.
- Kiểm tra token đăng nhập.
- Kiểm tra role của người dùng.
- Xử lý nghiệp vụ đặt lịch, đổi trạng thái, tạo bệnh án.
- Giao tiếp với Supabase PostgreSQL.
- Trả JSON response rõ ràng cho frontend.

Backend là nơi bắt buộc phải kiểm tra quyền. Dù frontend có ẩn nút chức năng, người dùng vẫn có thể gọi API trực tiếp, vì vậy mọi endpoint nhạy cảm đều phải có kiểm tra phân quyền.

### Database - Supabase PostgreSQL

Supabase PostgreSQL lưu toàn bộ dữ liệu chính:

- Người dùng.
- Vai trò.
- Bệnh nhân.
- Bác sĩ.
- Dịch vụ nha khoa.
- Giá dịch vụ.
- Lịch hẹn.
- Hồ sơ điều trị.
- Nhật ký thao tác.

Supabase cũng có thể mở rộng để dùng:

- Supabase Auth cho đăng nhập.
- Supabase Storage để lưu ảnh chụp X-quang hoặc file hồ sơ.
- Row Level Security để bảo vệ dữ liệu ở tầng database.

## Cấu Trúc Thư Mục Hiện Tại

Repository hiện tại có cấu trúc:

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

Trong đó:

- `Backend/`: thư mục dành cho FastAPI backend.
- `flutter_application_1/`: thư mục chứa Flutter app.
- `README.md`: tài liệu tổng quan toàn dự án.

## Cấu Trúc Thư Mục Đề Xuất

Khi phát triển đầy đủ, nên tổ chức lại như sau:

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
│   │   ├── schemas/
│   │   │   ├── auth.py
│   │   │   ├── user.py
│   │   │   ├── patient.py
│   │   │   ├── doctor.py
│   │   │   ├── service.py
│   │   │   ├── appointment.py
│   │   │   └── medical_record.py
│   │   ├── routers/
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   ├── patients.py
│   │   │   ├── doctors.py
│   │   │   ├── services.py
│   │   │   ├── appointments.py
│   │   │   └── medical_records.py
│   │   └── services/
│   │       ├── auth_service.py
│   │       ├── user_service.py
│   │       ├── patient_service.py
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
│   │   │   │   └── api_constants.dart
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
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── patient_model.dart
│   │   │   │   ├── appointment_model.dart
│   │   │   │   └── service_model.dart
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

## Thiết Kế Database

Database nên được thiết kế rõ ràng ngay từ đầu vì đây là phần ảnh hưởng đến toàn bộ hệ thống.

Các bảng chính:

```text
users
patients
doctors
services
appointments
medical_records
audit_logs
```

## Bảng `users`

Bảng này lưu thông tin tài khoản đăng nhập và vai trò.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `email` | `text` | Email đăng nhập, không được trùng |
| `full_name` | `text` | Họ tên người dùng |
| `phone` | `text` | Số điện thoại |
| `role` | `text` | `admin`, `staff`, `doctor`, `patient` |
| `is_active` | `boolean` | Tài khoản có đang hoạt động không |
| `created_at` | `timestamptz` | Thời điểm tạo |
| `updated_at` | `timestamptz` | Thời điểm cập nhật |

## Bảng `patients`

Bảng này lưu thông tin bệnh nhân.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `user_id` | `uuid` | Liên kết đến `users.id`, có thể null |
| `full_name` | `text` | Họ tên bệnh nhân |
| `date_of_birth` | `date` | Ngày sinh |
| `gender` | `text` | Giới tính |
| `phone` | `text` | Số điện thoại |
| `address` | `text` | Địa chỉ |
| `allergies` | `text` | Dị ứng nếu có |
| `medical_notes` | `text` | Ghi chú y tế tổng quát |
| `created_at` | `timestamptz` | Thời điểm tạo |

## Bảng `doctors`

Bảng này lưu thông tin riêng của bác sĩ.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `user_id` | `uuid` | Liên kết đến `users.id` |
| `specialization` | `text` | Chuyên môn |
| `license_number` | `text` | Số giấy phép hành nghề |
| `is_available` | `boolean` | Có đang nhận lịch không |

## Bảng `services`

Bảng này lưu dịch vụ nha khoa và giá.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `name` | `text` | Tên dịch vụ |
| `description` | `text` | Mô tả dịch vụ |
| `duration_minutes` | `integer` | Thời lượng dự kiến |
| `price` | `numeric` | Giá dịch vụ |
| `is_active` | `boolean` | Dịch vụ có đang được sử dụng không |

Ví dụ dịch vụ:

- Khám tổng quát.
- Cạo vôi răng.
- Trám răng.
- Nhổ răng.
- Tẩy trắng răng.
- Niềng răng.
- Điều trị tủy.

## Bảng `appointments`

Bảng này lưu lịch hẹn khám.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `patient_id` | `uuid` | Bệnh nhân đặt lịch |
| `doctor_id` | `uuid` | Bác sĩ phụ trách |
| `service_id` | `uuid` | Dịch vụ được chọn |
| `appointment_time` | `timestamptz` | Thời gian khám |
| `status` | `text` | Trạng thái lịch hẹn |
| `reason` | `text` | Lý do khám |
| `created_by` | `uuid` | Người tạo lịch |
| `created_at` | `timestamptz` | Thời điểm tạo |
| `updated_at` | `timestamptz` | Thời điểm cập nhật |

Các trạng thái lịch hẹn:

| Trạng thái | Ý nghĩa |
| --- | --- |
| `pending` | Chờ xác nhận |
| `confirmed` | Đã xác nhận |
| `completed` | Đã khám xong |
| `cancelled` | Đã hủy |
| `no_show` | Bệnh nhân không đến |

## Bảng `medical_records`

Bảng này lưu hồ sơ điều trị do bác sĩ tạo.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `appointment_id` | `uuid` | Liên kết lịch hẹn |
| `patient_id` | `uuid` | Bệnh nhân |
| `doctor_id` | `uuid` | Bác sĩ tạo hồ sơ |
| `diagnosis` | `text` | Chẩn đoán |
| `treatment` | `text` | Phương pháp điều trị |
| `prescription` | `text` | Đơn thuốc |
| `notes` | `text` | Ghi chú |
| `follow_up_date` | `date` | Ngày tái khám |
| `created_at` | `timestamptz` | Thời điểm tạo |

## Bảng `audit_logs`

Bảng này ghi lại các hành động quan trọng.

| Cột | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `id` | `uuid` | Khóa chính |
| `user_id` | `uuid` | Người thực hiện |
| `action` | `text` | Hành động |
| `entity_type` | `text` | Loại dữ liệu bị tác động |
| `entity_id` | `uuid` | ID bản ghi bị tác động |
| `created_at` | `timestamptz` | Thời điểm thực hiện |

Ví dụ `action`:

```text
CREATE_USER
CHANGE_USER_ROLE
CREATE_APPOINTMENT
CANCEL_APPOINTMENT
CREATE_MEDICAL_RECORD
UPDATE_SERVICE_PRICE
```

## Quan Hệ Giữa Các Bảng

```text
users 1--1 doctors
users 1--1 patients
patients 1--n appointments
doctors 1--n appointments
services 1--n appointments
appointments 1--1 medical_records
patients 1--n medical_records
doctors 1--n medical_records
users 1--n audit_logs
```

Giải thích:

- Một user có thể là doctor hoặc patient.
- Một patient có nhiều appointments.
- Một doctor có nhiều appointments.
- Một appointment thuộc về một service.
- Một appointment sau khi khám có thể có một medical record.
- Một patient có thể có nhiều medical records theo thời gian.

## SQL Schema Mẫu

Có thể chạy SQL này trong Supabase SQL Editor để tạo database cơ bản.

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

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  created_at timestamptz not null default now()
);
```

## Phân Quyền Role-Based Access Control

Phân quyền là phần rất quan trọng vì hệ thống có dữ liệu y tế.

Nguyên tắc:

- Người dùng phải đăng nhập mới được gọi API bảo vệ.
- Token phải hợp lệ.
- Tài khoản phải đang hoạt động.
- Role phải có quyền với chức năng đang gọi.
- Patient chỉ được xem và thao tác dữ liệu của chính mình.
- Doctor chỉ được tạo hồ sơ điều trị cho lịch hẹn được giao.
- Staff không được tạo hồ sơ điều trị.
- Admin có quyền quản trị người dùng nhưng không nên tự ý sửa nội dung chuyên môn y tế.

## Bảng Phân Quyền

| Chức năng | Admin | Staff | Doctor | Patient |
| --- | --- | --- | --- | --- |
| Quản lý user | Có | Không | Không | Không |
| Gán role | Có | Không | Không | Không |
| Xem danh sách bệnh nhân | Có | Có | Bệnh nhân được giao | Không |
| Tạo bệnh nhân | Có | Có | Không | Tự đăng ký |
| Sửa thông tin bệnh nhân | Có | Có | Hạn chế | Chính mình |
| Xem dịch vụ | Có | Có | Có | Có |
| Tạo dịch vụ | Có | Có | Không | Không |
| Sửa giá dịch vụ | Có | Có | Không | Không |
| Tạo lịch hẹn | Có | Có | Không | Cho chính mình |
| Xem toàn bộ lịch hẹn | Có | Có | Không | Không |
| Xem lịch cá nhân | Có | Có | Có | Có |
| Cập nhật trạng thái lịch hẹn | Có | Có | Hạn chế | Hủy lịch của mình |
| Tạo hồ sơ điều trị | Không | Không | Có | Không |
| Xem hồ sơ điều trị | Có | Hạn chế | Bệnh nhân được giao | Của chính mình |

## Ví Dụ RBAC Trong FastAPI

Ví dụ hàm kiểm tra role:

```python
from fastapi import Depends, HTTPException, status

def require_roles(*allowed_roles: str):
    def checker(current_user = Depends(get_current_user)):
        if not current_user.get("is_active"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tài khoản đã bị vô hiệu hóa",
            )

        if current_user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền thực hiện chức năng này",
            )

        return current_user

    return checker
```

Ví dụ route chỉ cho Admin và Staff tạo dịch vụ:

```python
@router.post("/services")
async def create_service(
    payload: ServiceCreate,
    current_user = Depends(require_roles("admin", "staff")),
):
    return service_service.create_service(payload)
```

Ví dụ route chỉ cho Doctor tạo hồ sơ điều trị:

```python
@router.post("/medical-records")
async def create_medical_record(
    payload: MedicalRecordCreate,
    current_user = Depends(require_roles("doctor")),
):
    return medical_record_service.create_record(payload, current_user)
```

## Cấu Trúc API

API base URL khi chạy local:

```text
http://localhost:8000/api/v1
```

Các nhóm API chính:

| Nhóm | Prefix | Mục đích |
| --- | --- | --- |
| Auth | `/api/v1/auth` | Đăng ký, đăng nhập, lấy thông tin user hiện tại |
| Users | `/api/v1/users` | Quản lý người dùng |
| Patients | `/api/v1/patients` | Quản lý bệnh nhân |
| Doctors | `/api/v1/doctors` | Quản lý bác sĩ |
| Services | `/api/v1/services` | Quản lý dịch vụ và giá |
| Appointments | `/api/v1/appointments` | Quản lý lịch hẹn |
| Medical Records | `/api/v1/medical-records` | Quản lý hồ sơ điều trị |

## Danh Sách Endpoint Đề Xuất

### Auth API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `POST` | `/auth/register` | Public | Đăng ký tài khoản patient |
| `POST` | `/auth/login` | Public | Đăng nhập |
| `GET` | `/auth/me` | Đã đăng nhập | Lấy thông tin user hiện tại |
| `POST` | `/auth/logout` | Đã đăng nhập | Đăng xuất |

### Users API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `GET` | `/users` | Admin | Lấy danh sách user |
| `POST` | `/users` | Admin | Tạo user |
| `GET` | `/users/{user_id}` | Admin | Xem chi tiết user |
| `PATCH` | `/users/{user_id}` | Admin | Cập nhật user |
| `PATCH` | `/users/{user_id}/role` | Admin | Đổi role |
| `DELETE` | `/users/{user_id}` | Admin | Vô hiệu hóa user |

### Patients API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `GET` | `/patients` | Admin, Staff | Lấy danh sách bệnh nhân |
| `POST` | `/patients` | Admin, Staff | Tạo hồ sơ bệnh nhân |
| `GET` | `/patients/{patient_id}` | Admin, Staff, Doctor liên quan, Patient chủ sở hữu | Xem chi tiết bệnh nhân |
| `PATCH` | `/patients/{patient_id}` | Admin, Staff, Patient chủ sở hữu | Cập nhật bệnh nhân |

### Services API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `GET` | `/services` | Đã đăng nhập | Lấy danh sách dịch vụ |
| `POST` | `/services` | Admin, Staff | Tạo dịch vụ |
| `PATCH` | `/services/{service_id}` | Admin, Staff | Cập nhật dịch vụ hoặc giá |
| `DELETE` | `/services/{service_id}` | Admin, Staff | Ngừng sử dụng dịch vụ |

### Appointments API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `GET` | `/appointments` | Admin, Staff | Lấy toàn bộ lịch hẹn |
| `POST` | `/appointments` | Admin, Staff, Patient | Tạo lịch hẹn |
| `GET` | `/appointments/my` | Doctor, Patient | Lấy lịch hẹn của chính mình |
| `GET` | `/appointments/{appointment_id}` | Người có quyền | Xem chi tiết lịch hẹn |
| `PATCH` | `/appointments/{appointment_id}` | Admin, Staff | Dời lịch hoặc sửa lịch |
| `PATCH` | `/appointments/{appointment_id}/status` | Admin, Staff, Doctor | Cập nhật trạng thái |
| `DELETE` | `/appointments/{appointment_id}` | Admin, Staff, Patient chủ sở hữu | Hủy lịch |

### Medical Records API

| Method | Endpoint | Quyền | Mô tả |
| --- | --- | --- | --- |
| `GET` | `/medical-records` | Admin, Doctor | Lấy danh sách hồ sơ điều trị |
| `POST` | `/medical-records` | Doctor | Tạo hồ sơ điều trị |
| `GET` | `/medical-records/{record_id}` | Người có quyền | Xem chi tiết hồ sơ |
| `PATCH` | `/medical-records/{record_id}` | Doctor tạo hồ sơ | Cập nhật hồ sơ |

## Ví Dụ API Thực Tế

Các ví dụ dưới đây dùng base URL:

```text
http://localhost:8000/api/v1
```

## Đăng Ký Tài Khoản Patient

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

## Đăng Nhập

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

## Lấy Thông Tin User Hiện Tại

Request:

```bash
curl -X GET "http://localhost:8000/api/v1/auth/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Response:

```json
{
  "id": "97f8c930-4f36-4404-8901-3e8b02aa01c6",
  "email": "staff@example.com",
  "full_name": "Clinic Staff",
  "phone": "0900000000",
  "role": "staff",
  "is_active": true
}
```

## Tạo Dịch Vụ Nha Khoa

Chỉ `admin` và `staff` được gọi API này.

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/services" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cao voi rang",
    "description": "Lam sach cao rang va kiem tra ve sinh rang mieng",
    "duration_minutes": 30,
    "price": 300000
  }'
```

Response:

```json
{
  "id": "c57a49d5-2eec-407b-9e9e-41fa5c7c6f6d",
  "name": "Cao voi rang",
  "description": "Lam sach cao rang va kiem tra ve sinh rang mieng",
  "duration_minutes": 30,
  "price": 300000,
  "is_active": true
}
```

## Lấy Danh Sách Dịch Vụ

Request:

```bash
curl -X GET "http://localhost:8000/api/v1/services" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Response:

```json
[
  {
    "id": "c57a49d5-2eec-407b-9e9e-41fa5c7c6f6d",
    "name": "Cao voi rang",
    "duration_minutes": 30,
    "price": 300000,
    "is_active": true
  },
  {
    "id": "6d23a365-e2cd-4b83-9d2f-7cde1cc4f456",
    "name": "Tram rang",
    "duration_minutes": 45,
    "price": 500000,
    "is_active": true
  }
]
```

## Đặt Lịch Hẹn

`patient` chỉ được đặt lịch cho chính mình. `staff` và `admin` có thể đặt lịch thay bệnh nhân.

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
    "reason": "Dau rang ham duoi ben phai"
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
  "reason": "Dau rang ham duoi ben phai"
}
```

## Cập Nhật Trạng Thái Lịch Hẹn

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

## Tạo Hồ Sơ Điều Trị

Chỉ `doctor` được tạo hồ sơ điều trị.

Request:

```bash
curl -X POST "http://localhost:8000/api/v1/medical-records" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": "ad4cf0f4-7c3a-4be4-a8da-d6f690975337",
    "patient_id": "4b9f7060-4cf4-49c2-b515-5e14d09f5f20",
    "doctor_id": "f80ec2dc-e97d-4f9a-a0be-860e3e620908",
    "diagnosis": "Sau rang",
    "treatment": "Lam sach lo sau va tram composite",
    "prescription": "Ibuprofen 400mg khi dau",
    "notes": "Khong an do cung trong 24 gio",
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
  "diagnosis": "Sau rang",
  "treatment": "Lam sach lo sau va tram composite",
  "prescription": "Ibuprofen 400mg khi dau",
  "notes": "Khong an do cung trong 24 gio",
  "follow_up_date": "2026-05-24",
  "created_at": "2026-05-03T15:25:00Z"
}
```

## Format Lỗi API

Backend nên trả lỗi theo format thống nhất:

```json
{
  "detail": {
    "code": "FORBIDDEN",
    "message": "Bạn không có quyền thực hiện chức năng này"
  }
}
```

Các HTTP status thường dùng:

| Status | Ý nghĩa |
| --- | --- |
| `200` | Thành công |
| `201` | Tạo mới thành công |
| `400` | Request sai |
| `401` | Chưa đăng nhập hoặc token không hợp lệ |
| `403` | Không có quyền |
| `404` | Không tìm thấy dữ liệu |
| `409` | Xung đột dữ liệu, ví dụ trùng lịch |
| `422` | Lỗi validate dữ liệu |
| `500` | Lỗi server |

## Cài Đặt Môi Trường Phát Triển

## Phần Mềm Cần Có

Cần cài:

- Flutter SDK.
- Dart SDK, đi kèm Flutter.
- Python 3.11 hoặc mới hơn.
- Git.
- Tài khoản Supabase.
- VS Code hoặc Android Studio.
- Android Studio Emulator nếu chạy mobile Android.

Kiểm tra phiên bản:

```bash
flutter --version
python --version
git --version
```

## Cài Đặt Supabase

Các bước:

1. Truy cập Supabase và tạo project mới.
2. Mở SQL Editor.
3. Chạy SQL schema ở phần trên.
4. Vào Project Settings để lấy `SUPABASE_URL`.
5. Lấy `SUPABASE_ANON_KEY`.
6. Lấy `SUPABASE_SERVICE_ROLE_KEY`.
7. Tạo file `.env` trong backend.

File môi trường mẫu:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
JWT_SECRET_KEY=replace-this-with-a-long-random-secret
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

Lưu ý bảo mật:

- Không commit file `.env`.
- Chỉ commit `.env.example`.
- Không đưa `SUPABASE_SERVICE_ROLE_KEY` vào Flutter.
- Service role key chỉ được dùng ở backend.
- Khi deploy production phải dùng HTTPS.

## Cách Chạy Backend FastAPI

Backend nằm trong thư mục:

```text
Backend
```

## Bước 1: Tạo Virtual Environment

Windows PowerShell:

```bash
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

macOS hoặc Linux:

```bash
cd Backend
python3 -m venv .venv
source .venv/bin/activate
```

## Bước 2: Tạo `requirements.txt`

Nội dung đề xuất:

```txt
fastapi
uvicorn[standard]
python-dotenv
pydantic
supabase
python-jose[cryptography]
passlib[bcrypt]
pytest
httpx
```

Cài dependencies:

```bash
pip install -r requirements.txt
```

## Bước 3: Tạo File FastAPI Chính

Tạo file:

```text
Backend/app/main.py
```

Code mẫu:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Dental Clinic Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:53365",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok"}
```

## Bước 4: Chạy Backend

Từ thư mục `Backend`:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Kiểm tra API:

```text
http://localhost:8000/health
```

Mở Swagger Docs:

```text
http://localhost:8000/docs
```

Swagger Docs giúp test API trực tiếp trên trình duyệt, rất hữu ích cho người mới bắt đầu.

## Cách Chạy Frontend Flutter

Frontend nằm trong thư mục:

```text
flutter_application_1
```

## Bước 1: Cài Dependencies

```bash
cd flutter_application_1
flutter pub get
```

## Bước 2: Chạy Flutter Web

```bash
flutter run -d chrome
```

## Bước 3: Chạy Android Emulator

Xem danh sách thiết bị:

```bash
flutter devices
```

Chạy app:

```bash
flutter run -d emulator-5554
```

Thay `emulator-5554` bằng device ID thực tế trên máy.

## Cấu Hình API Base URL Trong Flutter

Tạo file:

```text
flutter_application_1/lib/core/constants/api_constants.dart
```

Nếu chạy Flutter Web:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
}
```

Nếu chạy Android Emulator:

```dart
class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
}
```

Giải thích:

- `localhost` trên web là máy tính hiện tại.
- `localhost` trong Android Emulator là chính emulator.
- `10.0.2.2` là địa chỉ để emulator gọi về máy tính host.

## Luồng Phát Triển Tính Năng

Khi làm một chức năng mới, nên đi theo thứ tự:

```text
Database -> Backend API -> Test API -> Flutter UI -> Test UI
```

Ví dụ chức năng đặt lịch:

1. Tạo bảng `appointments`.
2. Tạo schema `AppointmentCreate`.
3. Tạo endpoint `POST /appointments`.
4. Kiểm tra role.
5. Kiểm tra bác sĩ có bị trùng lịch không.
6. Test bằng Swagger hoặc curl.
7. Tạo Flutter model `AppointmentModel`.
8. Tạo `AppointmentApi`.
9. Tạo màn hình đặt lịch.
10. Gọi API từ Flutter.
11. Hiển thị kết quả cho người dùng.

## Quy Trình Làm Việc Với Git

Tạo branch mới cho từng chức năng:

```bash
git checkout -b feature/appointment-booking
```

Ví dụ tên branch:

```text
feature/auth-login
feature/admin-users
feature/staff-appointments
feature/doctor-medical-records
fix/appointment-status-validation
```

Trước khi merge:

- Code chạy được.
- Không có lỗi phân tích Flutter.
- Backend endpoint test được.
- Không commit file `.env`.
- Không commit key Supabase thật.
- API response không thay đổi bất ngờ.
- Đã kiểm tra quyền của từng role.

## Quy Ước Code Backend

Nên tách backend theo trách nhiệm:

- `routers/`: khai báo endpoint.
- `schemas/`: Pydantic model cho request và response.
- `services/`: xử lý nghiệp vụ.
- `core/`: config, security, RBAC.
- `db/`: kết nối Supabase.

Không nên viết tất cả code vào một file `main.py` khi dự án lớn dần.

Ví dụ:

```text
Request vào /appointments
    |
appointments.py trong routers nhận request
    |
AppointmentCreate trong schemas validate dữ liệu
    |
appointment_service.py xử lý nghiệp vụ
    |
supabase.py ghi dữ liệu vào database
```

## Quy Ước Code Flutter

Nên tách frontend theo feature:

```text
features/auth
features/admin
features/staff
features/doctor
features/patient
```

Mỗi feature nên có:

```text
screens/
widgets/
providers/
```

Tầng gọi API nên để trong:

```text
data/api
data/repositories
data/models
```

Ví dụ luồng Flutter:

```text
BookingScreen
    |
AppointmentRepository
    |
AppointmentApi
    |
ApiClient
    |
FastAPI Backend
```

## Chia Việc Cho Nhóm 2 Người

Dự án này phù hợp chia cho 2 người:

- Người 1: Backend + Database.
- Người 2: Flutter Frontend.

Hai người cần thống nhất API contract trước khi code UI.

## Người 1: Backend + Database

Trách nhiệm chính:

- Thiết kế database trên Supabase.
- Viết SQL tạo bảng.
- Viết FastAPI backend.
- Tạo API đăng nhập, đăng ký.
- Tạo middleware hoặc dependency kiểm tra token.
- Tạo RBAC.
- Viết API cho users, patients, doctors, services, appointments, medical_records.
- Test API bằng Swagger hoặc curl.
- Viết tài liệu API.

Danh sách task đề xuất:

| Thứ tự | Công việc | Kết quả |
| --- | --- | --- |
| 1 | Thiết kế database | Có SQL schema chạy được |
| 2 | Cấu hình Supabase | Backend kết nối được database |
| 3 | Auth API | Register, login, me |
| 4 | RBAC | Có `require_roles()` |
| 5 | Users API | Admin quản lý user |
| 6 | Services API | Staff quản lý dịch vụ, giá |
| 7 | Patients API | Staff quản lý bệnh nhân |
| 8 | Appointments API | Đặt lịch, sửa lịch, hủy lịch |
| 9 | Medical Records API | Doctor tạo hồ sơ điều trị |
| 10 | Testing | Test các luồng chính |

## Người 2: Flutter Frontend

Trách nhiệm chính:

- Xây dựng giao diện Flutter.
- Tạo routing.
- Tạo theme.
- Tạo màn hình đăng nhập, đăng ký.
- Lưu token sau khi login.
- Gọi API backend.
- Xây dựng dashboard theo role.
- Xây dựng màn hình cho Admin, Staff, Doctor, Patient.
- Test trên web và mobile.

Danh sách task đề xuất:

| Thứ tự | Công việc | Kết quả |
| --- | --- | --- |
| 1 | Cấu trúc Flutter | Có thư mục feature rõ ràng |
| 2 | Auth UI | Login, register |
| 3 | API Client | Gửi request kèm token |
| 4 | Role Navigation | Login xong vào đúng dashboard |
| 5 | Patient UI | Đặt lịch, xem lịch |
| 6 | Staff UI | Quản lý bệnh nhân, lịch hẹn, dịch vụ |
| 7 | Doctor UI | Xem lịch, tạo hồ sơ điều trị |
| 8 | Admin UI | Quản lý users và roles |
| 9 | Testing | Kiểm tra web và mobile |

## Công Việc Cần Làm Chung

Hai người cần cùng thống nhất:

- Tên endpoint.
- Request body.
- Response body.
- Format lỗi.
- Danh sách role.
- Trạng thái lịch hẹn.
- Quy tắc bệnh nhân hủy lịch.
- Quy tắc bác sĩ tạo hồ sơ điều trị.
- Quy tắc trùng lịch.

## Kế Hoạch 4 Tuần Đề Xuất

| Tuần | Backend + Database | Flutter Frontend |
| --- | --- | --- |
| Tuần 1 | Tạo database, auth, RBAC | App shell, routing, theme, login UI |
| Tuần 2 | Users, patients, services API | Login thật, màn hình services, patients |
| Tuần 3 | Appointments API, kiểm tra trùng lịch | Booking flow, staff appointment screen |
| Tuần 4 | Medical records, test, sửa lỗi | Doctor screen, admin screen, test cuối |

## Kiểm Thử Backend

Nên dùng:

- `pytest`
- `TestClient` của FastAPI

Ví dụ test health check:

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

Các case backend cần test:

- Patient đăng ký được.
- User đăng nhập được.
- Staff tạo dịch vụ được.
- Patient không tạo dịch vụ được.
- Patient đặt lịch cho chính mình được.
- Patient không đặt lịch cho người khác.
- Staff xác nhận lịch được.
- Doctor xem lịch của mình được.
- Doctor tạo hồ sơ điều trị cho lịch được giao.
- Doctor không tạo hồ sơ cho lịch của bác sĩ khác.

## Kiểm Thử Flutter

Chạy:

```bash
cd flutter_application_1
flutter analyze
flutter test
```

Các case frontend cần test:

- Form login báo lỗi khi bỏ trống email hoặc password.
- Đăng nhập thành công chuyển đúng dashboard theo role.
- Patient đặt lịch phải chọn đủ dịch vụ, bác sĩ, ngày, giờ.
- Staff nhập giá dịch vụ phải là số hợp lệ.
- Doctor tạo hồ sơ điều trị phải có chẩn đoán và điều trị.
- Giao diện hiển thị đúng trên web và mobile.

## Build Và Deploy

## Deploy Backend

FastAPI backend có thể deploy lên:

- Render.
- Railway.
- Fly.io.
- Azure App Service.
- AWS.
- VPS dùng Docker.

Lệnh chạy production cơ bản:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Khi deploy thật nên dùng:

- Biến môi trường thay vì file `.env`.
- HTTPS.
- CORS giới hạn domain frontend thật.
- Logging.
- Backup database.

## Build Flutter Web

```bash
cd flutter_application_1
flutter build web
```

File build nằm ở:

```text
flutter_application_1/build/web
```

Có thể deploy Flutter Web lên:

- Firebase Hosting.
- Netlify.
- Vercel.
- Supabase Storage.
- Static hosting bất kỳ.

## Build Android

```bash
cd flutter_application_1
flutter build apk --release
```

File APK nằm trong thư mục build của Flutter.

## Build iOS

Cần macOS và Xcode:

```bash
flutter build ios --release
```

## Ghi Chú Bảo Mật

Vì hệ thống có dữ liệu bệnh nhân và hồ sơ điều trị, cần chú ý:

- Không lưu password dạng plain text.
- Không expose service role key.
- Không để patient xem dữ liệu của patient khác.
- Không để staff tạo hoặc sửa hồ sơ điều trị chuyên môn.
- Không để doctor xem toàn bộ dữ liệu nếu không cần.
- Mọi endpoint quan trọng phải kiểm tra token và role.
- Nên bật HTTPS khi deploy.
- Nên có audit log cho thao tác đổi role, hủy lịch, sửa giá, tạo bệnh án.
- Nên backup database định kỳ.

## Thứ Tự Làm Dự Án Cho Người Mới

Nếu mới bắt đầu, nên làm theo thứ tự này:

1. Tạo Supabase project.
2. Tạo các bảng database.
3. Tạo FastAPI health check.
4. Kết nối backend với Supabase.
5. Làm đăng ký và đăng nhập.
6. Làm kiểm tra token.
7. Làm phân quyền role.
8. Làm màn hình login Flutter.
9. Làm dashboard theo role.
10. Làm API dịch vụ.
11. Làm màn hình danh sách dịch vụ.
12. Làm API bệnh nhân.
13. Làm màn hình quản lý bệnh nhân.
14. Làm API đặt lịch.
15. Làm màn hình đặt lịch.
16. Làm màn hình staff quản lý lịch hẹn.
17. Làm màn hình doctor xem lịch.
18. Làm API hồ sơ điều trị.
19. Làm màn hình doctor tạo hồ sơ điều trị.
20. Làm admin quản lý user.
21. Test toàn bộ luồng.
22. Build và deploy.

## Definition Of Done

Một chức năng được xem là hoàn thành khi:

- Database có bảng hoặc cột cần thiết.
- Backend có endpoint hoạt động.
- Backend validate dữ liệu đầu vào.
- Backend kiểm tra token.
- Backend kiểm tra role.
- API có response rõ ràng.
- Flutter gọi được API.
- Flutter có loading state.
- Flutter có error state.
- Người dùng đúng role dùng được.
- Người dùng sai role bị chặn.
- Có test cơ bản hoặc đã test thủ công bằng Swagger/curl.

## Kết Luận

Dự án này nên được xây dựng theo hướng rõ ràng, dễ mở rộng và dễ bảo trì:

- Flutter chỉ tập trung vào giao diện và trải nghiệm người dùng.
- FastAPI xử lý nghiệp vụ và phân quyền.
- Supabase PostgreSQL lưu dữ liệu có cấu trúc.
- RBAC phải được kiểm tra ở backend.
- API contract phải thống nhất trước khi frontend gọi.

Nếu làm đúng cấu trúc từ đầu, nhóm 2 người có thể phát triển hệ thống theo từng module mà không bị rối khi dự án lớn dần.
