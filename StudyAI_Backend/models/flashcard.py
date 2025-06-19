from pydantic import BaseModel
from typing import List, Optional

class Flashcard(BaseModel):
    question: str
    answer: str
    id: Optional[str] = None

class FlashcardSet(BaseModel):
    name: str
    user_id: str
    note_id: Optional[str] = None
    note_title: Optional[str] = None
    flashcards: List[Flashcard]
    created_at: Optional[str] = None
    id: Optional[str] = None

class FlashcardGenerationRequest(BaseModel):
    content: str
    user_id: str
    set_name: str
    note_id: Optional[str] = None
    note_title: Optional[str] = None 