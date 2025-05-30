from pydantic import BaseModel

class NoteRequest(BaseModel):
    content: str
    user_id: str
    title: str
    source: str
