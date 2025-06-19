//
//  SettingsView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//


import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                Form {
                    Section(header: Text("Account")
                        .font(.custom("AvenirNext-UltraLight", size: 18))
                        .foregroundColor(AppColors.text.opacity(0.8))) {
                        NavigationLink("Profile", destination: ProfileView())
                            .foregroundColor(AppColors.text)
                        Button("Log Out", role: .destructive) {
                            showLogoutAlert = true
                        }
                    }
                    .listRowBackground(AppColors.card)
                    Section(header: Text("Preferences")
                        .font(.custom("AvenirNext-UltraLight", size: 18))
                        .foregroundColor(AppColors.text.opacity(0.8))) {
                        Text("Version 1.0.0")
                            .foregroundColor(AppColors.text.opacity(0.7))
                    }
                    .listRowBackground(AppColors.card)
                }
                .background(AppColors.background)
                .scrollContentBackground(.hidden)
                .accentColor(AppColors.accent)
                .tint(AppColors.accent)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("AvenirNext-UltraLight", size: 24))
                        .foregroundColor(AppColors.text)
                }
            }
        }
        .alert("Are you sure you want to log out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logOut()
            }
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false
            appState.currentAuthFlow = .welcome
        } catch {
            print("❌ Logout error: \(error.localizedDescription)")
        }
    }
}
