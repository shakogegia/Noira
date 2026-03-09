//
//  SettingsView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var userDefaults = UserDefaultsService.shared
    
    @State var theme: Theme = .dark
    @State var showLogoutAlert: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Audiobookshelf")) {
                Picker("Library", selection: $theme) {
                    Text("Dark").tag(Theme.dark)
                    Text("Light").tag(Theme.light)
                    Text("System").tag(Theme.system)
                }
            }

            Section(header: Text("User")) {
                Button(action: {}) {
                    Text(userDefaults.username ?? "Username")
                }
                .disabled(true)

                Button(role: .destructive, action: {
                    showLogoutAlert = true
                }, label: {
                    Text("Sign out")
                })
            }
        }
        .padding(.leading, 400)
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                BrandingView()
                    .frame(width: 350)

                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.gray)
                    .padding(.vertical, 40)
            }
        }
        .alert("Sign out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

enum Theme: Hashable {
    case dark
    case light
    case system
}

#Preview {
    SettingsView()
}

