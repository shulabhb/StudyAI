import Foundation

public struct Flashcard: Identifiable, Hashable {
    public let id: String
    public var question: String
    public var answer: String
}

public struct FlashcardData: Codable, Identifiable {
    public let id: String
    public var question: String
    public var answer: String
}

public struct FlashcardSet: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let noteId: String?
    public let noteTitle: String?
    public let flashcardCount: Int
    public let createdAt: String
}

public struct FlashcardSetDetail: Codable {
    public let success: Bool?
    public let id: String
    public let name: String?
    public let noteId: String?
    public let noteTitle: String?
    public let flashcards: [FlashcardData]?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case success
        case id
        case name
        case noteId     = "note_id"
        case noteTitle  = "note_title"
        case flashcards
        case createdAt  = "created_at"
    }
} 