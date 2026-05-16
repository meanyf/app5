# auth.py

from pydantic import BaseModel, field_validator
import re


class SendOtpRequest(BaseModel):
    phone: str

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Приводим к формату 7XXXXXXXXXX (для СМС.ру)
        cleaned = re.sub(r"\D", "", v)
        if cleaned.startswith("8") and len(cleaned) == 11:
            cleaned = "7" + cleaned[1:]
        if not re.fullmatch(r"7\d{10}", cleaned):
            raise ValueError("Неверный формат номера телефона. Ожидается российский номер.")
        return cleaned


class VerifyOtpRequest(BaseModel):
    phone: str
    code: str

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"\D", "", v)
        if cleaned.startswith("8") and len(cleaned) == 11:
            cleaned = "7" + cleaned[1:]
        if not re.fullmatch(r"7\d{10}", cleaned):
            raise ValueError("Неверный формат номера телефона.")
        return cleaned


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"