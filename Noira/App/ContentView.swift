//
//  ContentView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                HomeView()
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
        .onAppear {
            authService.checkAuthentication()
        }
    }
}

#Preview {
    ContentView()
}
