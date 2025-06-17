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

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
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
                        TextField("Last Name", text: $lastName)
                            .foregroundColor(AppColors.text)
                        TextField("Username", text: $username)
                            .foregroundColor(AppColors.text)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .foregroundColor(AppColors.text)
                        Picker("Country", selection: $country) {
                            ForEach(countryList, id: \.self) { c in
                                Text(countryFlagEmoji(for: c) + " " + c).tag(c)
                            }
                        }
                        DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                    }
                    .listRowBackground(AppColors.card)
                    Section(header: Text("Account")
                        .font(.custom("AvenirNext-UltraLight", size: 18))
                        .foregroundColor(AppColors.text.opacity(0.8))) {
                        Text(email).foregroundColor(.gray)
                        Button("Reset Password") {
                            resetPassword()
                        }
                    }
                    .listRowBackground(AppColors.card)
                    Section(header: Text("Change Password")
                        .font(.custom("AvenirNext-UltraLight", size: 18))
                        .foregroundColor(AppColors.text.opacity(0.8))) {
                        SecureField("Current Password", text: $currentPassword)
                            .foregroundColor(.gray)
                        SecureField("New Password", text: $newPassword)
                            .foregroundColor(.gray)
                        SecureField("Confirm New Password", text: $confirmNewPassword)
                            .foregroundColor(AppColors.text)
                        Button("Update Password") {
                            updatePassword()
                        }
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
                    Button("Save Changes") {
                        saveProfile()
                    }
                    .listRowBackground(AppColors.card)
                }
                .background(AppColors.background)
                .scrollContentBackground(.hidden)
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
                self.age = String(data["age"] as? Int ?? 0)
                self.country = data["country"] as? String ?? "United States"
                self.email = data["email"] as? String ?? ""
                if let dob = data["dateOfBirth"] as? Timestamp {
                    self.birthDate = dob.dateValue()
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
            "age": Int(age) ?? 0,
            "country": country,
            "dateOfBirth": Timestamp(date: birthDate)
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
}
