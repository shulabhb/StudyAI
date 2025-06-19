# 📚 StudyAI – AI-Powered Study Assistant App

StudyAI is an intelligent, modular iOS study assistant that helps students organize, summarize, and interact with study materials through **notes**, **PDFs**, **voice recordings**, and **AI-powered flashcards**. It features a custom FastAPI backend and a modern SwiftUI frontend, with all data synced via Firebase.

---

## ✨ Features

- 🏠 **Dashboard Home**  
  Central hub for navigation to all major features: paste note, scan PDF, record voice, flashcards, and more.

- 📝 **Smart Note Summarization**  
  Summarize your notes using a locally hosted NLP backend (BART model).

- 📄 **PDF Upload & Scan**  
  Import PDF files, extract text, and generate AI summaries from scanned notes.

- 🎙️ **Voice Note Recording & Transcription**  
  Record voice notes, transcribe them, and generate AI summaries.

- 📋 **Paste Note**  
  Paste text to quickly create and summarize notes.

- 🧠 **AI Summaries with Multiple Styles**  
  Choose from short, medium, detailed, or academic-style summaries.

- 🧾 **Flashcard Generation, Review, and Management**  
  - Generate flashcards from notes or pasted text using AI.  
  - Manually create, edit, and delete flashcard sets and cards.  
  - Review flashcards with a modern, flip-card UI.  
  - All flashcard data is synced with Firestore for persistence and cross-device access.

- 🔄 **Export & Share Notes as PDF**  
  Export your notes as PDF for sharing or offline use.

- 👤 **Profile Management**  
  View and edit your user profile.

- ⚙️ **Settings & Preferences**  
  Manage your account, log out, and view app version.

- 🔐 **Secure Auth & Data Sync**  
  Uses Firebase Authentication and Firestore to securely store user data, notes, summaries, and flashcards.

- 💾 **Local Persistence**  
  Uses Core Data for local caching and offline support.

- 🎨 **Custom Theming & UI**  
  Consistent, beautiful theming and custom UI components throughout the app.

