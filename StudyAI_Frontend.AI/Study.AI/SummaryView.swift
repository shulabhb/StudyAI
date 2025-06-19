//
//  SummaryView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/8/25.
//
import SwiftUI

struct SummaryCardView: View {
    let summary: Summary
    let note: Note?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary.title ?? note?.title ?? "Untitled")
                .font(.custom("AvenirNext-UltraLight", size: 18))
                .foregroundColor(AppColors.text)
            Text(summary.summary)
                .foregroundColor(AppColors.text.opacity(0.9))
                .font(.system(size: 15))
        }
        .padding()
        .background(AppColors.card)
        .cornerRadius(14)
        .listRowInsets(EdgeInsets())
    }
}

struct SummaryDetailView: View {
    let summary: Summary
    let note: Note?
    @State private var showShareSheet = false
    @State private var showCopyAlert = false
    @State private var pdfToShare: Data? = nil
    @State private var exportingSummary = false
    @State private var exportingNote = false
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        if isEditingTitle {
                            TextField("Enter title", text: $editedTitle)
                                .font(.custom("AvenirNext-UltraLight", size: 28))
                                .foregroundColor(AppColors.text)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onSubmit {
                                    saveTitle()
                                }
                        } else {
                            Text(summary.title ?? note?.title ?? "Untitled")
                                .font(.custom("AvenirNext-UltraLight", size: 28))
                                .foregroundColor(AppColors.text)
                        }
                        Spacer()
                        Button(action: {
                            if isEditingTitle {
                                saveTitle()
                            } else {
                                startEditing()
                            }
                        }) {
                            Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle")
                                .font(.system(size: 24))
                                .foregroundColor(isEditingTitle ? .green : AppColors.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    // Summary Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Summary")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = summary.summary
                                showCopyAlert = true
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(AppColors.accent)
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                if let pdfData = generatePDF(from: summary.summary, title: summary.title ?? note?.title ?? "Summary") {
                                    pdfToShare = pdfData
                                    exportingSummary = true
                                    showShareSheet = true
                                }
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(AppColors.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(summary.summary)
                            .foregroundColor(AppColors.text)
                            .font(.system(size: 17))
                            .padding()
                            .background(AppColors.card)
                            .cornerRadius(12)
                    }
                    // Note Section
                    if let note = note {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Original Note")
                                    .font(.headline)
                                    .foregroundColor(AppColors.text)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = note.content
                                    showCopyAlert = true
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(AppColors.accent)
                                }
                                .buttonStyle(.plain)
                                Button(action: {
                                    if let pdfData = generatePDF(from: note.content, title: note.title) {
                                        pdfToShare = pdfData
                                        exportingNote = true
                                        showShareSheet = true
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(AppColors.accent)
                                }
                                .buttonStyle(.plain)
                            }
                            DisclosureGroup("Show Original Note") {
                                Text(note.content)
                                    .foregroundColor(AppColors.text)
                                    .padding()
                                    .background(AppColors.card)
                                    .cornerRadius(12)
                            }
                            .accentColor(AppColors.accent)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
            .alert(isPresented: $showCopyAlert) {
                Alert(title: Text("Copied!"), message: nil, dismissButton: .default(Text("OK")))
            }
            .alert("Title Updated", isPresented: $showSaveAlert) {
                Button("OK") { }
            } message: {
                Text(saveAlertMessage)
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                exportingSummary = false
                exportingNote = false
                pdfToShare = nil
            }) {
                if let pdfData = pdfToShare {
                    ShareSheet(activityItems: [pdfData])
                }
            }
        }
    }
    // Helper to generate PDF from text
    private func generatePDF(from text: String, title: String?) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Study.AI",
            kCGPDFContextAuthor: "Study.AI User",
            kCGPDFContextTitle: title ?? "Exported Note"
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
    
    // MARK: - Title Editing Functions
    private func startEditing() {
        editedTitle = summary.title ?? note?.title ?? "Untitled"
        isEditingTitle = true
    }
    
    private func saveTitle() {
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveAlertMessage = "Title cannot be empty"
            showSaveAlert = true
            return
        }
        
        // Update the summary title in Firestore
        SummaryService.updateSummaryTitle(summaryId: summary.id, newTitle: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)) { success in
            DispatchQueue.main.async {
                if success {
                    saveAlertMessage = "Title updated successfully!"
                    showSaveAlert = true
                    isEditingTitle = false
                } else {
                    saveAlertMessage = "Failed to update title. Please try again."
                    showSaveAlert = true
                }
            }
        }
    }
}

struct SummaryView: View {
    @EnvironmentObject var appState: AppState
    @State private var notes: [Note] = []
    @State private var summaries: [Summary] = []
    @State private var isLoading = true
    @State private var searchText: String = ""
    @State private var isDeleting = false
    @State private var scrollToSummaryId: String? = nil
    @State private var highlightSummaryId: String? = nil

    // Group summaries by noteId
    private var summariesByNoteId: [String: [Summary]] {
        Dictionary(grouping: summaries, by: { $0.noteId })
    }

    // MARK: - Filtered Notes for Search
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                    } else if summaries.isEmpty {
                        Text("No summaries yet.")
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.custom("AvenirNext-UltraLight", size: 20))
                            .padding()
                    } else {
                        ScrollViewReader { proxy in
                            List {
                                ForEach(summaries) { summary in
                                    let note = notes.first(where: { $0.id == summary.noteId })
                                    NavigationLink(destination: SummaryDetailView(summary: summary, note: note)) {
                                        SummaryCardView(summary: summary, note: note)
                                            .background(
                                                highlightSummaryId == summary.id ? Color.yellow.opacity(0.2) : Color.clear
                                            )
                                    }
                                    .listRowBackground(AppColors.card)
                                    .id(summary.id)
                                }
                                .onDelete(perform: deleteSummary)
                            }
                            .listStyle(PlainListStyle())
                            .background(AppColors.background)
                            .scrollContentBackground(.hidden)
                            .onChange(of: appState.newSummaryId) { newId in
                                if let newId = newId {
                                    withAnimation(.easeInOut) {
                                        proxy.scrollTo(newId, anchor: .center)
                                        highlightSummaryId = newId
                                    }
                                    // Remove highlight after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        highlightSummaryId = nil
                                        appState.newSummaryId = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Summaries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Summaries")
                        .font(.custom("AvenirNext-UltraLight", size: 24))
                        .foregroundColor(AppColors.text)
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search notes or summaries"
        )
        .tint(AppColors.text)
        .onAppear {
            fetchNotesAndSummaries()
        }
    }

    // MARK: - Data Fetching
    private func fetchNotesAndSummaries() {
        isLoading = true
        NoteService.fetchNotes { noteResults in
            SummaryService.fetchSummaries { summaryResults in
                notes = noteResults
                summaries = summaryResults
                isLoading = false
            }
        }
    }

    // MARK: - Deletion (calls backend, not Firestore directly!)
    private func deleteSummary(at offsets: IndexSet) {
        let idsToDelete = offsets.map { summaries[$0].id }
        // Remove from UI immediately
        summaries.remove(atOffsets: offsets)
        // Call backend for each summary
        for id in idsToDelete {
            SummaryService.deleteSummaryViaBackend(summaryId: id) { _ in
                // Optionally handle errors here
            }
        }
    }
}
