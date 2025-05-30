//  PasteNoteView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/27/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PasteNoteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var summaryType = "medium"
    @State private var isSummarizing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    let summaryOptions = ["short", "medium", "detailed", "academic"]

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Enter title", text: $noteTitle)
            }

            Section(header: Text("Paste Your Note Here")) {
                TextEditor(text: $noteContent)
                    .frame(minHeight: 200)
            }

            Section(header: Text("Summary Type")) {
                Picker("Summary Type", selection: $summaryType) {
                    ForEach(summaryOptions, id: \.self) { opt in
                        Text(opt.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            if let message = successMessage {
                Section { Text("✅ \(message)").foregroundColor(.green) }
            }
            if let error = errorMessage {
                Section { Text("❌ \(error)").foregroundColor(.red) }
            }

            Button(action: summarizeAndSave) {
                if isSummarizing {
                    ProgressView("Summarizing...")
                } else {
                    Text("Save & Summarize")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Paste Note")
    }

    private func summarizeAndSave() {
        guard !noteTitle.isEmpty, !noteContent.isEmpty else {
            errorMessage = "Title and content can't be empty."
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        isSummarizing = true
        errorMessage = nil
        successMessage = nil

        let url = URL(string: "http://127.0.0.1:8000/summarize_raw")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        let formFields: [(String, String)] = [
            ("content", noteContent),
            ("user_id", userId),
            ("title", noteTitle),
            ("summary_type", summaryType)
        ]
        for (k, v) in formFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n")
            body.append("\(v)\r\n")
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isSummarizing = false }

            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            guard
              let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let summary = json["summary"]
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid backend response."
                }
                return
            }

            let db = Firestore.firestore()
            let noteId = UUID().uuidString
            let summaryId = UUID().uuidString
            let timestamp = Timestamp()

            let noteData: [String: Any] = [
                "name": noteTitle,
                "content": noteContent,
                "summary": summary,
                "source": "text",
                "createdAt": timestamp,
                "summaryId": summaryId
            ]
            let summaryData: [String: Any] = [
                "noteId": noteId,
                "summary": summary,
                "createdAt": timestamp
            ]

            let noteRef = db.collection("users")
                             .document(userId)
                             .collection("notes")
                             .document(noteId)
            let summaryRef = db.collection("users")
                                .document(userId)
                                .collection("summaries")
                                .document(summaryId)

            db.batch()
              .setData(noteData, forDocument: noteRef)
              .setData(summaryData, forDocument: summaryRef)
              .commit { error in
                  DispatchQueue.main.async {
                      if let error = error {
                          self.errorMessage = error.localizedDescription
                      } else {
                          // flip to Summaries tab
                          appState.selectedTab = .summaries

                          self.successMessage = "Note and summary saved."
                          self.noteContent = ""
                          self.noteTitle = ""
                          DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                              presentationMode.wrappedValue.dismiss()
                          }
                      }
                  }
              }
        }
        .resume()
    }
}

// Helper to build multipart bodies
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
