//
//  frontHealthApp.swift
//  frontHealth
//
//  Created by Aiaulym Abduohapova on 04.05.2026.
//

import SwiftUI

@main
struct frontHealthApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
