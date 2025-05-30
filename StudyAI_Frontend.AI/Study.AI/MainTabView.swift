//  MainTabView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tag(AppTab.home)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            SummaryView()
                .tag(AppTab.summaries)
                .tabItem {
                    Image(systemName: "text.quote")
                    Text("Summaries")
                }

            FlashcardView()
                .tag(AppTab.flashcards)
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Flashcards")
                }

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}
