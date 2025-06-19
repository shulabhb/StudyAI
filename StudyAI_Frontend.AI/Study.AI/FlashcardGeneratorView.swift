//
//  FlashcardGeneratorView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI

struct FlashcardGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedOption: FlashcardOption = .selectNote
    @State private var showSelectNoteView = false
    @State private var showPasteNoteView = false
    @State private var showCreateSet = false
    
    enum FlashcardOption: String, CaseIterable {
        case selectNote = "Select Note"
        case pasteNote = "Paste Note"
        
        var icon: String {
            switch self {
            case .selectNote:
                return "doc.text.magnifyingglass"
            case .pasteNote:
                return "doc.text.viewfinder"
            }
        }
        
        var description: String {
            switch self {
            case .selectNote:
                return "Generate flashcards from your existing notes"
            case .pasteNote:
                return "Paste new text to create flashcards"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create Flashcards")
                            .font(.custom("AvenirNext-UltraLight", size: 28))
                            .foregroundColor(AppColors.text)
                        
                        Text("Choose how you'd like to generate your flashcards")
                            .font(.subheadline)
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Options
                    VStack(spacing: 16) {
                        ForEach(FlashcardOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                if option == .selectNote {
                                    showSelectNoteView = true
                                } else {
                                    showPasteNoteView = true
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: option.icon)
                                        .font(.title2)
                                        .foregroundColor(AppColors.accent)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.rawValue)
                                            .font(.headline)
                                            .foregroundColor(AppColors.text)
                                        
                                        Text(option.description)
                                            .font(.caption)
                                            .foregroundColor(AppColors.text.opacity(0.7))
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.text.opacity(0.5))
                                }
                                .padding()
                                .background(AppColors.card)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Button(action: { showCreateSet = true }) {
                            HStack(spacing: 16) {
                                Image(systemName: "plus.square.on.square")
                                    .font(.title2)
                                    .foregroundColor(AppColors.accent)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create New Flashcard Set")
                                        .font(.headline)
                                        .foregroundColor(AppColors.text)
                                    Text("Manually enter multiple questions and answers")
                                        .font(.caption)
                                        .foregroundColor(AppColors.text.opacity(0.7))
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppColors.text.opacity(0.5))
                            }
                            .padding()
                            .background(AppColors.card)
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Info section
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(AppColors.accent)
                            Text("Pro Tip")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                        }
                        
                        Text("Longer, more detailed notes typically generate better flashcards with more variety and depth.")
                            .font(.caption)
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(AppColors.card.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .fullScreenCover(isPresented: $showSelectNoteView) {
            FlashcardSelectNoteView()
        }
        .fullScreenCover(isPresented: $showPasteNoteView) {
            FlashcardPasteNoteView()
        }
        .sheet(isPresented: $showCreateSet) {
            CreateFlashcardSetView(onSave: { setName, cards in
                createNewFlashcardSet(setName: setName, cards: cards)
                showCreateSet = false
            }, onCancel: { showCreateSet = false })
        }
    }
    
    private func createNewFlashcardSet(setName: String, cards: [(String, String)]) {
        let flashcards = cards.map { FlashcardData(id: UUID().uuidString, question: $0.0, answer: $0.1) }
        FlashcardService.shared.createFlashcardSet(setName: setName, flashcards: flashcards) { _ in }
    }
} 