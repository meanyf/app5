from pydantic import BaseModel


class SendOTPRequest(BaseModel):
    phone: str


class SendOTPResponse(BaseModel):
    message: str


class VerifyOTPRequest(BaseModel):
    phone: str
    code: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
