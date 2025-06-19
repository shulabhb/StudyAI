import SwiftUI

struct CreateFlashcardView: View {
    @Binding var setName: String
    @Binding var question: String
    @Binding var answer: String
    var onSave: (String, String, String) -> Void
    var onCancel: () -> Void
    @State private var showTitleExistsAlert = false
    @State private var tempSetName = ""
    @Environment(\.presentationMode) var presentationMode
    // Access all sets to check for duplicates
    @State private var allSetNames: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create Flashcard")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.text)
                    .padding(.top, 16)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set Name")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter set name", text: $setName)
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(8)
                        .foregroundColor(AppColors.text)
                    Text("Question")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter question", text: $question)
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(8)
                        .foregroundColor(AppColors.text)
                    Text("Answer")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter answer", text: $answer)
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(8)
                        .foregroundColor(AppColors.text)
                }
                .padding(.horizontal, 20)
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.red)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                    Button("Save") {
                        if allSetNames.contains(where: { $0.caseInsensitiveCompare(setName) == .orderedSame }) {
                            tempSetName = setName
                            showTitleExistsAlert = true
                        } else {
                            onSave(setName, question, answer)
                        }
                    }
                    .foregroundColor(AppColors.text)
                    .padding()
                    .background(AppColors.accent)
                    .cornerRadius(8)
                    .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty || question.trimmingCharacters(in: .whitespaces).isEmpty || answer.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity((setName.trimmingCharacters(in: .whitespaces).isEmpty || question.trimmingCharacters(in: .whitespaces).isEmpty || answer.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1)
                }
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .onAppear {
                // Fetch all set names for duplicate check
                FlashcardService.shared.getFlashcardSets { result in
                    if case .success(let sets) = result {
                        // Only block if any set has the same name, regardless of noteId/noteTitle
                        allSetNames = sets.map { $0.name }
                    }
                }
            }
            .alert(isPresented: $showTitleExistsAlert) {
                Alert(
                    title: Text("Title Exists"),
                    message: Text("A flashcard set with this title already exists. Please choose a different title."),
                    primaryButton: .default(Text("Edit Title"), action: {
                        // Focus on setName field
                    }),
                    secondaryButton: .cancel(Text("Cancel"), action: {
                        setName = tempSetName
                    })
                )
            }
        }
    }
} 