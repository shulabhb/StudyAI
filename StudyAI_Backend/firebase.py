# firebase.py
"""
Firestore helpers – save & delete notes + summaries + flashcards.
"""
from __future__ import annotations

import os
import uuid
from typing import Dict, List

from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from utils.auto_google_creds import ensure_google_credentials
from models.flashcard import Flashcard, FlashcardSet

load_dotenv()

# ---------- initialisation ---------- #
ensure_google_credentials()

if not firebase_admin._apps:
    firebase_admin.initialize_app(credentials.Certificate(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]))

db = firestore.client()

# ---------- utils ---------- #
def _sanitize(key: str) -> str:
    return key.replace(" ", "_").replace("/", "-").strip()


# ---------- public API ---------- #
def save_note_to_firestore(
    *,
    user_id: str,
    title: str,
    content: str,
    summary: str,
    source: str,
    summary_type: str = "bullet_points",
) -> Dict[str, str]:
    note_id = f"{_sanitize(source)}_{_sanitize(title)}"
    summary_id = f"{note_id}_{summary_type}_{uuid.uuid4().hex[:8]}"

    note_ref = (
        db.collection("users")
        .document(user_id)
        .collection("notes")
        .document(note_id)
    )
    summary_ref = (
        db.collection("users")
        .document(user_id)
        .collection("summaries")
        .document(summary_id)
    )

    if note_ref.get().exists:
        print(f"⚠️ Note {note_id} already exists – skipping write")
        return {"success": False, "note_id": note_id, "summary_id": summary_id}

    batch = db.batch()
    ts = firestore.SERVER_TIMESTAMP

    batch.set(
        note_ref,
        {
            "name": title,
            "content": content,
            "source": source,
            "createdAt": ts,
            "noteId": note_id,
        },
    )
    batch.set(
        summary_ref,
        {
            "noteId": note_id,
            "summary": summary,
            "summaryType": summary_type,
            "createdAt": ts,
        },
    )
    batch.commit()
    print("✅ Firestore write successful.")
    return {"success": True, "note_id": note_id, "summary_id": summary_id}


def delete_summary_and_note(user_id: str, summary_id: str) -> Dict[str, str | bool]:
    """Atomically delete summary and its linked note."""
    try:
        print(f"[DEBUG] Deleting summary: user_id={user_id}, summary_id={summary_id}")
        summary_ref = (
            db.collection("users")
            .document(user_id)
            .collection("summaries")
            .document(summary_id)
        )
        summary_doc = summary_ref.get()
        if not summary_doc.exists:
            print(f"[DEBUG] Summary not found: {summary_id}")
            return {"success": False, "message": "Summary not found"}
        note_id = summary_doc.to_dict().get("noteId")
        note_ref = (
            db.collection("users")
            .document(user_id)
            .collection("notes")
            .document(note_id)
        )
        batch = db.batch()
        batch.delete(summary_ref)
        batch.delete(note_ref)
        batch.commit()
        print(f"[DEBUG] Deleted summary: {summary_id} and note: {note_id}")
        return {"success": True, "message": "Deleted", "note_id": note_id}
    except Exception as exc:
        print(f"[DEBUG] Exception in delete_summary_and_note: {exc}")
        return {"success": False, "message": str(exc)}


# ---------- flashcard functions ---------- #
def save_flashcard_set_to_firestore(
    *,
    user_id: str,
    set_name: str,
    flashcards: List[Flashcard],
    note_id: str = None,
    note_title: str = None,
) -> Dict[str, str]:
    """Save a flashcard set to Firestore."""
    set_id = f"flashcard_set_{_sanitize(set_name)}_{uuid.uuid4().hex[:8]}"
    
    # Convert flashcards to dict format for Firestore
    flashcard_data = []
    for i, card in enumerate(flashcards):
        flashcard_data.append({
            "id": f"card_{i}_{uuid.uuid4().hex[:4]}",
            "question": card.question,
            "answer": card.answer,
        })
    
    set_ref = (
        db.collection("users")
        .document(user_id)
        .collection("flashcardSets")
        .document(set_id)
    )
    
    if set_ref.get().exists:
        print(f"⚠️ Flashcard set {set_id} already exists – skipping write")
        return {"success": False, "set_id": set_id}
    
    ts = firestore.SERVER_TIMESTAMP
    
    set_ref.set({
        "name": set_name,
        "userId": user_id,
        "noteId": note_id,
        "noteTitle": note_title,
        "flashcards": flashcard_data,
        "createdAt": ts,
        "setId": set_id,
    })
    
    print("✅ Flashcard set saved to Firestore.")
    return {"success": True, "set_id": set_id}


