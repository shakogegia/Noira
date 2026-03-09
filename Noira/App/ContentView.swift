//
//  ContentView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var absLibraryService = ABSLibraryService()
    @StateObject private var audioPlayerService = AudioPlayerService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                RootView()
                    .environmentObject(authService)
                    .environmentObject(absLibraryService)
                    .environmentObject(audioPlayerService)
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
