//
//  SettingsView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    @State var showPreview: Bool = false
    @State var theme: Theme = .dark
    @State var showLogoutAlert: Bool = false
    
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
                .padding(.vertical, 40)
                
            NavigationStack {
                Form {
                    Section(header: Text("General")) {
                        Picker("Theme", selection: $theme) {
                            Text("Dark").tag(Theme.dark)
                            Text("Light").tag(Theme.light)
                            Text("System").tag(Theme.system)
                        }
                        
                        Toggle("Show Previews", isOn: $showPreview)
                    }
                    
                    Section(header: Text("Audiobookshelf")) {
                        Picker("Library", selection: $theme) {
                            Text("Dark").tag(Theme.dark)
                            Text("Light").tag(Theme.light)
                            Text("System").tag(Theme.system)
                        }
                    }
                    
                    
                    Section(header: Text("User")) {
                        Button(role: .destructive, action: {
                            showLogoutAlert = true
                        }, label: {
                            Text("Log out")
                        })
                    }
                }
                .padding(.all)
                .scrollClipDisabled()
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
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

