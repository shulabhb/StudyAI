# main.py
from fastapi import FastAPI, UploadFile, File, Form, Body
from typing import List
from models.note import NoteRequest
from services.summarizer import summarize_text
from services.parser import extract_text_from_image
from firebase import save_note_to_firestore
from services.pdf_parser import extract_text_from_pdf

app = FastAPI()

@app.get("/")
def welcome():
    return {"message": "StudyAI Backend is Live 🎉"}

@app.post("/summarize_text")
async def summarize_text_handler(note: NoteRequest = Body(...)):
    print("📝 Received text note to summarize")

    try:
        summary = summarize_text(note.content, summary_type=note.summary_type or "medium")
    except Exception as e:
        print(f"❌ Summarization failed: {e}")
        return {"error": "Summarization failed", "details": str(e)}

    try:
        save_note_to_firestore(
            user_id=note.user_id,
            title=note.title,
            content=note.content,
            summary=summary,
            source=note.source
        )
    except Exception as e:
        print(f"❌ Firestore write failed: {e}")
        return {"error": "Firestore save failed", "details": str(e)}

    return {"summary": summary, "status": "✅ Text summarized and saved"}

@app.post("/summarize_raw")
async def summarize_raw_text(
    content: str = Form(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("medium")
):
    print("📝 Raw text input received")

    if not content.strip():
        return {"error": "Text input is empty."}

    try:
        summary = summarize_text(content, summary_type=summary_type)
        print("🧠 Summary successfully generated.")
    except Exception as e:
        print(f"❌ Summarization failed: {e}")
        return {"error": "Summarization failed", "details": str(e)}

    try:
        save_note_to_firestore(
            user_id=user_id,
            title=title,
            content=content,
            summary=summary,
            source="text"
        )
    except Exception as e:
        print(f"❌ Firestore write failed: {e}")
        return {"error": "Firestore save failed", "details": str(e)}

    return {"summary": summary, "status": "✅ Text summarized and saved"}

@app.post("/upload_pdf")
async def upload_pdf(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("medium")
):
    print("📄 PDF upload received")

    pdf_bytes = await file.read()
    extracted_text = extract_text_from_pdf(pdf_bytes)

    if not extracted_text.strip():
        return {"error": "No text found in PDF."}

    summary = summarize_text(extracted_text, summary_type=summary_type)

    save_note_to_firestore(
        user_id=user_id,
        title=title,
        content=extracted_text,
        summary=summary,
        source="pdf"
    )

    return {
        "raw_text": extracted_text,
        "summary": summary,
        "status": "PDF summarized and saved ✅"
    }

@app.post("/upload_images")
async def upload_images(
    files: List[UploadFile] = File(...),
    user_id: str = Form(...),
    title: str = Form(...),
    summary_type: str = Form("medium")
):
    print("📥 Received upload request")
    print(f"👤 user_id: {user_id}")
    print(f"📝 title: {title}")
    print(f"📦 Total files received: {len(files)}")

    full_text = ""

    for i, file in enumerate(files):
        print(f"🔍 Processing file {i + 1}: {file.filename}")
        try:
            image_bytes = await file.read()
            print(f"✅ Read {len(image_bytes)} bytes from {file.filename}")
            extracted_text = extract_text_from_image(image_bytes)
            print(f"🧠 OCR extracted {len(extracted_text)} characters")
            full_text += extracted_text + "\n"
        except Exception as e:
            print(f"❌ Failed to process {file.filename}: {e}")
            continue

    if not full_text.strip():
        return {"error": "No text extracted from images."}

    try:
        summary = summarize_text(full_text, summary_type=summary_type)
        print("📝 Summary successfully generated.")
    except Exception as e:
        print(f"❌ Summarization failed: {e}")
        return {"error": "Summarization failed", "details": str(e)}

    try:
        save_note_to_firestore(
            user_id=user_id,
            title=title,
            content=full_text,
            summary=summary,
            source="image"
        )
    except Exception as e:
        print(f"❌ Firestore write failed: {e}")
        return {"error": "Firestore save failed", "details": str(e)}

    return {
        "raw_text": full_text,
        "summary": summary,
        "status": "✅ Saved to Firestore"
    }
