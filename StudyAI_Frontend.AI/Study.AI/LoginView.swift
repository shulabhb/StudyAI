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

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray4), Color(.systemGray6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Logo
                    Text("Study.AI")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.mint)
                        .shadow(color: .white.opacity(0.8), radius: 8)
                        .padding(.bottom, 10)

                    // Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(.caption).foregroundColor(.gray)
                        TextField("you@example.com", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 3)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    // Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password").font(.caption).foregroundColor(.gray)
                        SecureField("Enter password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 3)
                    }

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, -10)
                    }

                    // Forgot password
                    Button("Forgot Password?") {
                        // Optional reset flow
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    // Login Button
                    Button(action: logIn) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .scaleEffect(animate ? 1 : 0.95)
                    }

                    // Sign-up Navigation
                    HStack {
                        Text("First time here?").foregroundColor(.gray)
                        NavigationLink("Get Started", destination: SignupView())
                            .foregroundColor(.blue)
                            .bold()
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
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
                    appState.isLoggedIn = true
                } else {
                    errorMessage = "User data not found."
                }
            }
        }
    }
}
