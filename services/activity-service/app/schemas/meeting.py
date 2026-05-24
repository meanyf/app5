# meeting.py

from pydantic import BaseModel, field_validator
from datetime import datetime

class MeetingRequestCreate(BaseModel):
    activity_id: str

class MeetingRequestRead(BaseModel):
    id: str
    activity_id: str
    user_id: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}

    @field_validator('activity_id', mode='before')
    @classmethod
    def uuid_to_str(cls, v):
        return str(v)

class MeetingRequestUpdate(BaseModel):
    status: str