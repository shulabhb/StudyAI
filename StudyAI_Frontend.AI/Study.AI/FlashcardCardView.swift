import SwiftUI

struct FlashcardCardView: View {
    let flashcard: Flashcard
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.1),
                        radius: 10, x: 0, y: 4)

            Text(isFlipped ? flashcard.answer : flashcard.question)
                .font(.title3.bold())
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(height: 220)
        .onTapGesture { isFlipped.toggle() }
        .animation(.spring(), value: isFlipped)
    }
} 