from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import extract, and_, func
from typing import List, Optional
from uuid import UUID
from datetime import datetime, date

from db import get_db
from models.user import User
from models.doctor import Doctor
from models.booking import Booking
from models.doctor_work_schedule import DoctorWorkSchedule
from models.work_shift import WorkShift
from models.salary import (
    SalaryConfig,
    SalaryShiftCoefficient,
    SalaryComplexityCoefficient,
    SalarySlip
)
from schemas.salary import (
    SalaryConfigCreate,
    SalaryConfigResponse,
    SalaryShiftCoefficientCreate,
    SalaryShiftCoefficientResponse,
    SalaryComplexityCoefficientCreate,
    SalaryComplexityCoefficientResponse,
    SalarySlipCreate,
    SalarySlipResponse,
    MonthlySalaryReportResponse,
    YearlyDoctorSalaryReportResponse,
    YearlyAllDoctorSalaryReportResponse,
    DoctorSalaryReportItem,
    YearlyDoctorSalaryReportItem
)
from dependencies import get_current_user, get_current_admin

router = APIRouter(
    prefix="/salary",
    tags=["Salary"]
)


# ==========================================
# 1. ADMIN - THIẾT LẬP THAM SỐ LƯƠNG
# ==========================================

@router.get("/configs", response_model=List[SalaryConfigResponse])
def get_salary_configs(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    configs = db.query(SalaryConfig).order_by(SalaryConfig.effective_date.desc()).all()
    # Seed default base rate if empty
    if not configs:
        default_config = SalaryConfig(
            base_salary_per_hour=200000.0,
            effective_date=date(2026, 1, 1)
        )
        db.add(default_config)
        db.commit()
        db.refresh(default_config)
        configs = [default_config]
    return configs


@router.post("/configs", response_model=SalaryConfigResponse)
def create_salary_config(
    payload: SalaryConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    new_config = SalaryConfig(
        base_salary_per_hour=payload.base_salary_per_hour,
        effective_date=payload.effective_date
    )
    db.add(new_config)
    db.commit()
    db.refresh(new_config)
    return new_config


@router.get("/shifts", response_model=List[SalaryShiftCoefficientResponse])
def get_shift_coefficients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    coeffs = db.query(SalaryShiftCoefficient).all()
    # Seed default shift coefficients if empty
    if not coeffs:
        defaults = [
            SalaryShiftCoefficient(shift_name="Ca sáng", coefficient=1.0),
            SalaryShiftCoefficient(shift_name="Ca chiều", coefficient=1.2),
            SalaryShiftCoefficient(shift_name="Ca tối", coefficient=1.5),
            SalaryShiftCoefficient(shift_name="Thứ 7", coefficient=1.3),
            SalaryShiftCoefficient(shift_name="Chủ nhật", coefficient=1.5),
        ]
        db.add_all(defaults)
        db.commit()
        coeffs = db.query(SalaryShiftCoefficient).all()
    return coeffs


@router.post("/shifts", response_model=SalaryShiftCoefficientResponse)
def create_shift_coefficient(
    payload: SalaryShiftCoefficientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    # Check if duplicate
    existing = db.query(SalaryShiftCoefficient).filter(
        SalaryShiftCoefficient.shift_name.ilike(payload.shift_name)
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Tên ca/ngày làm việc này đã được thiết lập hệ số"
        )
    new_coeff = SalaryShiftCoefficient(
        shift_name=payload.shift_name,
        coefficient=payload.coefficient
    )
    db.add(new_coeff)
    db.commit()
    db.refresh(new_coeff)
    return new_coeff


@router.put("/shifts/{coeff_id}", response_model=SalaryShiftCoefficientResponse)
def update_shift_coefficient(
    coeff_id: int,
    payload: SalaryShiftCoefficientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    coeff = db.query(SalaryShiftCoefficient).filter(SalaryShiftCoefficient.id == coeff_id).first()
    if not coeff:
        raise HTTPException(status_code=404, detail="Không tìm thấy hệ số ca làm việc")
    coeff.shift_name = payload.shift_name
    coeff.coefficient = payload.coefficient
    db.commit()
    db.refresh(coeff)
    return coeff


@router.delete("/shifts/{coeff_id}")
def delete_shift_coefficient(
    coeff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    coeff = db.query(SalaryShiftCoefficient).filter(SalaryShiftCoefficient.id == coeff_id).first()
    if not coeff:
        raise HTTPException(status_code=404, detail="Không tìm thấy hệ số ca làm việc")
    db.delete(coeff)
    db.commit()
    return {"message": "Đã xóa hệ số ca làm việc thành công"}


@router.get("/complexities", response_model=List[SalaryComplexityCoefficientResponse])
def get_complexity_coefficients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    coeffs = db.query(SalaryComplexityCoefficient).all()
    # Seed default complexity coefficients if empty
    if not coeffs:
        defaults = [
            SalaryComplexityCoefficient(complexity_level="Thông thường", coefficient=0.0),
            SalaryComplexityCoefficient(complexity_level="Khó", coefficient=0.1),
            SalaryComplexityCoefficient(complexity_level="Khó vừa", coefficient=0.3),
            SalaryComplexityCoefficient(complexity_level="Rất khó", coefficient=0.5),
        ]
        db.add_all(defaults)
        db.commit()
        coeffs = db.query(SalaryComplexityCoefficient).all()
    return coeffs


@router.post("/complexities", response_model=SalaryComplexityCoefficientResponse)
def create_complexity_coefficient(
    payload: SalaryComplexityCoefficientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    existing = db.query(SalaryComplexityCoefficient).filter(
        SalaryComplexityCoefficient.complexity_level.ilike(payload.complexity_level)
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Mức độ phức tạp này đã được thiết lập hệ số"
        )
    new_coeff = SalaryComplexityCoefficient(
        complexity_level=payload.complexity_level,
        coefficient=payload.coefficient
    )
    db.add(new_coeff)
    db.commit()
    db.refresh(new_coeff)
    return new_coeff


@router.put("/complexities/{coeff_id}", response_model=SalaryComplexityCoefficientResponse)
def update_complexity_coefficient(
    coeff_id: int,
    payload: SalaryComplexityCoefficientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    coeff = db.query(SalaryComplexityCoefficient).filter(SalaryComplexityCoefficient.id == coeff_id).first()
    if not coeff:
        raise HTTPException(status_code=404, detail="Không tìm thấy hệ số ca phức tạp")
    coeff.complexity_level = payload.complexity_level
    coeff.coefficient = payload.coefficient
    db.commit()
    db.refresh(coeff)
    return coeff


@router.delete("/complexities/{coeff_id}")
def delete_complexity_coefficient(
    coeff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    coeff = db.query(SalaryComplexityCoefficient).filter(SalaryComplexityCoefficient.id == coeff_id).first()
    if not coeff:
        raise HTTPException(status_code=404, detail="Không tìm thấy hệ số ca phức tạp")
    db.delete(coeff)
    db.commit()
    return {"message": "Đã xóa hệ số ca phức tạp thành công"}


# ==========================================
# 2. STAFF - TÍNH TOÁN & LẬP PHIẾU LƯƠNG
# ==========================================

def calculate_salary_details(doctor: Doctor, month: int, year: int, db: Session):
    # Find active hourly rate
    # Look for SalaryConfig effective on or before the first day of that month/year
    target_date = date(year, month, 1)
    config = db.query(SalaryConfig).filter(
        SalaryConfig.effective_date <= target_date
    ).order_by(SalaryConfig.effective_date.desc()).first()
    
    base_rate = config.base_salary_per_hour if config else 200000.0

    # Get shift coefficients
    shifts_list = db.query(SalaryShiftCoefficient).all()
    shift_coeffs = {s.shift_name.lower(): s.coefficient for s in shifts_list}
    
    # Get complexity coefficients
    complexities_list = db.query(SalaryComplexityCoefficient).all()
    complexity_coeffs = {c.complexity_level.lower(): c.coefficient for c in complexities_list}

    # Fetch doctor schedules
    schedules = db.query(DoctorWorkSchedule).join(WorkShift).filter(
        DoctorWorkSchedule.doctor_id == doctor.id,
        extract('month', DoctorWorkSchedule.work_date) == month,
        extract('year', DoctorWorkSchedule.work_date) == year
    ).all()

    # Fetch all completed bookings in this month for this doctor
    date_prefix = f"{year}-{month:02d}-"
    bookings = db.query(Booking).filter(
        Booking.doctor_id == doctor.id,
        Booking.status == "completed",
        Booking.booking_date.like(f"{date_prefix}%")
    ).all()

    total_shifts = len(schedules)
    total_hours = 0.0
    total_complexity_coef = 0.0
    total_salary = 0.0

    for sched in schedules:
        shift = db.query(WorkShift).filter(WorkShift.id == sched.work_shift_id).first()
        if not shift:
            continue
        # 1. Hours duration
        t1 = datetime.combine(date.today(), shift.start_time)
        t2 = datetime.combine(date.today(), shift.end_time)
        duration_hours = (t2 - t1).seconds / 3600.0
        total_hours += duration_hours

        # 2. Day & Shift coefficient
        weekday = sched.work_date.weekday()
        if weekday == 5: # Saturday
            shift_coef = shift_coeffs.get("thứ 7", 1.3)
        elif weekday == 6: # Sunday
            shift_coef = shift_coeffs.get("chủ nhật", 1.5)
        else: # Weekday, match by shift name
            # match substring e.g. "sáng", "chiều", "tối"
            shift_name_lower = shift.shift_name.lower()
            if "sáng" in shift_name_lower:
                shift_coef = shift_coeffs.get("ca sáng", 1.0)
            elif "chiều" in shift_name_lower:
                shift_coef = shift_coeffs.get("ca chiều", 1.2)
            elif "tối" in shift_name_lower:
                shift_coef = shift_coeffs.get("ca tối", 1.5)
            else:
                shift_coef = 1.0

        # 3. Sum complexity level coefficients of completed patients treated in this shift
        sum_complexity_shift = 0.0
        
        # Match bookings on this day and during this shift
        sched_date_str = sched.work_date.strftime("%Y-%m-%d")
        for b in bookings:
            if b.booking_date == sched_date_str:
                # Check if booking belongs to this shift
                shift_words = set(shift.shift_name.lower().split())
                slot_words = set(b.time_slot.lower().split())
                
                # Check word overlap to match shifts
                is_match = False
                if len(shift_words.intersection(slot_words)) >= 2:
                    is_match = True
                elif "sáng" in shift_words and "sáng" in slot_words:
                    is_match = True
                elif "chiều" in shift_words and "chiều" in slot_words:
                    is_match = True
                elif "tối" in shift_words and "tối" in slot_words:
                    is_match = True
                
                if is_match:
                    comp_level = (b.complexity_level or "Thông thường").lower()
                    coef = complexity_coeffs.get(comp_level, 0.0)
                    sum_complexity_shift += coef
                    total_complexity_coef += coef

        # 4. Ca salary
        # Số_giờ_quy_đổi = Số_giờ_mỗi_ca × (Hệ_số_ca_làm_việc + Tổng_hệ_số_bệnh_nhân)
        converted_hours = duration_hours * (shift_coef + sum_complexity_shift)
        # Tiền_ca = Số_giờ_quy_đổi × Hệ_số_bác_sĩ × Tiền_một_giờ
        ca_salary = converted_hours * (doctor.salary_coefficient or 1.0) * base_rate
        total_salary += ca_salary

    return {
        "base_rate": base_rate,
        "doctor_coefficient": doctor.salary_coefficient or 1.0,
        "total_shifts": total_shifts,
        "total_hours": total_hours,
        "total_complexity_coef": total_complexity_coef,
        "total_salary": total_salary
    }


@router.get("/calculate", response_model=dict)
def calculate_doctor_salary(
    doctor_id: UUID,
    month: int,
    year: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin bác sĩ")
    
    details = calculate_salary_details(doctor, month, year, db)
    
    return {
        "doctor_id": doctor.id,
        "doctor_code": doctor.doctor_code,
        "full_name": doctor.full_name,
        "qualification": doctor.qualification,
        "salary_coefficient": doctor.salary_coefficient or 1.0,
        "month": month,
        "year": year,
        **details
    }


@router.post("/slips", response_model=SalarySlipResponse)
def create_salary_slip(
    payload: SalarySlipCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check permission (Staff or Admin)
    if current_user.role not in ["staff", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền lập phiếu lương"
        )

    # Check if duplicate slip already exists
    existing = db.query(SalarySlip).filter(
        SalarySlip.doctor_id == payload.doctor_id,
        SalarySlip.month == payload.month,
        SalarySlip.year == payload.year
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Bác sĩ đã có phiếu lương cho tháng {payload.month}/{payload.year}"
        )

    doctor = db.query(Doctor).filter(Doctor.id == payload.doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin bác sĩ")

    # Calculate actual values
    details = calculate_salary_details(doctor, payload.month, payload.year, db)

    new_slip = SalarySlip(
        doctor_id=payload.doctor_id,
        month=payload.month,
        year=payload.year,
        base_rate=details["base_rate"],
        doctor_coefficient=details["doctor_coefficient"],
        total_shifts=details["total_shifts"],
        total_hours=details["total_hours"],
        total_complexity_coef=details["total_complexity_coef"],
        total_salary=details["total_salary"],
        created_by=current_user.id
    )

    db.add(new_slip)
    db.commit()
    db.refresh(new_slip)
    return new_slip


@router.get("/slips", response_model=List[SalarySlipResponse])
def get_salary_slips(
    doctor_id: Optional[UUID] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(SalarySlip)
    if doctor_id:
        query = query.filter(SalarySlip.doctor_id == doctor_id)
    if month:
        query = query.filter(SalarySlip.month == month)
    if year:
        query = query.filter(SalarySlip.year == year)

    return query.order_by(SalarySlip.year.desc(), SalarySlip.month.desc()).all()


# ==========================================
# 3. ADMIN - BÁO CÁO DOANH THU & LƯƠNG
# ==========================================

# UC4.5: Báo cáo tiền lương tất cả bác sĩ trong 1 tháng
@router.get("/reports/monthly", response_model=MonthlySalaryReportResponse)
def get_monthly_all_doctors_report(
    month: int,
    year: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    doctors = db.query(Doctor).filter(Doctor.status == True).all()
    report_items = []
    
    for doc in doctors:
        # Check if saved slip exists first
        slip = db.query(SalarySlip).filter(
            SalarySlip.doctor_id == doc.id,
            SalarySlip.month == month,
            SalarySlip.year == year
        ).first()

        if slip:
            report_items.append(
                DoctorSalaryReportItem(
                    doctor_id=doc.id,
                    doctor_code=doc.doctor_code,
                    full_name=doc.full_name,
                    total_salary=slip.total_salary,
                    total_hours=slip.total_hours,
                    total_shifts=slip.total_shifts
                )
            )
        else:
            # Calculate dynamically
            details = calculate_salary_details(doc, month, year, db)
            report_items.append(
                DoctorSalaryReportItem(
                    doctor_id=doc.id,
                    doctor_code=doc.doctor_code,
                    full_name=doc.full_name,
                    total_salary=details["total_salary"],
                    total_hours=details["total_hours"],
                    total_shifts=details["total_shifts"]
                )
            )

    return MonthlySalaryReportResponse(
        month=month,
        year=year,
        items=report_items
    )


# UC4.6: Báo cáo tiền lương của một bác sĩ trong 1 năm
@router.get("/reports/yearly-doctor", response_model=YearlyDoctorSalaryReportResponse)
def get_yearly_doctor_report(
    doctor_id: UUID,
    year: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Không tìm thấy bác sĩ")

    months_data = []
    total_salary_year = 0.0

    for m in range(1, 13):
        slip = db.query(SalarySlip).filter(
            SalarySlip.doctor_id == doctor_id,
            SalarySlip.month == m,
            SalarySlip.year == year
        ).first()

        if slip:
            total_salary_year += slip.total_salary
            months_data.append(
                YearlyDoctorSalaryReportItem(
                    month=m,
                    total_salary=slip.total_salary,
                    total_hours=slip.total_hours,
                    total_shifts=slip.total_shifts
                )
            )
        else:
            details = calculate_salary_details(doctor, m, year, db)
            total_salary_year += details["total_salary"]
            months_data.append(
                YearlyDoctorSalaryReportItem(
                    month=m,
                    total_salary=details["total_salary"],
                    total_hours=details["total_hours"],
                    total_shifts=details["total_shifts"]
                )
            )

    average_salary = total_salary_year / 12.0

    return YearlyDoctorSalaryReportResponse(
        doctor_id=doctor.id,
        full_name=doctor.full_name,
        year=year,
        months=months_data,
        total_salary_year=total_salary_year,
        average_salary_month=average_salary
    )


# UC4.7: Báo cáo tiền lương tất cả bác sĩ trong 1 năm
@router.get("/reports/yearly-all", response_model=YearlyAllDoctorSalaryReportResponse)
def get_yearly_all_doctors_report(
    year: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    doctors = db.query(Doctor).filter(Doctor.status == True).all()
    report_items = []
    total_pool = 0.0

    for doc in doctors:
        doc_total_salary = 0.0
        doc_total_hours = 0.0
        doc_total_shifts = 0
        
        # Aggregate across 12 months
        for m in range(1, 13):
            slip = db.query(SalarySlip).filter(
                SalarySlip.doctor_id == doc.id,
                SalarySlip.month == m,
                SalarySlip.year == year
            ).first()

            if slip:
                doc_total_salary += slip.total_salary
                doc_total_hours += slip.total_hours
                doc_total_shifts += slip.total_shifts
            else:
                details = calculate_salary_details(doc, m, year, db)
                doc_total_salary += details["total_salary"]
                doc_total_hours += details["total_hours"]
                doc_total_shifts += details["total_shifts"]

        total_pool += doc_total_salary
        report_items.append(
            DoctorSalaryReportItem(
                doctor_id=doc.id,
                doctor_code=doc.doctor_code,
                full_name=doc.full_name,
                total_salary=doc_total_salary,
                total_hours=doc_total_hours,
                total_shifts=doc_total_shifts
            )
        )

    return YearlyAllDoctorSalaryReportResponse(
        year=year,
        total_pool=total_pool,
        items=report_items
    )
