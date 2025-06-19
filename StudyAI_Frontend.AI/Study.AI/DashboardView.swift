//
//  DashboardView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 4/7/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showFlashcardGenerator = false
    
    // Custom colors
    private let backgroundColor = Color(red: 0.1, green: 0.15, blue: 0.25) // Light dark blue
    private let buttonColor = Color(red: 0.15, green: 0.2, blue: 0.3) // Slightly lighter blue for buttons
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Welcome Section
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Welcome back,")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(appState.username)")
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Grid of buttons
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            NavigationLink(destination: PasteNoteView()) {
                                dashboardButton(label: "Paste Text", systemImage: "doc.text.viewfinder")
                            }
                            
                            NavigationLink(destination: ScanView()) {
                                dashboardButton(label: "Scan Notes", systemImage: "camera.viewfinder")
                            }
                            
                            NavigationLink(destination: RecordView()) {
                                dashboardButton(label: "Record Notes", systemImage: "waveform.circle.fill")
                            }
                            
                            Button(action: {
                                showFlashcardGenerator = true
                            }) {
                                dashboardButton(label: "Flashcards", systemImage: "rectangle.stack")
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dashboard")
                        .font(.custom("AvenirNext-UltraLight", size: 24))
                        .foregroundColor(.white)
                }
            }
        }
        .fullScreenCover(isPresented: $showFlashcardGenerator) {
            FlashcardGeneratorView()
        }
    }
    
    func dashboardButton(label: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(buttonColor)
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
