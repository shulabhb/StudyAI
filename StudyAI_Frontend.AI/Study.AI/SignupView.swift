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
    @State private var isAnimating = false
    @State private var animate = false

    // Form Fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var selectedCountry = "United States"
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 25) {
                    // Back button
                    HStack {
                        Button(action: {
                            appState.currentAuthFlow = .welcome
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(AppColors.text.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    logoSection
                    titleSection
                    formFieldsSection
                }
                .padding(.bottom, 30)
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.easeOut(duration: 0.6), value: animate)
            .onAppear { animate = true }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
        }
        .padding(.top, 20)
    }

    private var titleSection: some View {
        Text("Create Account")
            .font(.custom("AvenirNext-UltraLight", size: 36))
            .foregroundColor(AppColors.text)
            .scaleEffect(animate ? 1 : 0.8)
            .opacity(animate ? 1 : 0)
    }

    private var formFieldsSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                CustomTextField(
                    text: $firstName,
                    placeholder: "First Name",
                    systemImage: "person.fill"
                )
                CustomTextField(
                    text: $lastName,
                    placeholder: "Last Name",
                    systemImage: "person.fill"
                )
            }
            CustomTextField(
                text: $username,
                placeholder: "Username",
                systemImage: "at"
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth")
                    .foregroundColor(AppColors.text.opacity(0.8))
                    .font(.system(size: 14, weight: .medium))
                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .accentColor(AppColors.text)
            }
            .padding()
            .background(AppColors.card)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppColors.text.opacity(0.2), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Country")
                    .foregroundColor(AppColors.text.opacity(0.8))
                    .font(.system(size: 14, weight: .medium))
                Picker("", selection: $selectedCountry) {
                    ForEach(countryList, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(AppColors.text)
            }
            .padding()
            .background(AppColors.card)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppColors.text.opacity(0.2), lineWidth: 1)
            )
            CustomTextField(
                text: $email,
                placeholder: "Email",
                systemImage: "envelope.fill"
            )
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            CustomSecureField(
                text: $password,
                placeholder: "Password",
                systemImage: "lock.fill"
            )
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            Button(action: signUp) {
                Text("CREATE ACCOUNT")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(AppColors.text.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 10)
            HStack {
                Text("Already have an account?")
                    .foregroundColor(AppColors.text.opacity(0.7))
                Button("Log In") {
                    appState.currentAuthFlow = .login
                }
                .foregroundColor(AppColors.accent)
                .font(.system(size: 16, weight: .bold))
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 25)
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
