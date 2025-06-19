# main.py
"""
FastAPI entry-point for StudyAI backend.
• One Bart model instance shared via app.state
• Endpoints: raw text, PDF, images, delete, flashcards
"""
from __future__ import annotations

import os
from typing import Any, Dict, List

from fastapi import (
    Body,
    FastAPI,
    File,
    Form,
    HTTPException,
    Request,
    UploadFile,
)
from fastapi.middleware.cors import CORSMiddleware
from models.note import NoteRequest
from models.flashcard import FlashcardGenerationRequest, Flashcard
from services.summarizer_service import SummarizerService
from services.flashcard_service import FlashcardService
from services.parser import extract_text_from_image
from services.pdf_parser import extract_text_from_pdf
from firebase import (
    delete_summary_and_note, 
    save_note_to_firestore,
    save_flashcard_set_to_firestore,
    get_user_flashcard_sets,
    get_flashcard_set,
    delete_flashcard_set,
    update_flashcard_set
)
from utils.auto_google_creds import ensure_google_credentials

# ---------- bootstrap ---------- #
ensure_google_credentials()

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def load_model() -> None:
    app.state.summarizer = SummarizerService()
    app.state.flashcard_service = FlashcardService(app.state.summarizer)


# ---------- helper ---------- #
async def _process_and_save(
    *,
    request: Request,
    content: str,
    user_id: str,
    title: str,
    source: str,
    summary_type: str,
) -> Dict[str, Any]:
    if not content.strip():
        return {"error": "Content is empty.", "success": False}

    svc: SummarizerService = request.app.state.summarizer
    summary = await svc.summarize(content, academic=True)

    if len(summary.strip()) < 10:
        return {"error": "Summary too short – probably invalid input.", "success": False}

    save_res = save_note_to_firestore(
        user_id=user_id,
        title=title,
        content=content,
        summary=summary,
        source=source,
        summary_type=summary_type,
    )
    
    if not save_res["success"]:
        return {
            "warning": "Note already existed.", 
            "success": False,
            "summary_id": save_res.get("summary_id", ""),
            "note_id": save_res.get("note_id", "")
        }

    return {
        "summary": summary, 
        "summary_id": save_res.get("summary_id", ""), 
        "note_id": save_res.get("note_id", ""),
        "success": True
    }


# ---------- routes ---------- #
@app.get("/")
def welcome():
    return {"message": "StudyAI Backend is Live 🎉"}


@app.post("/summarize_text")
async def summarize_text_handler(request: Request, note: NoteRequest = Body(...)):
    return await _process_and_save(
        request=request,
        content=note.content,
        user_id=note.user_id,
        title=note.title,
        source=note.source,
        summary_type="detailed",
    )


