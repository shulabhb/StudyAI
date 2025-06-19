//
//  WelcomeView.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var animate = false
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.25),  // Deep blue
                    Color(red: 0.1, green: 0.2, blue: 0.4),   // Medium blue
                    Color(red: 0.15, green: 0.3, blue: 0.5),  // Light blue
                    Color(red: 0.05, green: 0.1, blue: 0.25)  // Back to deep blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(animate ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
            
            // Floating particles effect
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo Section with glow effect
                VStack(spacing: 20) {
                    ZStack {
                        // Glow effect
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                            .opacity(glowOpacity)
                            .scaleEffect(animate ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                        
                        // Main logo
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .scaleEffect(logoScale)
                            .shadow(color: AppColors.accent.opacity(0.5), radius: 20, x: 0, y: 0)
                    }
                    
                    // Welcome text
                    VStack(spacing: 8) {
                        Text("Welcome to STUDY.AI")
                            .font(.custom("AvenirNext-UltraLight", size: 32))
                            .fontWeight(.light)
                            .foregroundColor(AppColors.text)
                            .opacity(textOpacity)
                        
                        Text("Studying made smarter and easier")
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(AppColors.text.opacity(0.7))
                            .opacity(textOpacity)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 20) {
                    // Login button
                    Button(action: {
                        appState.currentAuthFlow = .login
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("LOG IN")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(AppColors.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(AppColors.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: AppColors.accent.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .offset(y: buttonOffset)
                    
                    // Sign up button
                    Button(action: {
                        appState.currentAuthFlow = .signup
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("CREATE ACCOUNT")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(AppColors.accent)
                        )
                        .shadow(color: AppColors.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .offset(y: buttonOffset)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start background animation
        animate = true
        
        // Animate logo
        withAnimation(.easeOut(duration: 1.2)) {
            logoScale = 1.0
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            textOpacity = 1.0
        }
        
        // Animate buttons
        withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
            buttonOffset = 0
        }
        
        // Animate glow
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            glowOpacity = 0.6
        }
    }
}

#Preview {
    WelcomeView()
} 