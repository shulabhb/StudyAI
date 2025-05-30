import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
import PDFKit

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var showFileImporter = false
    @State private var importedURL: URL? = nil
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var noteTitle = ""
    @State private var showTitlePrompt = false
    @State private var summaryType = "medium"

    let summaryOptions = ["short", "medium", "detailed", "academic"]

    var body: some View {
        VStack(spacing: 20) {
            Text("📄 Scan PDF Notes")
                .font(.title)
                .fontWeight(.semibold)

            Button(action: { showFileImporter = true }) {
                Label("Import PDF", systemImage: "doc")
            }
            .buttonStyle(.bordered)

            Section(header: Text("Summary Type")) {
                Picker("Summary Type", selection: $summaryType) {
                    ForEach(summaryOptions, id: \.self) { option in
                        Text(option.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }

            Button("Save & Summarize") {
                // only present sheet if we've already imported a URL
                if importedURL != nil {
                    showTitlePrompt = true
                } else {
                    showFileImporter = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isUploading)

            if isUploading {
                ProgressView("Uploading...")
            }

            if uploadSuccess {
                Text("✅ Uploaded & saved!")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                importedURL = url
                showTitlePrompt = true
            case .failure(let error):
                print("❌ Failed to import PDF: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showTitlePrompt) {
            VStack(spacing: 20) {
                Text("Name your note")
                    .font(.headline)

                TextField("Enter a title...", text: $noteTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Upload & Save") {
                    showTitlePrompt = false
                    if let url = importedURL {
                        uploadRawPDF(url: url)
                    }
                }
                .padding()
                .buttonStyle(.borderedProminent)

                Button("Cancel", role: .cancel) {
                    showTitlePrompt = false
                }
            }
            .presentationDetents([.height(250)])
            .padding()
        }
    }

    private func uploadRawPDF(url: URL) {
        isUploading = true
        uploadSuccess = false

        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ Not logged in.")
            isUploading = false
            return
        }
        guard let pdfData = try? Data(contentsOf: url) else {
            print("❌ Couldn't read PDF data")
            isUploading = false
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000/upload_pdf")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        appendField("user_id", userID)
        appendField("title", noteTitle)
        appendField("summary_type", summaryType)

        // file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"note.pdf\"\r\n")
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(pdfData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isUploading = false }

            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("❌ No data returned from server.")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: String].self, from: data)
                guard
                  let raw = decoded["raw_text"],
                  let summary = decoded["summary"]
                else {
                    print("❌ Missing keys in response JSON.")
                    return
                }

                NoteService.saveNote(name: noteTitle,
                                     content: raw,
                                     summary: summary,
                                     source: "pdf") { err in
                    DispatchQueue.main.async {
                        if let err = err {
                            print("❌ Firestore error: \(err.localizedDescription)")
                        } else {
                            // switch to Summaries tab and pop back
                            appState.selectedTab = .summaries
                            uploadSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            } catch {
                print("❌ JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
