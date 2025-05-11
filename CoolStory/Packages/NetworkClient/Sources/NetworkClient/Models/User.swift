//
//  File.swift
//  NetworkClient
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation

public struct User: Codable, Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let profilePictureUrl: URL
    public let storyAlreadySeen: Bool
    
    public init(id: Int,
         name: String,
         profilePictureUrl: URL,
         storyAlreadySeen: Bool) {
        self.id = id
        self.name = name
        self.profilePictureUrl = profilePictureUrl
        self.storyAlreadySeen = storyAlreadySeen
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.profilePictureUrl = URL(string: try container.decode(String.self, forKey: .profilePictureUrl))!
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try container.decode(Int.self, forKey: .id)
        self.storyAlreadySeen = try container.decode(Bool.self, forKey: .storyAlreadySeen)
    }
}
