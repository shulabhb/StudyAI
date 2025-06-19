//
//  FlashCardView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI

// Main entry point for flashcards tab, now uses modularized views
struct FlashcardView: View {
    @State private var path: [FlashcardRoute] = []
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 36) {
                    Text("Flashcards")
                        .font(.custom("AvenirNext-UltraLight", size: 32))
                        .foregroundColor(AppColors.text)
                        .padding(.top, 24)
                    Spacer()
                    VStack(spacing: 24) {
                        Button(action: { path.append(.existingNotes) }) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 28, weight: .bold))
                                Text("Generate from Existing Notes")
                                    .font(.title3.bold())
                            }
                            .foregroundColor(AppColors.text)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(AppColors.card)
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                        Button(action: { path.append(.pasteNote) }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 28, weight: .bold))
                                Text("Paste New Note")
                                    .font(.title3.bold())
                            }
                            .foregroundColor(AppColors.text)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(AppColors.card)
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                }
            }
            .navigationDestination(for: FlashcardRoute.self) { route in
                switch route {
                case .existingNotes:
                    FlashcardSelectNoteView()
                case .pasteNote:
                    FlashcardPasteNoteView()
                }
            }
        }
    }
}

enum FlashcardRoute: Hashable {
    case existingNotes
    case pasteNote
}
