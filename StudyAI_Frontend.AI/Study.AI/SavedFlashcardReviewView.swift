import SwiftUI

// Moved from SavedFlashcardSetsView.swift
struct SavedFlashcardReviewView: View {
    let flashcardSet: FlashcardSet
    @Environment(\.dismiss) var dismiss
    @State private var flashcardDetails: FlashcardSetDetail? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var currentIndex: Int = 0
    @State private var isFlipped = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var editCard: FlashcardData? = nil
    @State private var showDeleteCardAlert = false
    @State private var deleteCardIdx: Int? = nil
    @State private var showEditCardsSheet = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    Spacer()
                    Text(flashcardSet.name)
                        .font(.custom("AvenirNext-UltraLight", size: 24))
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Button(action: { showEditCardsSheet = true }) {
                        Image(systemName: "pencil")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.accent)
                            .padding(8)
                            .background(AppColors.card)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Edit Cards")
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                            .padding(8)
                            .background(AppColors.card)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Delete Set")
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView("Loading flashcards...")
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            .foregroundColor(AppColors.text)
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundColor(AppColors.text.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Error loading flashcards")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text(error)
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.accent)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                } else if let details = flashcardDetails, let flashcards = details.flashcards, !flashcards.isEmpty {
                    Spacer()
                    ZStack {
                        ForEach(flashcards.indices, id: \ .self) { idx in
                            if idx == currentIndex {
                                VStack(spacing: 0) {
                                    FlashcardCardView(
                                        flashcard: Flashcard(
                                            id: flashcards[idx].id,
                                            question: flashcards[idx].question,
                                            answer: flashcards[idx].answer
                                        ),
                                        isFlipped: $isFlipped
                                    )
                                    .transition(.scale)
                                    .onTapGesture { isFlipped.toggle() }
                                    .animation(.spring(), value: isFlipped)
                                }
                            }
                        }
                    }
                    .frame(height: 260)

                    HStack(spacing: 24) {
                        Button(action: prevCard) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(AppColors.accent)
                        }
                        Text("\(currentIndex + 1) of \(flashcards.count)")
                            .font(.caption)
                            .foregroundColor(AppColors.text.opacity(0.7))
                        Button(action: nextCard) {
                            Image(systemName: "chevron.right")
                                .font(.title2.bold())
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("No flashcards found in this set.")
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .font(.title3)
                            .padding()
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.accent)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                    }
                    Spacer()
                }
            }
            .padding(20)
        }
        .onAppear(perform: loadFlashcardSet)
        .alert("Delete Flashcard Set?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSet() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this flashcard set? This cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            if let card = editCard {
                EditFlashcardSheet(
                    flashcard: card,
                    onSave: { updated in
                        updateCard(updated)
                        showEditSheet = false
                    },
                    onCancel: { showEditSheet = false }
                )
            }
        }
        .sheet(isPresented: $showEditCardsSheet) {
            if let details = flashcardDetails, let flashcards = details.flashcards {
                EditCardsSheet(
                    flashcards: flashcards,
                    onUpdate: { updatedCards in
                        FlashcardService.shared.updateFlashcardSet(setId: flashcardSet.id, flashcards: updatedCards.map { Flashcard(id: $0.id, question: $0.question, answer: $0.answer) }) { _ in
                            loadFlashcardSet()
                        }
                    },
                    onCancel: { showEditCardsSheet = false }
                )
            }
        }
    }

    private func loadFlashcardSet() {
        isLoading = true
        errorMessage = nil
        FlashcardService.shared.getFlashcardSet(setId: flashcardSet.id) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let details):
                    self.flashcardDetails = details
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func prevCard() {
        guard let details = flashcardDetails, let flashcards = details.flashcards, !flashcards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + flashcards.count) % flashcards.count
        isFlipped = false
    }

    private func nextCard() {
        guard let details = flashcardDetails, let flashcards = details.flashcards, !flashcards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % flashcards.count
        isFlipped = false
    }

    private func deleteSet() {
        FlashcardService.shared.deleteFlashcardSet(setId: flashcardSet.id) { _ in
            dismiss()
        }
    }

    private func updateCard(_ updated: FlashcardData) {
        guard let details = flashcardDetails, let flashcards = details.flashcards else { return }
        var newFlashcards = flashcards
        if let idx = newFlashcards.firstIndex(where: { $0.id == updated.id }) {
            newFlashcards[idx] = updated
            FlashcardService.shared.updateFlashcardSet(setId: flashcardSet.id, flashcards: newFlashcards.map { Flashcard(id: $0.id, question: $0.question, answer: $0.answer) }) { _ in
                loadFlashcardSet()
            }
        }
    }
} 