import SwiftUI

struct FlashcardEditSheet: View {
    @State var flashcard: Flashcard
    var onSave: (Flashcard) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Edit Flashcard")
                .font(.headline)
                .foregroundColor(AppColors.text)

            Group {
                TextField("Question", text: $flashcard.question)
                TextField("Answer",   text: $flashcard.answer)
            }
            .padding(10)
            .background(AppColors.card)
            .cornerRadius(8)

            HStack(spacing: 16) {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.red)
                Button("Save")   { onSave(flashcard) }
                    .disabled(flashcard.question.isEmpty
                           || flashcard.answer.isEmpty)
            }
        }
        .padding(24)
        .background(AppColors.background)
        .cornerRadius(18)
        .shadow(radius: 20)
        .frame(maxWidth: 400)
    }
} 