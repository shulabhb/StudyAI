import Foundation
import FirebaseFirestore
import FirebaseAuth

struct NoteService {
    static func saveNote(name: String, content: String, summary: String, source: String, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }

        let db = Firestore.firestore()
        let noteId = UUID().uuidString
        let summaryId = UUID().uuidString
        let timestamp = Timestamp(date: Date())

        let noteData: [String: Any] = [
            "name": name,
            "content": content,
            "source": source, // "voice" or "image"
            "createdAt": timestamp,
            "summarized": true,
            "summaryId": summaryId,
            "summary": summary
        ]

        let summaryData: [String: Any] = [
            "noteId": noteId,
            "createdAt": timestamp,
            "summary": summary
        ]

        let noteRef = db.collection("users").document(userId).collection("notes").document(noteId)
        let summaryRef = db.collection("users").document(userId).collection("summaries").document(summaryId)

        let batch = db.batch()
        batch.setData(noteData, forDocument: noteRef)
        batch.setData(summaryData, forDocument: summaryRef)

        batch.commit { error in
            completion(error)
        }
    }
}
