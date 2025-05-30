//
//  EditNoteView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditNoteView: View {
    let noteId: String
    @State private var content: String = ""
    @State private var summary: String = ""
    @State private var title: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Enter note title", text: $title)
            }

            Section(header: Text("Content")) {
                TextEditor(text: $content)
                    .frame(minHeight: 120)
            }

            Section(header: Text("Summary")) {
                TextEditor(text: $summary)
                    .frame(minHeight: 100)
            }

            if let error = errorMessage {
                Section {
                    Text("❌ \(error)").foregroundColor(.red)
                }
            }

            if let message = successMessage {
                Section {
                    Text("✅ \(message)").foregroundColor(.green)
                }
            }

            Button("Save Changes") {
                saveChanges()
            }
        }
        .navigationTitle("Edit Note")
        .onAppear {
            loadNote()
        }
    }

    private func loadNote() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // 🔹 Load the main note
        db.collection("users").document(userId).collection("notes").document(noteId).getDocument { doc, err in
            if let data = doc?.data() {
                self.content = data["content"] as? String ?? ""
                self.title = data["name"] as? String ?? "" // fixed from "title"
            } else {
                self.errorMessage = err?.localizedDescription ?? "Note not found."
            }
        }

        // 🔹 Load the summary from the summaries subcollection
        db.collection("users").document(userId).collection("summaries")
            .whereField("noteId", isEqualTo: noteId)
            .getDocuments { snap, err in
                if let doc = snap?.documents.first {
                    self.summary = doc.data()["summary"] as? String ?? ""
                }
            }
    }

    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let updatedData: [String: Any] = [
            "name": title, // updated from "title"
            "content": content
        ]

        // 🔹 Save note content
        db.collection("users").document(userId).collection("notes").document(noteId).updateData(updatedData) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Note updated."
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }

        // 🔹 Save updated summary
        db.collection("users").document(userId).collection("summaries")
            .whereField("noteId", isEqualTo: noteId)
            .getDocuments { snap, err in
                guard let doc = snap?.documents.first else { return }
                doc.reference.updateData(["summary": summary])
            }
    }
}
