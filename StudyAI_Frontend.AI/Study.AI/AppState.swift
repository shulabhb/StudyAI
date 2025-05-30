//  AppState.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import Foundation

/// The four main tabs
enum AppTab: Hashable {
    case home, summaries, flashcards, settings
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var username: String = "User"

    /// Tracks which tab is currently selected
    @Published var selectedTab: AppTab = .home
}
