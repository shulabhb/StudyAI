//
//  DashboardView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back,")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("\(appState.username)")
                            .font(.largeTitle)
                            .bold()
                    }

                    Spacer()

                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 20) {
                    
                    NavigationLink(destination: PasteNoteView()) {
                        dashboardButton(label: "Paste Text", systemImage: "doc.text.viewfinder")
                    }

                    NavigationLink(destination: ScanView()) {
                        dashboardButton(label: "Scan Notes", systemImage: "camera.viewfinder")
                    }
                    
                    NavigationLink(destination: RecordView()) {
                        dashboardButton(label: "Record Notes", systemImage: "waveform.circle.fill")
                    }


                    NavigationLink(destination: FlashcardView()) {
                        dashboardButton(label: "Flashcards", systemImage: "rectangle.stack")
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Dashboard")
        }
    }

    func dashboardButton(label: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(label)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.15))
        .foregroundColor(.blue)
        .cornerRadius(14)
        .font(.headline)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
        )
    }
}
