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
├── backend/ # FastAPI-based summarization backend
│ ├── main.py # Entry point of FastAPI app
│ ├── summarize.py # Hugging Face summarization logic
│ ├── firebase.py # Firestore integration
│ └── pdf_parser.py # Text extraction via pdfminer
│
├── frontend/ # SwiftUI-based iOS app
│ ├── Study.AI/ # Main iOS app source
│ ├── Views/ # Login, Dashboard, Scan, Record, etc.
│ └── Services/ # NoteService, SummaryService, etc.
│
└── README.md # This file


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

cd backend/
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```
# Set your Firebase credentials
export GOOGLE_APPLICATION_CREDENTIALS=path/to/your/serviceAccountKey.json

# Run the server
uvicorn main:app --reload

The backend will run on http://127.0.0.1:8000.

### 2. Frontend (iOS App)
Open the project in Xcode: frontend/Study.AI/Study_AI.xcodeproj

Set your Bundle ID and Firebase config (GoogleService-Info.plist)

Run the app on a simulator or real iOS device

🧪 Example Workflow
Upload a PDF via the Scan tab → Get AI summary

Record a voice note → Transcription appears in real-time

Save note → Choose summary type → Summary & note saved to Firebase

Access your notes in the Summary tab or Dashboard

Use Flashcard tab to scaffold your revision

💡 Future Roadmap
 Flashcard Generation Automation

 OCR-based image parsing

 Quiz generator based on content

 Personalized study reminders

🤝 Contributing
Feel free to fork the repo, make improvements, and submit a pull request. Contributions are welcome!

📜 License
This project is under the MIT License.

🙋‍♂️ Author
Shulabh Bhattarai


