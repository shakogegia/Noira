//
//  LoginView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Noira")
                .font(.largeTitle)
                .fontWeight(.bold)
                //.foregroundColor(.white)
            
            // Login Form
            VStack(spacing: 4) {
                TextField("Audiobookshelf URL", text: $serverURL)
                    .keyboardType(.URL)
                    .padding()
                    .frame(maxWidth: 600)
                
                TextField("Username", text: $username)
                    .padding()
                    .frame(maxWidth: 600)
                
                SecureField("Password", text: $password)
                    .padding()
                    .cornerRadius(8)
                    .frame(maxWidth: 600)
                
                Button("Connect") {
                    Task {
                        await handleLogin()
                    }
                }
                // .buttonStyle(.borderedProminent)
                .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || authService.isLoading)
                // .font(.title2)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
            }
            
            if authService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .background(Color.black)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleLogin() async {
        let success = await authService.login(
            serverURL: serverURL,
            username: username,
            password: password
        )
        
        if !success {
            alertMessage = "Failed to connect to server. Please check your credentials."
            showingAlert = true
        }
    }
}

#Preview("Light Mode") {
    LoginView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginView()
        .preferredColorScheme(.dark)
}
