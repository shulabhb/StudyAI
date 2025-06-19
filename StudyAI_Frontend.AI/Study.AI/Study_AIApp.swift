//
//  Study_AIApp.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI
import Firebase

@main
struct Study_AIApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var appState = AppState()

    // Firebase Configuration
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appState)
            } else {
                switch appState.currentAuthFlow {
                case .welcome:
                    WelcomeView()
                        .environmentObject(appState)
                case .login:
                    LoginView()
                        .environmentObject(appState)
                case .signup:
                    SignupView()
                        .environmentObject(appState)
                }
            }
        }
    }

}
