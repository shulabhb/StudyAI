//
//  NoteService.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 6/11/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class NoteService {
    // MARK: - Create Note & Summary via Backend API
    static func createNoteViaBackend(name: String, content: String, summaryType: String = "bullet_points", source: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in. Please log in and try again."])));
            return
        }
        let urlString = "\(APIConfig.baseURL)/summarize_raw"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid backend URL. Please contact support."])));
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        let params: [String: String] = [
            "content": content,
            "user_id": userId,
            "title": name,
            "summary_type": summaryType
        ]
        for (key, value) in params {
            body.appendFormField(named: key, value: value, using: boundary)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error: \(error.localizedDescription)"])));
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No response from backend. Please try again."])));
                return
            }
            guard httpResponse.statusCode == 200 else {
                let message = "Backend error (\(httpResponse.statusCode)). Please try again or contact support."
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])));
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data returned from backend."])));
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let summaryId = json["summary_id"] as? String {
                    completion(.success(summaryId))
                } else {
                    completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing summary_id in backend response."])));
                }
            } catch {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "JSON parsing error: \(error.localizedDescription)"])));
            }
        }.resume()
    }

    // MARK: - Fetch All Notes
    static func fetchNotes(completion: @escaping ([Note]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not logged in")
            completion([])
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("notes")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore fetch error: \(error)")
                    completion([])
                    return
                }

                let notes = snapshot?.documents.compactMap { doc in
                    Note(from: doc.data(), id: doc.documentID)
                } ?? []

                completion(notes)
            }
    }

    // MARK: - Delete Note By ID
    static func deleteNote(withId noteId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("notes").document(noteId).delete { error in
            if let error = error {
                print("❌ Firestore delete error (note): \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
