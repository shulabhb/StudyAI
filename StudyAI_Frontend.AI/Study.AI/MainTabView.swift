//  MainTabView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//

import SwiftUI

extension Color {
    static let tabInactive = Color(red: 0.7, green: 0.85, blue: 1.0)
    static let tabActive = Color(red: 0.25, green: 0.45, blue: 0.85)
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tag(AppTab.home)
                .tabItem {
                    Image(systemName: "house.fill")
                        .renderingMode(.template)
                        .foregroundColor(appState.selectedTab == .home ? .tabActive : .tabInactive)
                    Text("Home")
                        .foregroundColor(appState.selectedTab == .home ? .tabActive : .tabInactive)
                }
            SummaryView()
                .tag(AppTab.summaries)
                .tabItem {
                    Image(systemName: "text.quote")
                        .renderingMode(.template)
                        .foregroundColor(appState.selectedTab == .summaries ? .tabActive : .tabInactive)
                    Text("Summaries")
                        .foregroundColor(appState.selectedTab == .summaries ? .tabActive : .tabInactive)
                }
            SavedFlashcardSetsView()
                .tag(AppTab.flashcards)
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                        .renderingMode(.template)
                        .foregroundColor(appState.selectedTab == .flashcards ? .tabActive : .tabInactive)
                    Text("Flashcards")
                        .foregroundColor(appState.selectedTab == .flashcards ? .tabActive : .tabInactive)
                }
            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                        .renderingMode(.template)
                        .foregroundColor(appState.selectedTab == .settings ? .tabActive : .tabInactive)
                    Text("Settings")
                        .foregroundColor(appState.selectedTab == .settings ? .tabActive : .tabInactive)
                }
        }
        .accentColor(.white)
    }
}

// Extension to add logo to navigation bar
extension View {
    func withLogoNavigationBar() -> some View {
        self.navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
            }
        }
    }
}
