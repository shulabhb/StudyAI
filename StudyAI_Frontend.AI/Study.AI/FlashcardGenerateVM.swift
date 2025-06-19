import Foundation

@MainActor
final class FlashcardGenerateVM: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var reviewSet: FlashcardSetDetail?

    func generate(from note: Note, setName: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await FlashcardService.shared.generateFlashcardsAsync(
                content: note.content,
                setName: setName,
                noteId: note.id,
                noteTitle: note.title
            )
            guard response.success,
                  let setId = response.set_id else {
                throw FlashcardError.apiError(
                    response.error ?? response.warning ?? "Unknown error")
            }
            reviewSet = try await FlashcardService.shared.getFlashcardSetAsync(setId: setId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
} 