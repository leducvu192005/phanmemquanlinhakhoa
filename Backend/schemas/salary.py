from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime, date


# ==========================================
# HOURLY RATE CONFIGS
# ==========================================
class SalaryConfigBase(BaseModel):
    base_salary_per_hour: float
    effective_date: date


class SalaryConfigCreate(SalaryConfigBase):
    pass


class SalaryConfigResponse(SalaryConfigBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ==========================================
# SHIFT COEFFICIENTS
# ==========================================
class SalaryShiftCoefficientBase(BaseModel):
    shift_name: str
    coefficient: float


class SalaryShiftCoefficientCreate(SalaryShiftCoefficientBase):
    pass


class SalaryShiftCoefficientResponse(SalaryShiftCoefficientBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ==========================================
# TREATMENT COMPLEXITY COEFFICIENTS
# ==========================================
class SalaryComplexityCoefficientBase(BaseModel):
    complexity_level: str
    coefficient: float


class SalaryComplexityCoefficientCreate(SalaryComplexityCoefficientBase):
    pass


class SalaryComplexityCoefficientResponse(SalaryComplexityCoefficientBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ==========================================
# SALARY SLIPS
# ==========================================
class SalarySlipCreate(BaseModel):
    doctor_id: UUID
    month: int
    year: int


class DoctorMin(BaseModel):
    id: UUID
    doctor_code: str
    full_name: str
    qualification: Optional[str] = None
    salary_coefficient: float


class UserMin(BaseModel):
    id: int
    username: str


class SalarySlipResponse(BaseModel):
    id: int
    doctor_id: UUID
    month: int
    year: int
    base_rate: float
    doctor_coefficient: float
    total_shifts: int
    total_hours: float
    total_complexity_coef: float
    total_salary: float
    created_at: datetime
    created_by: Optional[int] = None
    doctor: Optional[DoctorMin] = None
    creator: Optional[UserMin] = None

    class Config:
        from_attributes = True


# ==========================================
# REPORTS SCHEMAS
# ==========================================
class DoctorSalaryReportItem(BaseModel):
    doctor_id: UUID
    doctor_code: str
    full_name: str
    total_salary: float
    total_hours: float
    total_shifts: int


class MonthlySalaryReportResponse(BaseModel):
    month: int
    year: int
    items: List[DoctorSalaryReportItem]


class YearlyDoctorSalaryReportItem(BaseModel):
    month: int
    total_salary: float
    total_hours: float
    total_shifts: int


class YearlyDoctorSalaryReportResponse(BaseModel):
    doctor_id: UUID
    full_name: str
    year: int
    months: List[YearlyDoctorSalaryReportItem]
    total_salary_year: float
    average_salary_month: float


class YearlyAllDoctorSalaryReportResponse(BaseModel):
    year: int
    total_pool: float
    items: List[DoctorSalaryReportItem]
