import SwiftUI

struct FlashcardSelectNoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notes: [Note] = []
    @State private var isLoading = true
    @State private var selectedNote: Note? = nil
    @State private var showPreview = false
    @State private var setName: String = ""
    @State private var canContinue = false
    @State private var showFlashcardReview = false
    @State private var errorMessage: String? = nil
    @State private var reviewSetDetail: FlashcardSetDetail? = nil

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Text("Select a Note")
                    .font(.custom("AvenirNext-UltraLight", size: 26))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 18)
                    .padding(.horizontal, 20)
                
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        Text("Loading notes...")
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Error loading notes")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text(error)
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            fetchNotes()
                        }
                        .foregroundColor(AppColors.accent)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Spacer()
                } else if notes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("No notes found")
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.title3)
                        Text("Create some notes first to generate flashcards")
                            .foregroundColor(AppColors.text.opacity(0.5))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(notes) { note in
                                Button(action: {
                                    selectedNote = note
                                    setName = note.title
                                    showPreview = true
                                }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(note.title)
                                            .font(.headline)
                                            .foregroundColor(AppColors.text)
                                        Text(note.content.prefix(80) + (note.content.count > 80 ? "..." : ""))
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.text.opacity(0.7))
                                        Text("\(note.content.count) characters")
                                            .font(.caption)
                                            .foregroundColor(AppColors.text.opacity(0.5))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppColors.card)
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .onAppear(perform: fetchNotes)
        .sheet(isPresented: $showPreview) {
            if let note = selectedNote {
                FlashcardNotePreviewSheet(note: note, setName: $setName, onContinue: {
                    showPreview = false
                    // Generate flashcards and fetch set by set_id
                    isLoading = true
                    errorMessage = nil
                    FlashcardService.shared.generateFlashcards(
                        content: note.content,
                        setName: setName,
                        noteId: note.id,
                        noteTitle: note.title
                    ) { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            switch result {
                            case .success(let response):
                                if response.success, let setId = response.set_id {
                                    // Fetch the set details by setId
                                    isLoading = true
                                    FlashcardService.shared.getFlashcardSet(setId: setId) { detailResult in
                                        DispatchQueue.main.async {
                                            isLoading = false
                                            switch detailResult {
                                            case .success(let detail):
                                                reviewSetDetail = detail
                                                showFlashcardReview = true
                                            case .failure(let err):
                                                errorMessage = err.localizedDescription
                                            }
                                        }
                                    }
                                } else {
                                    errorMessage = response.error ?? response.warning ?? "Failed to generate flashcards"
                                }
                            case .failure(let err):
                                errorMessage = err.localizedDescription
                            }
                        }
                    }
                })
            }
        }
        .fullScreenCover(isPresented: $showFlashcardReview) {
            if let detail = reviewSetDetail {
                SavedFlashcardReviewView(flashcardSet: FlashcardSet(
                    id: detail.id,
                    name: detail.name ?? "Untitled",
                    noteId: detail.noteId,
                    noteTitle: detail.noteTitle,
                    flashcardCount: detail.flashcards?.count ?? 0,
                    createdAt: detail.createdAt ?? ""
                ))
            }
        }
    }

    private func fetchNotes() {
        isLoading = true
        errorMessage = nil
        
        NoteService.fetchNotes { fetched in
            DispatchQueue.main.async {
                self.isLoading = false
                self.notes = fetched
                
                if fetched.isEmpty {
                    self.errorMessage = "No notes found. Please create some notes first."
                }
                
                print("📝 Fetched \(fetched.count) notes")
                for note in fetched {
                    print("📝 Note: \(note.title) - \(note.content.prefix(50))...")
                }
            }
        }
    }
}

struct FlashcardNotePreviewSheet: View {
    let note: Note
    @Binding var setName: String
    var onContinue: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Preview Note")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                ScrollView {
                    Text(note.content)
                        .foregroundColor(AppColors.text.opacity(0.95))
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(10)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name Your FlashCard")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Set Name", text: $setName)
                        .padding(10)
                        .background(AppColors.card)
                        .foregroundColor(AppColors.text)
                        .cornerRadius(8)
                }
                Spacer()
                Button(action: {
                    dismiss()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .cornerRadius(12)
                }
                .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(setName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
            }
            .padding(20)
            .background(AppColors.background)
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 