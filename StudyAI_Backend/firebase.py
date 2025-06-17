# firebase.py
"""
Firestore helpers – save & delete notes + summaries.
"""
from __future__ import annotations

import os
import uuid
from typing import Dict

from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from utils.auto_google_creds import ensure_google_credentials

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
