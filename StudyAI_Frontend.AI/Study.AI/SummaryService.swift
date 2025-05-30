//
//  SummaryService.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/8/25.
//
import FirebaseAuth
import FirebaseFirestore

class SummaryService {
    static func fetchSummaries(completion: @escaping ([Summary]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not logged in")
            completion([])
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("summaries")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore fetch error: \(error)")
                    completion([])
                    return
                }

                let allSummaries = snapshot?.documents.compactMap { doc in
                    Summary(from: doc.data(), id: doc.documentID)
                } ?? []

                // ✅ Deduplicate by noteId
                let uniqueSummaries = Dictionary(grouping: allSummaries, by: \.noteId)
                    .compactMap { $0.value.first }

                completion(uniqueSummaries)
            }
    }
}
