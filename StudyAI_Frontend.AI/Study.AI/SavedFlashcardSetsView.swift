//
//  SavedFlashcardSetsView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI

struct SavedFlashcardSetsView: View {
    @State private var flashcardSets: [FlashcardSet] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedSet: FlashcardSet? = nil
    @State private var path: [FlashcardSet] = []
    @State private var showCreateFlashcard = false
    @State private var createFlashcardSetName: String = ""
    @State private var createFlashcardQuestion: String = ""
    @State private var createFlashcardAnswer: String = ""

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Saved Flashcard Sets")
                            .font(.custom("AvenirNext-UltraLight", size: 26))
                            .foregroundColor(AppColors.text)
                        Spacer()
                        Button(action: { showCreateFlashcard = true }) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(AppColors.accent)
                                .padding(8)
                                .background(AppColors.card)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Create Flashcard")
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 20)
                    
                    if isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            Text("Loading flashcard sets...")
                                .foregroundColor(AppColors.text.opacity(0.7))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("Error loading flashcard sets")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(error)
                                .foregroundColor(AppColors.text.opacity(0.7))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                fetchFlashcardSets()
                            }
                            .foregroundColor(AppColors.accent)
                            .padding()
                            .background(AppColors.card)
                            .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        Spacer()
                    } else if flashcardSets.isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "rectangle.stack")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.text.opacity(0.3))
                                Text("No flashcard sets yet")
                                    .foregroundColor(AppColors.text.opacity(0.7))
                                    .font(.title3)
                                Text("Create your first flashcard set from the dashboard")
                                    .foregroundColor(AppColors.text.opacity(0.5))
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(flashcardSets) { set in
                                    Button(action: {
                                        path.append(set)
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(set.name)
                                                    .font(.headline)
                                                    .foregroundColor(AppColors.text)
                                                Spacer()
                                                Text("\(set.flashcardCount) cards")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.text.opacity(0.6))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(AppColors.accent.opacity(0.2))
                                                    .cornerRadius(8)
                                            }
                                            
                                            if let noteTitle = set.noteTitle {
                                                Text("From: \(noteTitle)")
                                                    .font(.subheadline)
                                                    .foregroundColor(AppColors.text.opacity(0.7))
                                            }
                                            
                                            Text(formatDate(set.createdAt))
                                                .font(.caption)
                                                .foregroundColor(AppColors.text.opacity(0.5))
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppColors.card)
                                        .cornerRadius(14)
                                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 10)
                        }
                    }
                }
            }
            .onAppear(perform: fetchFlashcardSets)
            .navigationDestination(for: FlashcardSet.self) { set in
                SavedFlashcardReviewView(flashcardSet: set)
            }
            .sheet(isPresented: $showCreateFlashcard) {
                CreateFlashcardSetView(
                    onSave: { setName, cards in
                        saveCustomFlashcardSet(setName: setName, cards: cards)
                        showCreateFlashcard = false
                    },
                    onCancel: { showCreateFlashcard = false }
                )
            }
        }
    }

    private func fetchFlashcardSets() {
        isLoading = true
        errorMessage = nil
        
        FlashcardService.shared.getFlashcardSets { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sets):
                    self.flashcardSets = sets
                    print("📚 Fetched \(sets.count) flashcard sets")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching flashcard sets: \(error)")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Unknown date"
    }

    private func saveCustomFlashcardSet(setName: String, cards: [(String, String)]) {
        let flashcards = cards.map { FlashcardData(id: UUID().uuidString, question: $0.0, answer: $0.1) }
        FlashcardService.shared.createFlashcardSet(setName: setName, flashcards: flashcards) { _ in
            fetchFlashcardSets()
        }
    }
} 