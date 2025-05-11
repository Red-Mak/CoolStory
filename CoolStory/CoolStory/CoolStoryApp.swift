//
//  CoolStoryApp.swift
//  CoolStory
//
//  Created by Malek Radhouani on 06/05/2025.
//

import SwiftUI
import NetworkClient

@main
struct CoolStoryApp: App {
    var body: some Scene {
        WindowGroup {
            FeedView(viewModel: FeedViewModel(networkClient: NetworkClient.auto))
        }
    }
}
