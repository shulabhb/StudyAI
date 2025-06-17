//
//  SummaryService.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/8/25.
//
import FirebaseAuth
import FirebaseFirestore

class SummaryService {
    // MARK: - Legacy: Direct Firestore Delete (not used anymore)
    static func deleteSummary(withId summaryId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not logged in")
            completion(false)
            return
        }
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("summaries")
            .document(summaryId)
            .delete { error in
                if let error = error {
                    print("❌ Firestore delete error (summary): \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }

    // MARK: - Delete summary and note via FastAPI backend
    static func deleteSummaryViaBackend(summaryId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not logged in")
            completion(false)
            return
        }
        // Replace with your real backend URL!
        let urlString = "http://127.0.0.1:8000/delete_summary/\(userId)/\(summaryId)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Backend delete request error: \(error)")
                completion(false)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            if httpResponse.statusCode == 200 {
                completion(true)
            } else {
                print("❌ Backend delete failed. Status: \(httpResponse.statusCode)")
                completion(false)
            }
        }.resume()
    }

    // MARK: - Fetch all summaries for the current user
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
                    print("❌ Firestore fetch error (summaries): \(error)")
                    completion([])
                    return
                }
                let summaries = snapshot?.documents.compactMap { doc in
                    Summary(from: doc.data(), id: doc.documentID)
                } ?? []
                completion(summaries)
            }
    }
}
