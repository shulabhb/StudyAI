import Foundation
import Combine

@MainActor
final class FlashcardReviewVM: ObservableObject {
    @Published var flashcards: [Flashcard] = []
    @Published var currentIndex = 0
    @Published var isFlipped = false
    @Published var isLoading = false
    @Published var error: String?

    private let content: String
    private let setName: String
    private let noteId: String?
    private let noteTitle: String?

    init(content: String, setName: String, noteId: String?, noteTitle: String?) {
        self.content = content
        self.setName = setName
        self.noteId = noteId
        self.noteTitle = noteTitle
    }

    func generate() async {
        isLoading = true
        error = nil
        do {
            let res = try await FlashcardService.shared.generateFlashcardsAsync(
                content: content,
                setName: setName,
                noteId: noteId,
                noteTitle: noteTitle
            )
            guard res.success, let data = res.flashcards else {
                throw FlashcardError.apiError(
                    res.error ?? res.warning ?? "Unknown error")
            }
            flashcards = data.map {
                Flashcard(id: $0.id, question: $0.question, answer: $0.answer)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func prevCard() {
        guard !flashcards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + flashcards.count) % flashcards.count
        isFlipped = false
    }

    func nextCard() {
        guard !flashcards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % flashcards.count
        isFlipped = false
    }

    func deleteCard(at idx: Int) {
        guard flashcards.indices.contains(idx) else { return }
        flashcards.remove(at: idx)
        if currentIndex >= flashcards.count { currentIndex = max(0, flashcards.count - 1) }
        isFlipped = false
    }
} 