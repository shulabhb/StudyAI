import SwiftUI

// Moved from SavedFlashcardSetsView.swift
struct EditCardsSheet: View {
    @State var flashcards: [FlashcardData]
    var onUpdate: ([FlashcardData]) -> Void
    var onCancel: () -> Void
    @State private var editingId: String? = nil
    @State private var showEditSheet = false
    @State private var editCard: FlashcardData? = nil
    @State private var showAddSheet = false
    @State private var newQuestion = ""
    @State private var newAnswer = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Edit Flashcards")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.text)
                    .padding(.top, 16)
                List {
                    ForEach(flashcards, id: \.id) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Q: \(card.question)")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                            Text("A: \(card.answer)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.text.opacity(0.7))
                            HStack(spacing: 16) {
                                Button(action: {
                                    editCard = card
                                    editingId = card.id
                                    showEditSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .foregroundColor(AppColors.accent)
                                    .padding(6)
                                    .background(AppColors.card)
                                    .cornerRadius(8)
                                }
                                Button(action: {
                                    if let idx = flashcards.firstIndex(where: { $0.id == card.id }) {
                                        flashcards.remove(at: idx)
                                        onUpdate(flashcards)
                                        if flashcards.isEmpty {
                                            onCancel()
                                        }
                                        if editingId == card.id {
                                            editingId = nil
                                            editCard = nil
                                            showEditSheet = false
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                    .foregroundColor(.red)
                                    .padding(6)
                                    .background(AppColors.card)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .listRowBackground(AppColors.background)
                    }
                }
                .listStyle(.plain)
                .background(AppColors.background)
                Button(action: { showAddSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Card")
                    }
                    .foregroundColor(AppColors.accent)
                    .padding(.vertical, 8)
                }
                HStack(spacing: 16) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.red)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                }
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .sheet(isPresented: $showEditSheet) {
                if let id = editingId, let idx = flashcards.firstIndex(where: { $0.id == id }), let card = editCard {
                    EditFlashcardSheet(
                        flashcard: card,
                        onSave: { updated in
                            flashcards[idx] = updated
                            onUpdate(flashcards)
                            showEditSheet = false
                        },
                        onCancel: { showEditSheet = false }
                    )
                }
            }
            .sheet(isPresented: $showAddSheet) {
                VStack(spacing: 18) {
                    Text("Add Flashcard")
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question")
                            .font(.caption)
                            .foregroundColor(AppColors.text.opacity(0.7))
                        TextEditor(text: $newQuestion)
                            .frame(minHeight: 60, maxHeight: 100)
                            .padding(10)
                            .background(AppColors.card)
                            .foregroundColor(AppColors.text)
                            .cornerRadius(8)
                        Text("Answer")
                            .font(.caption)
                            .foregroundColor(AppColors.text.opacity(0.7))
                        TextEditor(text: $newAnswer)
                            .frame(minHeight: 60, maxHeight: 100)
                            .padding(10)
                            .background(AppColors.card)
                            .foregroundColor(AppColors.text)
                            .cornerRadius(8)
                    }
                    HStack(spacing: 16) {
                        Button("Cancel", action: { showAddSheet = false })
                            .foregroundColor(.red)
                        Button("Add") {
                            let newCard = FlashcardData(id: UUID().uuidString, question: newQuestion, answer: newAnswer)
                            flashcards.append(newCard)
                            onUpdate(flashcards)
                            showAddSheet = false
                            newQuestion = ""
                            newAnswer = ""
                        }
                        .foregroundColor(AppColors.text)
                        .disabled(newQuestion.trimmingCharacters(in: .whitespaces).isEmpty || newAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity((newQuestion.trimmingCharacters(in: .whitespaces).isEmpty || newAnswer.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1)
                    }
                }
                .padding(24)
                .background(AppColors.card)
                .cornerRadius(18)
                .shadow(radius: 20)
                .frame(maxWidth: 400)
            }
        }
        .background(AppColors.background)
    }
} 