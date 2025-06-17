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
    var title: String?    // <-- new!

    init(id: String, noteId: String, summary: String, createdAt: Date?, title: String? = nil) {
        self.id = id
        self.noteId = noteId
        self.summary = summary
        self.createdAt = createdAt
        self.title = title
    }
}

extension Summary {
    init?(from dictionary: [String: Any], id: String, title: String? = nil) {
        guard let noteId = dictionary["noteId"] as? String,
              let summary = dictionary["summary"] as? String else {
            return nil
        }

        let timestamp = dictionary["createdAt"] as? Timestamp
        self.init(
            id: id,
            noteId: noteId,
            summary: summary,
            createdAt: timestamp?.dateValue(),
            title: title
        )
    }
}


