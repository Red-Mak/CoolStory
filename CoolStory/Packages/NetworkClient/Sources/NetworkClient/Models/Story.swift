//
//  File.swift
//  NetworkClient
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation

public struct Story: Codable,Equatable {
    public let id: Int
    public let likedAtLeastOnce: Bool
    public let url: URL
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = URL(string: try container.decode(String.self, forKey: .url))!
        self.id = try container.decode(Int.self, forKey: .id)
        self.likedAtLeastOnce = try container.decode(Bool.self, forKey: .likedAtLeastOnce)
    }
}
