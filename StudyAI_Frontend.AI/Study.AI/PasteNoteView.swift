import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PasteNoteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var isSummarizing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TITLE")
                        .foregroundColor(AppColors.text.opacity(0.7))
                        .font(.caption)
                    ZStack(alignment: .leading) {
                        if noteTitle.isEmpty {
                            Text("Enter title")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 16)
                        }
                        TextField("", text: $noteTitle)
                            .padding(12)
                            .background(AppColors.card)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("PASTE YOUR NOTE HERE")
                        .foregroundColor(AppColors.text.opacity(0.7))
                        .font(.caption)
                    ZStack(alignment: .topLeading) {
                        AppColors.card
                            .cornerRadius(10)
                        TextEditor(text: $noteContent)
                            .padding(12)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                    }
                    
                    // Word count display
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(noteContent.count) characters")
                                .font(.caption)
                                .foregroundColor(AppColors.text.opacity(0.6))
                            Text("\(noteContent.split(separator: " ").count) words")
                                .font(.caption)
                                .foregroundColor(AppColors.text.opacity(0.6))
                        }
                    }
                    .padding(.top, 4)
                }
                if let message = successMessage {
                    Text("✅ \(message)").foregroundColor(.green)
                }
                if let error = errorMessage {
                    Text("❌ \(error)").foregroundColor(.red)
                }
                if !isSummarizing {
                    Button(action: summarizeAndSave) {
                        Text("Save & Summarize")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .frame(height: 50)
                    .background(AppColors.card)
                    .foregroundColor(AppColors.accent)
                    .cornerRadius(12)
                }

                // Centered overlay for summarizing
                if isSummarizing {
                    ZStack {
                        AppColors.background.opacity(0.85).ignoresSafeArea()
                        Text("Summarizing...")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Paste Note")
                        .font(.custom("AvenirNext-UltraLight", size: 22))
                        .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func summarizeAndSave() {
        guard !noteTitle.isEmpty, !noteContent.isEmpty else {
            showErrorAlert(message: "Title and content can't be empty.")
            return
        }
        let charCount = noteContent.count
        if charCount < 300 {
            showErrorAlert(message: "Note is too short. Please enter at least 300 characters.")
            return
        }
        isSummarizing = true
        errorMessage = nil
        successMessage = nil
        NoteService.createNoteViaBackend(name: noteTitle, content: noteContent, summaryType: "summary", source: "text") { result in
            DispatchQueue.main.async {
                isSummarizing = false
                switch result {
                case .success(let summaryId):
                    self.successMessage = "Note and summary saved."
                    self.noteContent = ""
                    self.noteTitle = ""
                    appState.newSummaryId = summaryId
                    appState.selectedTab = .summaries
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        presentationMode.wrappedValue.dismiss()
                    }
                case .failure(let error):
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // Helper to show error alerts
    private func showErrorAlert(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

// Helper to build multipart bodies
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
