import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
import PDFKit

struct ScanCardView: View {
    @Binding var showFileImporter: Bool
    @Binding var importedURL: URL?
    @Binding var showTitlePrompt: Bool
    @Binding var isUploading: Bool
    @Binding var uploadSuccess: Bool
    @Binding var errorMessage: String?
    @Binding var noteTitle: String
    let uploadRawPDF: (URL) -> Void

    var body: some View {
        VStack(spacing: 28) {
            Text("📄 Scan PDF Notes")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            Button(action: { showFileImporter = true }) {
                HStack {
                    Image(systemName: "doc")
                    Text("Import PDF")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.card)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 8)
            if isUploading {
                ProgressView("Uploading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            if uploadSuccess {
                Text("✅ Uploaded & saved!")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 8)
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .background(AppColors.card.opacity(0.15))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 18)
    }
}

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var showFileImporter = false
    @State private var importedURL: URL? = nil
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var noteTitle = ""
    @State private var showTitlePrompt = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack {
                Spacer(minLength: 40)
                ScanCardView(
                    showFileImporter: $showFileImporter,
                    importedURL: $importedURL,
                    showTitlePrompt: $showTitlePrompt,
                    isUploading: $isUploading,
                    uploadSuccess: $uploadSuccess,
                    errorMessage: $errorMessage,
                    noteTitle: $noteTitle,
                    uploadRawPDF: uploadRawPDF
                )
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Scan Notes")
                        .font(.custom("AvenirNext-UltraLight", size: 22))
                        .foregroundColor(.white)
                }
            }
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
                        .foregroundColor(.white)
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
                .background(AppColors.background)
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func uploadRawPDF(url: URL) {
        isUploading = true
        uploadSuccess = false

        guard let userID = Auth.auth().currentUser?.uid else {
            showErrorAlert(message: "Not logged in.")
            isUploading = false
            return
        }
        guard let pdfData = try? Data(contentsOf: url) else {
            showErrorAlert(message: "Couldn't read PDF data.")
            isUploading = false
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/upload_pdf")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendFormField(named: "user_id", value: userID, using: boundary)
        body.appendFormField(named: "title", value: noteTitle, using: boundary)

        // file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"note.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isUploading = false }

            if let error = error {
                showErrorAlert(message: "Upload failed: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                showErrorAlert(message: "No data returned from server.")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: String].self, from: data)
                guard let summaryId = decoded["summary_id"] else {
                    showErrorAlert(message: "Missing summary ID in response JSON.")
                    return
                }
                // switch to Summaries tab and pop back
                DispatchQueue.main.async {
                    appState.newSummaryId = summaryId
                    appState.selectedTab = .summaries
                    uploadSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                showErrorAlert(message: "JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Helper to show error alerts
    private func showErrorAlert(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