@app.post("/summarize_raw")
async def summarize_raw_text(
    request: Request,
    content: str = Form(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("detailed"),
):
    return await _process_and_save(
        request=request,
        content=content,
        user_id=user_id,
        title=title,
        source="text",
        summary_type=summary_type,
    )


@app.post("/upload_pdf")
async def upload_pdf(
    request: Request,
    file: UploadFile = File(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("detailed"),
):
    print(f"📄 PDF upload request: user_id={user_id}, title={title}, filename={file.filename}")
    
    pdf_bytes = await file.read()
    print(f"📄 Read {len(pdf_bytes)} bytes from uploaded file")
    
    extracted = extract_text_from_pdf(pdf_bytes)
    if not extracted.strip():
        print("❌ No text extracted from PDF")
        return {"error": "No text found in PDF.", "success": False}

    print(f"✅ Extracted {len(extracted)} characters from PDF")
    
    result = await _process_and_save(
        request=request,
        content=extracted,
        user_id=user_id,
        title=title,
        source="pdf",
        summary_type=summary_type,
    )
    
    print(f"📄 PDF processing result: {result}")
    return result


@app.post("/upload_images")
async def upload_images(
    request: Request,
    files: List[UploadFile] = File(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("detailed"),
):
    chunks = []
    for f in files:
        img_bytes = await f.read()
        chunks.append(extract_text_from_image(img_bytes))

    full_text = "\n".join(chunks).strip()
    if not full_text:
        return {"error": "No text extracted from images."}

    return await _process_and_save(
        request=request,
        content=full_text,
        user_id=user_id,
        title=title,
        source="image",
        summary_type=summary_type,
    )


@app.delete("/delete_summary/{user_id}/{summary_id}")
async def delete_summary_endpoint(user_id: str, summary_id: str):
    res = delete_summary_and_note(user_id, summary_id)
    if not res["success"]:
        raise HTTPException(status_code=404, detail=res["message"])
    return res


# ---------- flashcard routes ---------- #
@app.post("/generate_flashcards")
async def generate_flashcards(
    request: Request,
    flashcard_request: FlashcardGenerationRequest = Body(...)
):
    """Generate flashcards from content."""
    try:
        if not flashcard_request.content.strip():
            return {"error": "Content is empty.", "success": False}
        if len(flashcard_request.content.split()) < 20:
            return {"error": "Content too short for flashcard generation.", "success": False}
        flashcard_service: FlashcardService = request.app.state.flashcard_service
        # Generate flashcards
        flashcards = await flashcard_service.generate_flashcards(
            flashcard_request.content, 
            num_flashcards=10
        )
        if not flashcards:
            return {"error": "Could not generate flashcards from content. No flashcards were created.", "success": False}
        # Save to Firestore only if flashcards exist
        save_result = save_flashcard_set_to_firestore(
            user_id=flashcard_request.user_id,
            set_name=flashcard_request.set_name,
            flashcards=flashcards,
            note_id=flashcard_request.note_id,
            note_title=flashcard_request.note_title,
        )
        if not save_result["success"]:
            return {
                "error": "Flashcard set could not be saved (possibly duplicate name).",
                "success": False,
                "set_id": save_result.get("set_id", ""),
                "flashcards": [{"question": card.question, "answer": card.answer} for card in flashcards]
            }
        return {
            "success": True,
            "set_id": save_result.get("set_id", ""),
            "flashcards": [{"question": card.question, "answer": card.answer} for card in flashcards],
            "count": len(flashcards)
        }
    except Exception as e:
        print(f"[DEBUG] Exception in generate_flashcards: {e}")
        return {"error": f"Failed to generate flashcards: {str(e)}", "success": False}


@app.get("/flashcard_sets/{user_id}")
async def get_flashcard_sets(user_id: str):
    """Get all flashcard sets for a user."""
    try:
        sets = get_user_flashcard_sets(user_id)
        return {"success": True, "sets": sets}
    except Exception as e:
        print(f"[DEBUG] Exception in get_flashcard_sets: {e}")
        return {"error": f"Failed to get flashcard sets: {str(e)}", "success": False}


@app.get("/flashcard_set/{user_id}/{set_id}")
async def get_flashcard_set_endpoint(user_id: str, set_id: str):
    """Get a specific flashcard set."""
    try:
        result = get_flashcard_set(user_id, set_id)
        if not result["success"]:
            raise HTTPException(status_code=404, detail=result["message"])
        return result
    except HTTPException:
        raise
    except Exception as e:
        print(f"[DEBUG] Exception in get_flashcard_set_endpoint: {e}")
        return {"error": f"Failed to get flashcard set: {str(e)}", "success": False}


@app.delete("/flashcard_set/{user_id}/{set_id}")
async def delete_flashcard_set_endpoint(user_id: str, set_id: str):
    """Delete a flashcard set."""
    try:
        result = delete_flashcard_set(user_id, set_id)
        if not result["success"]:
            raise HTTPException(status_code=404, detail=result["message"])
        return result
    except HTTPException:
        raise
    except Exception as e:
        print(f"[DEBUG] Exception in delete_flashcard_set_endpoint: {e}")
        return {"error": f"Failed to delete flashcard set: {str(e)}", "success": False}


@app.put("/flashcard_set/{user_id}/{set_id}")
async def update_flashcard_set_endpoint(
    user_id: str, 
    set_id: str, 
    flashcards: List[Dict] = Body(...)
):
    """Update a flashcard set with new flashcards."""
    try:
        # Convert dict to Flashcard objects
        flashcard_objects = []
        for card_data in flashcards:
            flashcard_objects.append(
                Flashcard(
                    question=card_data["question"],
                    answer=card_data["answer"]
                )
            )
        
        result = update_flashcard_set(user_id, set_id, flashcard_objects)
        if not result["success"]:
            raise HTTPException(status_code=404, detail=result["message"])
        return result
    except HTTPException:
        raise
    except Exception as e:
        print(f"[DEBUG] Exception in update_flashcard_set_endpoint: {e}")
        return {"error": f"Failed to update flashcard set: {str(e)}", "success": False}


@app.post("/create_flashcard_set")
async def create_flashcard_set(
    data: Dict = Body(...)
):
    """Create a flashcard set manually with a list of flashcards."""
    try:
        user_id = data.get("user_id")
        set_name = data.get("set_name")
        flashcards = data.get("flashcards", [])
        note_id = data.get("note_id")
        note_title = data.get("note_title")
        if not user_id or not set_name or not flashcards:
            return {"success": False, "error": "Missing required fields."}
        flashcard_objs = [Flashcard(question=fc["question"], answer=fc["answer"]) for fc in flashcards]
        save_result = save_flashcard_set_to_firestore(
            user_id=user_id,
            set_name=set_name,
            flashcards=flashcard_objs,
            note_id=note_id,
            note_title=note_title
        )
        return {"success": save_result.get("success", False), "set_id": save_result.get("set_id", None)}
    except Exception as e:
        return {"success": False, "error": str(e)}
