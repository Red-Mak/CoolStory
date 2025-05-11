//
//  File.swift
//  NetworkClient
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation

public struct UserStories: Codable {
    public let userId: Int
    public let stories: [Story]
}
