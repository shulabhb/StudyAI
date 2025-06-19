import SwiftUI
// Add this import if FlashcardReviewView is in another file/module
// import YourModuleNameIfNeeded

struct FlashcardPasteNoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var noteTitle: String = ""
    @State private var noteContent: String = ""
    @State private var setName: String = ""
    @State private var showPreview = false
    @State private var showFlashcardReview = false
    // If you have any optionals initialized to nil, specify their type, e.g.:
    // @State private var reviewSet: FlashcardSetDetail? = nil

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
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
                
                Text("Paste New Note")
                    .font(.custom("AvenirNext-UltraLight", size: 26))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 18)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Note Title")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter title", text: $noteTitle)
                        .padding(12)
                        .background(AppColors.card)
                        .foregroundColor(AppColors.text)
                        .cornerRadius(10)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Note Content")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(AppColors.card)
                        .foregroundColor(AppColors.text)
                        .cornerRadius(10)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Flashcard Set Name")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter set name", text: $setName)
                        .padding(12)
                        .background(AppColors.card)
                        .foregroundColor(AppColors.text)
                        .cornerRadius(10)
                }
                Spacer()
                Button(action: { showPreview = true }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .cornerRadius(12)
                }
                .disabled(noteTitle.trimmingCharacters(in: .whitespaces).isEmpty || noteContent.trimmingCharacters(in: .whitespaces).isEmpty || setName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity((noteTitle.trimmingCharacters(in: .whitespaces).isEmpty || noteContent.trimmingCharacters(in: .whitespaces).isEmpty || setName.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1)
            }
            .padding(20)
        }
        .sheet(isPresented: $showPreview) {
            FlashcardPasteNotePreviewSheet(noteTitle: noteTitle, noteContent: noteContent, setName: setName, onContinue: {
                showPreview = false
                showFlashcardReview = true
            })
        }
        .fullScreenCover(isPresented: $showFlashcardReview) {
            SavedFlashcardReviewView(
                flashcardSet: FlashcardSet(
                    id: UUID().uuidString,
                    name: setName,
                    noteId: nil,
                    noteTitle: noteTitle,
                    flashcardCount: 0,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
            )
        }
    }
}

struct FlashcardPasteNotePreviewSheet: View {
    let noteTitle: String
    let noteContent: String
    let setName: String
    var onContinue: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Preview Note")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                Text(noteTitle)
                    .font(.title3.bold())
                    .foregroundColor(AppColors.text)
                ScrollView {
                    Text(noteContent)
                        .foregroundColor(AppColors.text.opacity(0.95))
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(10)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Flashcard Set Name")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    Text(setName)
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
            }
            .padding(20)
            .background(AppColors.background)
            .navigationTitle(noteTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.red)
                }
            }
        }
    }
} 