import SwiftUI

struct CreateFlashcardSetView: View {
    @State private var setName: String = ""
    @State private var cards: [(String, String)] = [("", "")]
    var onSave: (String, [(String, String)]) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text("Create Flashcard Set")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.text)
                    .padding(.top, 16)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set Name")
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    TextField("Enter set name", text: $setName)
                        .padding(10)
                        .background(AppColors.card)
                        .cornerRadius(8)
                        .foregroundColor(AppColors.text)
                    ForEach(cards.indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Question \(idx + 1)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.text.opacity(0.7))
                                Spacer()
                                if cards.count > 1 {
                                    Button(action: { cards.remove(at: idx) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            TextField("Enter question", text: Binding(
                                get: { cards[idx].0 },
                                set: { cards[idx].0 = $0 }
                            ))
                            .padding(10)
                            .background(AppColors.card)
                            .cornerRadius(8)
                            .foregroundColor(AppColors.text)
                            Text("Answer \(idx + 1)")
                                .font(.caption)
                                .foregroundColor(AppColors.text.opacity(0.7))
                            TextField("Enter answer", text: Binding(
                                get: { cards[idx].1 },
                                set: { cards[idx].1 = $0 }
                            ))
                            .padding(10)
                            .background(AppColors.card)
                            .cornerRadius(8)
                            .foregroundColor(AppColors.text)
                        }
                        .padding(.vertical, 6)
                    }
                    Button(action: { cards.append(("", "")) }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Another Card")
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 20)
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.red)
                        .padding()
                        .background(AppColors.card)
                        .cornerRadius(8)
                    Button("Save") {
                        let filtered = cards.filter { !$0.0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.1.trimmingCharacters(in: .whitespaces).isEmpty }
                        onSave(setName, filtered)
                    }
                    .foregroundColor(AppColors.text)
                    .padding()
                    .background(AppColors.accent)
                    .cornerRadius(8)
                    .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty || cards.allSatisfy { $0.0.trimmingCharacters(in: .whitespaces).isEmpty || $0.1.trimmingCharacters(in: .whitespaces).isEmpty })
                    .opacity((setName.trimmingCharacters(in: .whitespaces).isEmpty || cards.allSatisfy { $0.0.trimmingCharacters(in: .whitespaces).isEmpty || $0.1.trimmingCharacters(in: .whitespaces).isEmpty }) ? 0.6 : 1)
                }
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
        }
    }
} 