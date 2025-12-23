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

    var body: some View {
        HStack(alignment: .center) {
            BrandingView()
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
                            await authService.login(
                                serverURL: serverURL,
                                username: username,
                                password: password
                            )
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

                }

            }
            .frame(maxWidth: .infinity)
            .padding(.all)
        }
        .alert("Login Error", isPresented: .constant(authService.error != nil)) {
            Button("OK") {
                authService.error = nil
            }
        } message: {
            if let error = authService.error {
                Text(error.localizedDescription)
            }
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
