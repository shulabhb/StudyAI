//
//  LoginView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var animate = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 30) {
                    Text("STUDY.AI")
                        .font(.custom("AvenirNext-UltraLight", size: 42))
                        .foregroundColor(AppColors.text)
                        .padding(.bottom, 20)
                        .scaleEffect(animate ? 1 : 0.8)
                        .opacity(animate ? 1 : 0)
                    VStack(spacing: 25) {
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            systemImage: "envelope.fill"
                        )
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
                                .padding(.top, -10)
                        }
                        Button("Forgot Password?") {
                            // Optional reset flow
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.text.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 25)
                    Button(action: logIn) {
                        Text("LOG IN")
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
                    .padding(.horizontal, 25)
                    .scaleEffect(animate ? 1 : 0.9)
                    HStack {
                        Text("First time here?")
                            .foregroundColor(AppColors.text.opacity(0.7))
                        NavigationLink("Get Started", destination: SignupView())
                            .foregroundColor(AppColors.accent)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.top, 20)
                    Spacer()
                }
                .padding(.top, 50)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animate)
                .onAppear { animate = true }
            }
        }
    }
    
    // MARK: - Login Logic
    private func logIn() {
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }

            guard let uid = result?.user.uid else {
                errorMessage = "Unexpected login error."
                return
            }

            // Fetch user's username
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    errorMessage = "Firestore error: \(error.localizedDescription)"
                    return
                }

                if let data = snapshot?.data(),
                   let username = data["username"] as? String {
                    appState.username = username
                    appState.selectedTab = .home  // Reset to home tab
                    appState.isLoggedIn = true
                } else {
                    errorMessage = "User data not found."
                }
            }
        }
    }
}

// Custom TextField View
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// Custom SecureField View
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
