import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
load_dotenv()


# Use environment variable to securely load credentials
cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

if not firebase_admin._apps:
    if not cred_path:
        raise ValueError("❌ GOOGLE_APPLICATION_CREDENTIALS env variable is not set.")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def sanitize_for_firestore(text: str) -> str:
    return text.replace(' ', '_').replace('/', '-').strip()

def save_note_to_firestore(user_id: str, title: str, content: str, summary: str, source: str):
    note_id = f"{sanitize_for_firestore(source)}_{sanitize_for_firestore(title)}"
    summary_id = f"{note_id}_summary"
    timestamp = firestore.SERVER_TIMESTAMP

    note_ref = db.collection("users").document(user_id).collection("notes").document(note_id)
    summary_ref = db.collection("users").document(user_id).collection("summaries").document(summary_id)

    batch = db.batch()

    batch.set(note_ref, {
        "name": title,
        "content": content,
        "source": source,
        "createdAt": timestamp,
        "summarized": True,
        "summaryId": summary_id
    })

    batch.set(summary_ref, {
        "noteId": note_id,
        "summary": summary,
        "createdAt": timestamp
    })
    print("🔗 Note path:", note_ref.path)
    print("🔗 Summary path:", summary_ref.path)


    batch.commit()
    print("✅ Firestore write successful.")
