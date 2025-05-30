//
//  SummaryView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//
import SwiftUI

struct SummaryView: View {
    @State private var summaries: [Summary] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Summaries...")
                } else if summaries.isEmpty {
                    Text("No summaries available yet.")
                        .foregroundColor(.gray)
                } else {
                    List(summaries) { summary in
                        NavigationLink(destination: EditNoteView(noteId: summary.noteId)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("📝 Note ID: \(summary.noteId)")
                                    .font(.headline)
                                Text(summary.summary)
                                    .font(.body)
                                    .lineLimit(3)
                                if let date = summary.createdAt {
                                    Text("🕒 \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Summaries")
        }
        .onAppear {
            SummaryService.fetchSummaries { results in
                summaries = results
                isLoading = false
            }
        }
    }
}
