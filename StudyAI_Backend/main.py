# main.py
"""
FastAPI entry-point for StudyAI backend.
• One Bart model instance shared via app.state
• Endpoints: raw text, PDF, images, delete
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
from models.note import NoteRequest
from services.summarizer_service import SummarizerService
from services.parser import extract_text_from_image
from services.pdf_parser import extract_text_from_pdf
from firebase import delete_summary_and_note, save_note_to_firestore
from utils.auto_google_creds import ensure_google_credentials

# ---------- bootstrap ---------- #
ensure_google_credentials()

app = FastAPI()


@app.on_event("startup")
async def load_model() -> None:
    app.state.summarizer = SummarizerService()


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
        return {"error": "Content is empty."}

    svc: SummarizerService = request.app.state.summarizer
    summary = await svc.summarize(content, academic=True)

    if len(summary.strip()) < 10:
        return {"error": "Summary too short – probably invalid input."}

    save_res = save_note_to_firestore(
        user_id=user_id,
        title=title,
        content=content,
        summary=summary,
        source=source,
        summary_type=summary_type,
    )
    if not save_res["success"]:
        return {"warning": "Note already existed.", **save_res}

    return {"summary": summary, "summary_id": save_res.get("summary_id"), **save_res}


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
    pdf_bytes = await file.read()
    extracted = extract_text_from_pdf(pdf_bytes)
    if not extracted.strip():
        return {"error": "No text found in PDF."}

    return await _process_and_save(
        request=request,
        content=extracted,
        user_id=user_id,
        title=title,
        source="pdf",
        summary_type=summary_type,
    )


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