def get_user_flashcard_sets(user_id: str) -> List[Dict]:
    """Get all flashcard sets for a user."""
    try:
        sets_ref = (
            db.collection("users")
            .document(user_id)
            .collection("flashcardSets")
        )
        
        sets = []
        for doc in sets_ref.stream():
            data = doc.to_dict()
            created_at = data.get("createdAt")
            # Convert Firestore timestamp to ISO string
            if hasattr(created_at, "isoformat"):
                created_at = created_at.isoformat()
            elif created_at is not None:
                created_at = str(created_at)
            sets.append({
                "id": data.get("setId"),
                "name": data.get("name"),
                "noteId": data.get("noteId"),
                "noteTitle": data.get("noteTitle"),
                "flashcardCount": len(data.get("flashcards", [])),
                "createdAt": created_at,
            })
        # Sort by creation date (newest first)
        sets.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
        return sets
    except Exception as exc:
        print(f"[DEBUG] Exception in get_user_flashcard_sets: {exc}")
        return []


def get_flashcard_set(user_id: str, set_id: str) -> Dict:
    """Get a specific flashcard set."""
    try:
        set_ref = (
            db.collection("users")
            .document(user_id)
            .collection("flashcardSets")
            .document(set_id)
        )
        
        doc = set_ref.get()
        if not doc.exists:
            return {"success": False, "message": "Flashcard set not found"}
        
        data = doc.to_dict()
        created_at = data.get("createdAt")
        # Convert Firestore timestamp to ISO string
        if hasattr(created_at, "isoformat"):
            created_at = created_at.isoformat()
        elif created_at is not None:
            created_at = str(created_at)
        return {
            "success": True,
            "id": data.get("setId"),
            "name": data.get("name"),
            "noteId": data.get("noteId"),
            "noteTitle": data.get("noteTitle"),
            "flashcards": data.get("flashcards", []),
            "createdAt": created_at,
        }
    except Exception as exc:
        print(f"[DEBUG] Exception in get_flashcard_set: {exc}")
        return {"success": False, "message": str(exc)}


def delete_flashcard_set(user_id: str, set_id: str) -> Dict[str, str | bool]:
    """Delete a flashcard set."""
    try:
        print(f"[DEBUG] Deleting flashcard set: user_id={user_id}, set_id={set_id}")
        set_ref = (
            db.collection("users")
            .document(user_id)
            .collection("flashcardSets")
            .document(set_id)
        )
        
        if not set_ref.get().exists:
            print(f"[DEBUG] Flashcard set not found: {set_id}")
            return {"success": False, "message": "Flashcard set not found"}
        
        set_ref.delete()
        print(f"[DEBUG] Deleted flashcard set: {set_id}")
        return {"success": True, "message": "Deleted"}
    except Exception as exc:
        print(f"[DEBUG] Exception in delete_flashcard_set: {exc}")
        return {"success": False, "message": str(exc)}


def update_flashcard_set(
    user_id: str, 
    set_id: str, 
    flashcards: List[Flashcard]
) -> Dict[str, str | bool]:
    """Update a flashcard set with new flashcards."""
    try:
        set_ref = (
            db.collection("users")
            .document(user_id)
            .collection("flashcardSets")
            .document(set_id)
        )
        
        if not set_ref.get().exists:
            return {"success": False, "message": "Flashcard set not found"}
        
        # Convert flashcards to dict format
        flashcard_data = []
        for i, card in enumerate(flashcards):
            flashcard_data.append({
                "id": f"card_{i}_{uuid.uuid4().hex[:4]}",
                "question": card.question,
                "answer": card.answer,
            })
        
        set_ref.update({
            "flashcards": flashcard_data,
        })
        
        print(f"[DEBUG] Updated flashcard set: {set_id}")
        return {"success": True, "message": "Updated"}
    except Exception as exc:
        print(f"[DEBUG] Exception in update_flashcard_set: {exc}")
        return {"success": False, "message": str(exc)}
