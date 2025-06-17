# 📚 StudyAI – AI-Powered Study Assistant App

StudyAI is an intelligent, cross-modal iOS study assistant that helps students organize, summarize, and interact with study materials through both **PDF uploads** and **voice notes**. It integrates a custom AI backend and offers a clean, user-friendly frontend built for iPhones.

---

## ✨ Features

- 📝 **Smart PDF Summarization**  
  Upload PDFs from your device and receive editable, AI-generated summaries using a locally hosted NLP backend.

- 🎙️ **Voice Notes with Transcription**  
  Record thoughts or lectures using the app's voice note feature, powered by Apple's `SFSpeechRecognizer`.

- 🧠 **AI Summaries with Multiple Styles**  
  Choose from short, medium, detailed, or academic-style summaries depending on your learning needs.

- 🧾 **Flashcard Scaffolding**  
  Automatically scaffold flashcards from summarized notes for active recall and efficient revision.

- 🔐 **Secure Auth & Data Sync**  
  Uses Firebase Authentication and Firestore to securely store user data, notes, and summaries.

---

## 🏗️ Project Structure

StudyAI/
│
├── StudyAI_Backend/ # FastAPI-based summarization backend
│ ├── main.py # Entry point of FastAPI app
│ ├── firebase.py # Firestore integration
│ ├── requirements.txt # Python dependencies
│ ├── models/ # Data models and schemas
│ ├── services/ # Business logic services
│ ├── utils/ # Utility functions
│ └── serviceAccountKey.json # Firebase credentials
│
├── StudyAI_Frontend.AI/ # SwiftUI-based iOS app
│ ├── Study.AI/ # Main iOS app source
│ ├── Views/ # Login, Dashboard, Scan, Record, etc.
│ └── Services/ # NoteService, SummaryService, etc.
│
└── README.md # This file

---

## 🔥 Firebase Structure

### Authentication
- Email/Password authentication
- Google Sign-In integration
- User profile management

### Firestore Collections

#### Users Collection
```json
users/{userId}
{
  "email": "string",
  "displayName": "string",
  "createdAt": "timestamp",
  "lastLogin": "timestamp",
  "preferences": {
    "summaryStyle": "string",
    "theme": "string"
  }
}
```

#### Notes Collection
```json
notes/{noteId}
{
  "userId": "string",
  "title": "string",
  "content": "string",
  "type": "string", // "pdf" or "voice"
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "summary": {
    "short": "string",
    "medium": "string",
    "detailed": "string",
    "academic": "string"
  },
  "metadata": {
    "sourceFile": "string",
    "duration": "number", // for voice notes
    "pageCount": "number" // for PDFs
  }
}
```

#### Flashcards Collection
```json
flashcards/{flashcardId}
{
  "userId": "string",
  "noteId": "string",
  "question": "string",
  "answer": "string",
  "createdAt": "timestamp",
  "lastReviewed": "timestamp",
  "reviewCount": "number",
  "difficulty": "number"
}
```

---

## 🚀 Tech Stack

| Layer         | Technologies Used |
|---------------|-------------------|
| Frontend (iOS) | SwiftUI, Combine, AVFoundation, SFSpeechRecognizer |
| Backend (AI)   | FastAPI, Python, Hugging Face Transformers (`facebook/bart-large-cnn`), pdfminer.six |
| Cloud          | Firebase Auth, Firestore |
| Optional       | Tesseract OCR (for future image support) |

---

## 🔧 How to Run

### 1. Backend Setup

```bash
cd StudyAI_Backend/
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```

# Set your Firebase credentials
export GOOGLE_APPLICATION_CREDENTIALS=path/to/your/serviceAccountKey.json

# Run the server
uvicorn main:app --reload --port 8000

The backend will run on http://127.0.0.1:8000.

### 2. Frontend (iOS App)
Open the project in Xcode: StudyAI_Frontend.AI/Study.AI/Study_AI.xcodeproj

Set your Bundle ID and Firebase config (GoogleService-Info.plist)

Run the app on a simulator or real iOS device

---

## 🧪 Example Workflow
1. Upload a PDF via the Scan tab → Get AI summary
2. Record a voice note → Transcription appears in real-time
3. Save note → Choose summary type → Summary & note saved to Firebase
4. Access your notes in the Summary tab or Dashboard
5. Use Flashcard tab to scaffold your revision

---

## 💡 Future Roadmap
- Flashcard Generation Automation
- OCR-based image parsing
- Quiz generator based on content
- Personalized study reminders
- Collaborative study groups
- Progress tracking and analytics
- Export functionality for notes and summaries

---

## 🤝 Contributing
Feel free to fork the repo, make improvements, and submit a pull request. Contributions are welcome!

## 📜 License
This project is under the MIT License.

## 🙋‍♂️ Author
Shulabh Bhattarai


