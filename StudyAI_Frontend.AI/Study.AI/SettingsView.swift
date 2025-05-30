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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    NavigationLink("Profile", destination: ProfileView())
                    Button("Log Out", role: .destructive) {
                        logOut()
                    }
                }

                Section(header: Text("Preferences")) {
                    Toggle("Dark Mode", isOn: .constant(false)) // Placeholder
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false
        } catch {
            print("❌ Logout error: \(error.localizedDescription)")
        }
    }
}
