import SwiftUI

// Moved from SavedFlashcardSetsView.swift
struct EditFlashcardSheet: View {
    @State var flashcard: FlashcardData
    var onSave: (FlashcardData) -> Void
    var onCancel: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Text("Edit Flashcard")
                .font(.headline)
                .foregroundColor(AppColors.text)
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.caption)
                    .foregroundColor(AppColors.text.opacity(0.7))
                TextField("Question", text: $flashcard.question)
                    .padding(10)
                    .background(AppColors.card)
                    .foregroundColor(AppColors.text)
                    .cornerRadius(8)
                Text("Answer")
                    .font(.caption)
                    .foregroundColor(AppColors.text.opacity(0.7))
                TextField("Answer", text: $flashcard.answer)
                    .padding(10)
                    .background(AppColors.card)
                    .foregroundColor(AppColors.text)
                    .cornerRadius(8)
            }
            HStack(spacing: 16) {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.red)
                Button("Save") {
                    onSave(flashcard)
                }
                .foregroundColor(AppColors.text)
                .disabled(flashcard.question.trimmingCharacters(in: .whitespaces).isEmpty || flashcard.answer.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity((flashcard.question.trimmingCharacters(in: .whitespaces).isEmpty || flashcard.answer.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1)
            }
        }
        .padding(24)
        .background(AppColors.background)
        .cornerRadius(18)
        .shadow(radius: 20)
        .frame(maxWidth: 400)
    }
} 