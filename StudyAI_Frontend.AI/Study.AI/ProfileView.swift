//
//  ProfileView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/8/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var age = ""
    @State private var country = "United States"
    @State private var email = ""
    @State private var birthDate = Date()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""

    @State private var isEditingUsername = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Form {
                        Section {
                            HStack {
                                Spacer()
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)
                                    .padding(.vertical)
                                Spacer()
                            }
                        }
                        .listRowBackground(AppColors.card)
                        Section(header: Text("Personal Info")
                            .font(.custom("AvenirNext-UltraLight", size: 18))
                            .foregroundColor(AppColors.text.opacity(0.8))) {
                            TextField("First Name", text: $firstName)
                                .foregroundColor(AppColors.text)
                                .disabled(true)
                            TextField("Last Name", text: $lastName)
                                .foregroundColor(AppColors.text)
                                .disabled(true)
                            HStack {
                                if isEditingUsername {
                                    TextField("Username", text: $username)
                                        .foregroundColor(AppColors.text)
                                    Button(action: {
                                        confirmUsernameEdit()
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text(username)
                                        .foregroundColor(AppColors.text)
                                    Button(action: {
                                        isEditingUsername = true
                                    }) {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(AppColors.accent)
                                    }
                                }
                            }
                            HStack {
                                Text("Country")
                                    .foregroundColor(AppColors.text)
                                Spacer()
                                Text(countryFlagEmoji(for: country) + " " + country)
                                    .foregroundColor(AppColors.text.opacity(0.7))
                            }
                            DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                                .accentColor(AppColors.accent)
                                .colorScheme(.dark)
                                .foregroundColor(AppColors.text)
                                .disabled(true)
                                .onChange(of: birthDate) { newValue in
                                    birthDate = Calendar.current.startOfDay(for: newValue)
                                }
                        }
                        .listRowBackground(AppColors.card)
                        Section(header: Text("Account")
                            .font(.custom("AvenirNext-UltraLight", size: 18))
                            .foregroundColor(AppColors.text.opacity(0.8))) {
                            Text(email).foregroundColor(AppColors.text.opacity(0.7))
                            Button("Reset Password") {
                                resetPassword()
                            }
                            .foregroundColor(AppColors.accent)
                        }
                        .listRowBackground(AppColors.card)
                        Section(header: Text("Change Password")
                            .font(.custom("AvenirNext-UltraLight", size: 18))
                            .foregroundColor(AppColors.text.opacity(0.8))) {
                            SecureField("Current Password", text: $currentPassword)
                                .textContentType(.password)
                                .foregroundColor(AppColors.text)
                                .placeholder(when: currentPassword.isEmpty) {
                                    Text("Current Password").foregroundColor(AppColors.text.opacity(0.5))
                                }
                            SecureField("New Password", text: $newPassword)
                                .textContentType(.newPassword)
                                .foregroundColor(AppColors.text)
                                .placeholder(when: newPassword.isEmpty) {
                                    Text("New Password").foregroundColor(AppColors.text.opacity(0.5))
                                }
                            SecureField("Confirm New Password", text: $confirmNewPassword)
                                .textContentType(.newPassword)
                                .foregroundColor(AppColors.text)
                                .placeholder(when: confirmNewPassword.isEmpty) {
                                    Text("Confirm New Password").foregroundColor(AppColors.text.opacity(0.5))
                                }
                            Button("Update Password") {
                                updatePassword()
                            }
                            .foregroundColor(AppColors.accent)
                        }
                        .listRowBackground(AppColors.card)
                        if let error = errorMessage {
                            Section {
                                Text("❌ \(error)").foregroundColor(.red)
                            }
                            .listRowBackground(AppColors.card)
                        }
                        if let message = successMessage {
                            Section {
                                Text("✅ \(message)").foregroundColor(.green)
                            }
                            .listRowBackground(AppColors.card)
                        }
                    }
                    .background(AppColors.background)
                    .scrollContentBackground(.hidden)
                    .accentColor(AppColors.accent)
                    .tint(AppColors.accent)
                    .frame(maxWidth: 700)
                    .padding(.horizontal, 0)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.custom("AvenirNext-UltraLight", size: 24))
                        .foregroundColor(AppColors.text)
                }
            }
            .onAppear {
                loadUserProfile()
            }
        }
    }

    // MARK: - Firestore Load
    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.username = data["username"] as? String ?? ""
                self.country = data["country"] as? String ?? "United States"
                self.email = data["email"] as? String ?? ""
                if let dob = data["dateOfBirth"] as? Timestamp {
                    let date = dob.dateValue()
                    self.birthDate = Calendar.current.startOfDay(for: date)
                }
                self.isLoading = false
            } else {
                self.errorMessage = error?.localizedDescription ?? "Failed to load profile."
                self.isLoading = false
            }
        }
    }

    // MARK: - Firestore Save
    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let updatedData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "username": username,
            "dateOfBirth": Timestamp(date: birthDate)
            // Note: country is not included as it's now unchangeable
        ]

        Firestore.firestore().collection("users").document(uid).updateData(updatedData) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Profile updated successfully."
                self.appState.username = username // Update app state
            }
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            self.errorMessage = "Email is not available for password reset."
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = "Password reset failed: \(error.localizedDescription)"
            } else {
                self.successMessage = "Password reset email sent."
            }
        }
    }

    private func updatePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, newPassword == confirmNewPassword else {
            self.errorMessage = "Please check password fields."
            return
        }

        guard let user = Auth.auth().currentUser, let email = user.email else {
            self.errorMessage = "User not logged in."
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                self.errorMessage = "Reauthentication failed: \(error.localizedDescription)"
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.errorMessage = "Password update failed: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Password updated successfully."
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.confirmNewPassword = ""
                }
            }
        }
    }

    private var countryList: [String] {
        let recommended = ["United States"]
        let others = Locale.Region.isoRegions.compactMap {
            Locale.current.localizedString(forRegionCode: $0.identifier)
        }.sorted()
        return recommended + others.filter { !recommended.contains($0) }
    }

    private func countryFlagEmoji(for countryName: String) -> String {
        let base : UInt32 = 127397
        var emoji = ""
        let regionCode = (Locale.isoRegionCodes.first { Locale.current.localizedString(forRegionCode: $0) == countryName }) ?? "US"
        for scalar in regionCode.uppercased().unicodeScalars {
            emoji.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
        }
        return emoji
    }

    private func confirmUsernameEdit() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["username": username]) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Username updated successfully."
                self.appState.username = username
                self.isEditingUsername = false
            }
        }
    }

    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: date, to: now)
        return ageComponents.year ?? 0
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
