//
//  Summary.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/8/25.
//
import Foundation
import FirebaseCore

struct Summary: Identifiable {
    var id: String
    var noteId: String
    var summary: String
    var createdAt: Date?
}

extension Summary {
    init?(from dictionary: [String: Any], id: String) {
        guard let noteId = dictionary["noteId"] as? String,
              let summary = dictionary["summary"] as? String else {
            return nil
        }

        let timestamp = dictionary["createdAt"] as? Timestamp
        self.id = id
        self.noteId = noteId
        self.summary = summary
        self.createdAt = timestamp?.dateValue()
    }
}