- 🧩 **Modular, Maintainable Codebase**  
  Utility extensions and reusable components for rapid development.

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/StudyAI.git
cd StudyAI
```

### 2. Backend Setup (FastAPI)
```bash
cd StudyAI_Backend
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
# Set your Firebase credentials
export GOOGLE_APPLICATION_CREDENTIALS=path/to/your/serviceAccountKey.json
# Run the server (default port 8000)
uvicorn main:app --reload --port 8000
```
The backend will run on http://127.0.0.1:8000.

### 3. Frontend Setup (iOS)
- Open `StudyAI_Frontend.AI/Study.AI/Study_AI.xcodeproj` in Xcode.
- Set your Bundle ID and add your `GoogleService-Info.plist` for Firebase.
- Build and run on a simulator or real iOS device.

---

## 🏗️ Project Structure

StudyAI/
│
├── StudyAI_Backend/ # FastAPI-based backend
│ ├── main.py
│ ├── firebase.py
│ ├── requirements.txt
│ ├── render.yaml
│ ├── serviceAccountKey.json
│ ├── models/
│ │   ├── flashcard.py
│ │   └── note.py
│ ├── services/
│ │   ├── flashcard_service.py
│ │   ├── summarizer_service.py
│ │   ├── pdf_parser.py
│ │   └── parser.py
│ └── utils/
│     ├── auto_google_creds.py
│     └── storage.py
│
├── StudyAI_Frontend.AI/
│ └── Study.AI/
│     ├── APIConfig.swift
│     ├── AppDelegate.swift
│     ├── AppState.swift
│     ├── ContentView.swift
│     ├── CreateFlashcardSetView.swift
│     ├── CreateFlashcardView.swift
│     ├── DashboardView.swift
│     ├── Data+Multipart.swift
│     ├── EditCardsSheet.swift
│     ├── EditFlashcardSheet.swift
│     ├── EditNoteView.swift
│     ├── Extensions.swift
│     ├── FlashCardView.swift
│     ├── FlashcardCardView.swift
│     ├── FlashcardEditSheet.swift
│     ├── FlashcardGenerateVM.swift
│     ├── FlashcardGeneratorView.swift
│     ├── FlashcardModels.swift
│     ├── FlashcardPasteNoteView.swift
│     ├── FlashcardReviewVM.swift
│     ├── FlashcardSelectNoteView.swift
│     ├── FlashcardService.swift
│     ├── GoogleService-Info.plist
│     ├── LoadingView.swift
│     ├── LoginView.swift
│     ├── MainTabView.swift
│     ├── Note.swift
│     ├── NoteService.swift
│     ├── PasteNoteView.swift
│     ├── Persistence.swift
│     ├── ProfileView.swift
│     ├── RecordView.swift
│     ├── RoundedButton.swift
│     ├── SavedFlashcardReviewView.swift
│     ├── SavedFlashcardSetsView.swift
│     ├── ScanView.swift
│     ├── SettingsView.swift
│     ├── SignupView.swift
│     ├── Study_AI.entitlements
│     ├── Study_AIApp.swift
│     ├── Summary.swift
│     ├── SummaryService.swift
│     ├── SummaryView.swift
│     ├── Theme.swift
│     ├── WelcomeView.swift
│     └── Assets.xcassets/
│     └── Study_AI.xcdatamodeld/
│
└── README.md

---

## 🔥 Firebase Structure

### Authentication
- Email/Password authentication
- Google Sign-In integration
- User profile management

### Firestore Collections & Data Models

#### 1. **User**
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

#### 2. **Note**
```json
users/{userId}/notes/{noteId}
{
  "name": "string",         // Note title
  "content": "string",      // Full note text
  "source": "string",       // e.g. "text", "pdf", "voice"
  "createdAt": "timestamp",
  "noteId": "string"
}
```

#### 3. **Flashcard**
- Used as an embedded object in a flashcard set.
```json
{
  "id": "string",           // Unique flashcard ID
  "question": "string",     // Flashcard question
  "answer": "string"        // Flashcard answer
}
```

#### 4. **Flashcard Set**
```json
users/{userId}/flashcardSets/{setId}
{
  "id": "string",               // Set ID
  "name": "string",             // Set name
  "userId": "string",           // Owner user ID
  "noteId": "string|null",      // Linked note ID (if any)
  "noteTitle": "string|null",   // Linked note title (if any)
  "flashcards": [               // Array of flashcard objects
    {
      "id": "string",
      "question": "string",
      "answer": "string"
    }
  ],
  "createdAt": "timestamp"
}
```

#### 5. **FlashcardSetDetail (API Response)**
- Not stored in Firestore, but returned by the backend for detail views.
```json
{
  "success": true,
  "id": "string",
  "name": "string",
  "noteId": "string|null",
  "noteTitle": "string|null",
  "flashcards": [
    {
      "id": "string",
      "question": "string",
      "answer": "string"
    }
  ],
  "createdAt": "timestamp"
}
```

- Each set contains an array of flashcard objects (question, answer, id).
- Sets are linked to notes if generated from a note, or can be standalone.
- All flashcard CRUD operations are performed at the set level.

---

## 🚀 Flashcard Feature: Implementation Overview

### Backend (FastAPI + Firestore)
- **Endpoints:**
  - `POST /generate_flashcards` – Generate flashcards from text/notes (AI-powered)
  - `POST /create_flashcard_set` – Create a new flashcard set (manual or AI)
  - `GET /flashcard_sets/{user_id}` – List all flashcard sets for a user
  - `GET /flashcard_set/{user_id}/{set_id}` – Get details of a flashcard set
  - `PUT /flashcard_set/{user_id}/{set_id}` – Update flashcards in a set
  - `DELETE /flashcard_set/{user_id}/{set_id}` – Delete a flashcard set
- **Firestore Structure:** See above for `flashcardSets` subcollection.
- **Models:** See `models/flashcard.py` for Pydantic schemas.
- **No image OCR, quiz, or collaborative endpoints yet.**

### Frontend (SwiftUI, Modular)
- **All Files:**
  - `APIConfig.swift`
  - `AppDelegate.swift`
  - `AppState.swift`
  - `ContentView.swift`
  - `CreateFlashcardSetView.swift`
  - `CreateFlashcardView.swift`
  - `DashboardView.swift`
  - `Data+Multipart.swift`
  - `EditCardsSheet.swift`
  - `EditFlashcardSheet.swift`
  - `EditNoteView.swift`
  - `Extensions.swift`
  - `FlashCardView.swift`
  - `FlashcardCardView.swift`
  - `FlashcardEditSheet.swift`
  - `FlashcardGenerateVM.swift`
  - `FlashcardGeneratorView.swift`
  - `FlashcardModels.swift`
  - `FlashcardPasteNoteView.swift`
  - `FlashcardReviewVM.swift`
  - `FlashcardSelectNoteView.swift`
  - `FlashcardService.swift`
  - `GoogleService-Info.plist`
  - `LoadingView.swift`
  - `LoginView.swift`
  - `MainTabView.swift`
  - `Note.swift`
  - `NoteService.swift`
  - `PasteNoteView.swift`
  - `Persistence.swift`
  - `ProfileView.swift`
  - `RecordView.swift`
  - `RoundedButton.swift`
  - `SavedFlashcardReviewView.swift`
  - `SavedFlashcardSetsView.swift`
  - `ScanView.swift`
  - `SettingsView.swift`
  - `SignupView.swift`
  - `Study_AI.entitlements`
  - `Study_AIApp.swift`
  - `Summary.swift`
  - `SummaryService.swift`
  - `SummaryView.swift`
  - `Theme.swift`
  - `WelcomeView.swift`
  - `Assets.xcassets/`
  - `Study_AI.xcdatamodeld/`
 
- **Features:**
  - Generate flashcards from notes or pasted text using AI
  - Manually create, edit, and delete sets and cards
  - Review flashcards with a flip-card UI
  - All flashcard data is synced with Firestore
  - Modular SwiftUI code for maintainability and scalability
  - PDF upload and scan, voice note recording, paste note, dashboard, profile, settings, export/share as PDF, custom theming, local persistence, and more
- **No image OCR, quiz, or collaborative features in the frontend (yet).**

---

## 🧪 Example Workflow
1. Open the app and log in or sign up (onboarding flow).
2. Use the dashboard to:
   - Paste text to create and summarize a note
   - Scan/upload a PDF and generate a summary
   - Record a voice note and generate a summary
   - Access flashcards, profile, or settings
3. Generate flashcards using AI, or manually create a set.
4. Edit, add, or delete flashcards in a set.
5. Review flashcards with a flip-card UI.
6. Export notes as PDF if needed.
7. All changes are synced to Firestore and available across devices.

---

## 🧭 App State, Navigation, and Auth Flow
- The app uses a robust navigation and authentication flow:
  - Onboarding (WelcomeView)
  - Login/Signup (LoginView, SignupView)
  - MainTabView for dashboard, summaries, flashcards, and settings
  - AppState.swift manages global state and navigation
  - Profile and settings accessible from dashboard and tab bar

---

## 💡 Future Roadmap
- PDF and image OCR support
- Quiz generator based on flashcards
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


