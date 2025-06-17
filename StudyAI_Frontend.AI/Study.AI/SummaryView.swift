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
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(summary.title ?? note?.title ?? "Untitled")
                        .font(.custom("AvenirNext-UltraLight", size: 28))
                        .foregroundColor(AppColors.text)
                        .padding(.bottom, 8)
                    Text(summary.summary)
                        .foregroundColor(AppColors.text)
                        .font(.system(size: 17))
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(12)
                        .contextMenu {
                            Button("Copy Summary") {
                                UIPasteboard.general.string = summary.summary
                                showCopyAlert = true
                            }
                            Button("Share as PDF") {
                                showShareSheet = true
                            }
                        }
                    if let note = note {
                        DisclosureGroup("Show Original Note") {
                            Text(note.content)
                                .foregroundColor(AppColors.text)
                                .padding()
                                .background(AppColors.card)
                                .cornerRadius(12)
                                .contextMenu {
                                    Button("Copy Note") {
                                        UIPasteboard.general.string = note.content
                                        showCopyAlert = true
                                    }
                                }
                        }
                        .accentColor(AppColors.accent)
                        .padding(.top, 12)
                    }
                }
                .padding()
            }
            .alert(isPresented: $showCopyAlert) {
                Alert(title: Text("Copied!"), message: nil, dismissButton: .default(Text("OK")))
            }
            // Add share sheet logic if needed
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
        guard !isDeleting else { return }
        isDeleting = true
        offsets.forEach { index in
            let summary = summaries[index]
            SummaryService.deleteSummaryViaBackend(summaryId: summary.id) { _ in
                DispatchQueue.main.async {
                    isDeleting = false
                }
            }
        }
    }
}
