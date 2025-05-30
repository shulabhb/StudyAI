//
//  SignupView.swift
//  Study.AI
//
//  Created by Shulabh on 4/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    // Form Fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var age = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var selectedCountry = "United States"
    @State private var email = ""
    @State private var password = ""

    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()

                Group {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Username", text: $username)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countryList, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                }

                Group {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button("Sign Up") {
                        signUp()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
    }

    // MARK: - Firebase Signup Logic
    private func signUp() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and Password are required."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Signup failed: \(error.localizedDescription)"
                return
            }

            guard let uid = result?.user.uid else { return }

            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "username": username,
                "age": Int(age) ?? 0,
                "country": selectedCountry,
                "dateOfBirth": Timestamp(date: dateOfBirth),
                "email": email,
                "createdAt": Timestamp()
            ]

            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    self.errorMessage = "Firestore error: \(error.localizedDescription)"
                } else {
                    appState.username = username
                    appState.isLoggedIn = true
                }
            }
        }
    }

    // MARK: - Country List
    private var countryList: [String] {
        let recommended = ["United States"]
        let others = Locale.Region.isoRegions.compactMap {
            Locale.current.localizedString(forRegionCode: $0.identifier)
        }.sorted()
        return recommended + others.filter { !recommended.contains($0) }
    }
}
