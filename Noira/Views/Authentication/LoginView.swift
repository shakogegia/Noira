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
        HStack(alignment: .center) {
            VStack(spacing: 32) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 96))
                    .foregroundStyle(.gray)

                Text("Noira")
                    .font(.title3)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    Text("Audiobookshelf for tvOS")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(
                        "Copyright © 2025 Shalva Gegia.\nAll rights reserved."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                }
            }
            .frame(maxWidth: .infinity)
            .padding(.all)
            
            // vertical line
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.gray)
                .padding(.all)
                .frame(maxHeight: 400)

            VStack(spacing: 4) {
                if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    Text("Audiobookshelf server credentials.")
                        .padding()
                        .font(.body)
                        

                    TextField("Server URL", text: $serverURL)
                        .keyboardType(.URL)
                        .padding()
                        .frame(maxWidth: 600)

                    TextField("Username", text: $username)
                        .padding()
                        .frame(maxWidth: 600)

                    SecureField("Password", text: $password)
                        .padding(.all)
                        .cornerRadius(8)
                        .frame(maxWidth: 600)
                    
                    Button(action: {
                        Task {
                            await handleLogin()
                        }
                    }, label: {
                        HStack(spacing: 8) {
                            Image(systemName: "externaldrive.connected.to.line.below.fill")
                            Text("Connect to server")
                        }
                    })
                    .padding(.all)
                    .disabled(
                        serverURL.isEmpty || username.isEmpty
                            || password.isEmpty
                            || authService.isLoading
                    )
                    .frame(maxWidth: .infinity)
                    .alert("Error", isPresented: $showingAlert) {
                        Button("OK") {}
                    } message: {
                        Text(alertMessage)
                    }

                }

            }
            .frame(maxWidth: .infinity)
            .padding(.all)
        }

    }

    private func handleLogin() async {
        let result = await authService.login(
            serverURL: serverURL,
            username: username,
            password: password
        )

        switch result {
        case .success:
            // Login successful, authentication service will handle state updates
            break
        case .failure(let error):
            alertMessage = error.localizedDescription
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
