//
//  EditNoteView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PDFKit
import UIKit

struct EditNoteView: View {
    let noteId: String
    @State private var content: String = ""
    @State private var title: String = ""
    @State private var createdAt: Date? = nil

    @State private var summaries: [Summary] = []
    @State private var summary: String = "" // For editing the first summary
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showContent: Bool = false
    @State private var isEditingSummary: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showCopyConfirmation: Bool = false
    @State private var pdfToShare: Data? = nil
    @State private var showShareSheet: Bool = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // MARK: - Title Field (always editable)
                    TextField("Enter note title", text: $title)
                        .font(.title2.weight(.semibold))
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.top)

                    // MARK: - Meta Info Row
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                        if let createdAt = createdAt {
                            Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(summary.wordCount) words")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // MARK: - Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUMMARY")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 2)
                        if summaries.isEmpty {
                            Text("No summary available.")
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(14)
                                .frame(minHeight: 120, maxHeight: 300)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            // Show all summaries for this note
                            ForEach(summaries) { summaryObj in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(summaryObj.summary)
                                            .font(.body)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        Spacer()
                                        Button(action: {
                                            UIPasteboard.general.string = summaryObj.summary
                                            showCopyConfirmation = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                                showCopyConfirmation = false
                                            }
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.accentColor)
                                                .padding(.horizontal, 4)
                                        }
                                        Button(action: {
                                            if let pdfData = generatePDF(from: summaryObj.summary) {
                                                pdfToShare = pdfData
                                                showShareSheet = true
                                            }
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.accentColor)
                                                .padding(.horizontal, 4)
                                        }
                                    }
                                    if let date = summaryObj.createdAt {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            // Edit button for the first summary
                            if !isEditingSummary {
                                Button(action: { isEditingSummary = true }) {
                                    Label("Edit Summary", systemImage: "pencil")
                                        .font(.subheadline)
                                        .padding(.top, 6)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: $summary)
                                        .padding(8)
                                        .background(AppColors.card)
                                        .foregroundColor(AppColors.text)
                                        .cornerRadius(12)
                                    HStack {
                                        Button("Cancel") {
                                            isEditingSummary = false
                                            // Reset to original summary
                                            if let first = summaries.first {
                                                summary = first.summary
                                            }
                                        }
                                        .foregroundColor(.red)
                                        Spacer()
                                        Button("Save") {
                                            saveSummaryEdit()
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        if showCopyConfirmation {
                            Text("Copied!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // MARK: - Show/Hide Note Content Button
                    Button(action: { withAnimation { showContent.toggle() } }) {
                        HStack {
                            Image(systemName: showContent ? "chevron.down" : "chevron.right")
                            Text(showContent ? "Hide Full Note" : "Show Full Note")
                        }
                        .font(.body.weight(.semibold))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // MARK: - Content Reveal Section
                    if showContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONTENT")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            ScrollView {
                                Text(content.isEmpty ? "No content available." : content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(12)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor.opacity(0.13), lineWidth: 1)
                            )
                            .frame(minHeight: 100)
                            .padding(.bottom, 2)
                            Button(action: {
                                UIPasteboard.general.string = content
                            }) {
                                Label("Copy Content", systemImage: "doc.on.doc")
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }

                    // Error/Success messages
                    if let error = errorMessage {
                        Text("❌ \(error)").foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 2)
                    }
                    if let message = successMessage {
                        Text("✅ \(message)").foregroundColor(.green)
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadNoteAndSummaries() }
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfToShare {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .background(AppColors.background)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Data Loading (from Notes and Summaries)
    private func loadNoteAndSummaries() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("notes").document(noteId).getDocument { doc, err in
            if let data = doc?.data() {
                self.content = data["content"] as? String ?? ""
                self.title = data["name"] as? String ?? ""
                if let ts = data["createdAt"] as? Timestamp {
                    self.createdAt = ts.dateValue()
                }
            } else {
                self.errorMessage = err?.localizedDescription ?? "Note not found."
            }
        }
        // Fetch summaries for this note
        SummaryService.fetchSummaries { allSummaries in
            let filtered = allSummaries.filter { $0.noteId == noteId }
            self.summaries = filtered
            // For editing, load the first summary (if any)
            if let first = filtered.first {
                self.summary = first.summary
            }
        }
    }

    // MARK: - Save Logic (update title & summary)
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        // Only update the note title (not summary inline)
        let updatedData: [String: Any] = [
            "name": title
        ]
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
        // Optionally, update the first summary (if any)
        if let firstSummary = summaries.first {
            db.collection("users").document(userId).collection("summaries").document(firstSummary.id).updateData(["summary": summary]) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Add a function to save summary edits
    private func saveSummaryEdit() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        if let firstSummary = summaries.first {
            db.collection("users").document(userId).collection("summaries").document(firstSummary.id).updateData(["summary": summary]) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.successMessage = "Summary updated."
                    isEditingSummary = false
                    // Update local copy
                    if let idx = summaries.firstIndex(where: { $0.id == firstSummary.id }) {
                        summaries[idx] = Summary(id: firstSummary.id, noteId: firstSummary.noteId, summary: summary, createdAt: firstSummary.createdAt, title: firstSummary.title)
                    }
                }
            }
        }
    }

    // PDF generation helper
    private func generatePDF(from text: String) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Study.AI",
            kCGPDFContextAuthor: "Study.AI User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageWidth = 595.2
        let pageHeight = 841.8
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let textRect = CGRect(x: 32, y: 32, width: pageWidth - 64, height: pageHeight - 64)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraphStyle
            ]
            text.draw(in: textRect, withAttributes: attrs)
        }
        return data
    }
}

// MARK: - Helper: Word Count Extension
private extension String {
    var wordCount: Int {
        return split { $0.isWhitespace || $0.isNewline }.count
    }
}

// ShareSheet helper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
