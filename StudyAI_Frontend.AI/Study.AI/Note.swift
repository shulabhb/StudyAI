//
//  Note.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 6/11/25.
//


import Foundation
import FirebaseCore

struct Note: Identifiable {
    var id: String               // noteId (Firestore doc ID)
    var title: String
    var content: String
    var summary: String?         // If summary is stored inline in the note
    var summaryId: String?       // If you need to fetch summary separately
    var createdAt: Date?
    var source: String?

    init?(from dictionary: [String: Any], id: String) {
        guard let title = dictionary["name"] as? String,
              let content = dictionary["content"] as? String else { return nil }
        self.id = id
        self.title = title
        self.content = content
        self.summary = dictionary["summary"] as? String
        self.summaryId = dictionary["summaryId"] as? String
        if let timestamp = dictionary["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        }
        self.source = dictionary["source"] as? String
    }
}
