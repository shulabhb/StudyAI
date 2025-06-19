//
//  FlashcardService.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import Foundation
import FirebaseAuth

struct FlashcardGenerationRequest: Codable {
    let content: String
    let user_id: String
    let set_name: String
    let note_id: String?
    let note_title: String?
}

struct FlashcardGenerationResponse: Codable {
    let success: Bool
    let set_id: String?
    let flashcards: [FlashcardData]?
    let count: Int?
    let error: String?
    let warning: String?
}

struct FlashcardSetsResponse: Codable {
    let success: Bool
    let sets: [FlashcardSet]?
    let error: String?
}

class FlashcardService {
    static let shared = FlashcardService()
    private let baseURL = "http://localhost:8000"
    
    private init() {}
    
    // MARK: - Generate Flashcards
    func generateFlashcards(
        content: String,
        setName: String,
        noteId: String? = nil,
        noteTitle: String? = nil,
        completion: @escaping (Result<FlashcardGenerationResponse, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        
        let request = FlashcardGenerationRequest(
            content: content,
            user_id: user.uid,
            set_name: setName,
            note_id: noteId,
            note_title: noteTitle
        )
        
        guard let url = URL(string: "\(baseURL)/generate_flashcards") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(FlashcardError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FlashcardGenerationResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Flashcard Sets
    func getFlashcardSets(completion: @escaping (Result<[FlashcardSet], Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/flashcard_sets/\(user.uid)") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(FlashcardError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FlashcardSetsResponse.self, from: data)
                    if response.success, let sets = response.sets {
                        completion(.success(sets))
                    } else {
                        completion(.failure(FlashcardError.apiError(response.error ?? "Unknown error")))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Flashcard Set Detail
    func getFlashcardSet(setId: String, completion: @escaping (Result<FlashcardSetDetail, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        guard let url = URL(string: "\(baseURL)/flashcard_set/\(user.uid)/\(setId)") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        print("🌐 Requesting flashcard set from: \(url)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(FlashcardError.noData))
                    return
                }
                print("📦 JSON:\n\(String(data: data, encoding: .utf8) ?? "nil")")
                do {
                    let response = try JSONDecoder().decode(FlashcardSetDetail.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Flashcard Set
    func deleteFlashcardSet(setId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/flashcard_set/\(user.uid)/\(setId)") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    completion(.success(httpResponse.statusCode == 200))
                } else {
                    completion(.failure(FlashcardError.invalidResponse))
                }
            }
        }.resume()
    }
    
    // MARK: - Update Flashcard Set
    func updateFlashcardSet(
        setId: String,
        flashcards: [Flashcard],
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/flashcard_set/\(user.uid)/\(setId)") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        
        // Convert Flashcard to FlashcardData
        let flashcardData = flashcards.map { FlashcardData(id: $0.id, question: $0.question, answer: $0.answer) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(flashcardData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    completion(.success(httpResponse.statusCode == 200))
                } else {
                    completion(.failure(FlashcardError.invalidResponse))
                }
            }
        }.resume()
    }
    
    // MARK: - Create Flashcard Set (Manual)
    func createFlashcardSet(
        setName: String,
        flashcards: [FlashcardData],
        noteId: String? = nil,
        noteTitle: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(FlashcardError.userNotAuthenticated))
            return
        }
        guard let url = URL(string: "\(baseURL)/create_flashcard_set") else {
            completion(.failure(FlashcardError.invalidURL))
            return
        }
        let payload: [String: Any] = [
            "user_id": user.uid,
            "set_name": setName,
            "flashcards": flashcards.map { ["question": $0.question, "answer": $0.answer] },
            "note_id": noteId as Any,
            "note_title": noteTitle as Any
        ]
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(FlashcardError.noData))
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success,
                       let setId = json["set_id"] as? String {
                        completion(.success(setId))
                    } else {
                        let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Unknown error"
                        completion(.failure(FlashcardError.apiError(errorMsg)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

extension FlashcardService {
    func generateFlashcardsAsync(
        content: String,
        setName: String,
        noteId: String? = nil,
        noteTitle: String? = nil
    ) async throws -> FlashcardGenerationResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.generateFlashcards(
                content: content,
                setName: setName,
                noteId: noteId,
                noteTitle: noteTitle
            ) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getFlashcardSetAsync(setId: String) async throws -> FlashcardSetDetail {
        try await withCheckedThrowingContinuation { continuation in
            self.getFlashcardSet(setId: setId) { result in
                switch result {
                case .success(let detail):
                    continuation.resume(returning: detail)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors
enum FlashcardError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidURL
    case noData
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response"
        case .apiError(let message):
            return message
        }
    }
} 