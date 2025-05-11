//
//  NetworkClient+Extensions.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation
import NetworkClient

extension NetworkClient {
    static var auto: NetworkClient {
        #if DEBUG
        return NetworkClient(with: "https://www.dropbox.com", activateCache: false)
        #else
        return NetworkClient(with: "https://www.dropbox.com", activateCache: true)
        #endif
    }
}

class NetworkClientMock: NetworkClientProtocol {
    
    func getData<T: Codable>(from fileName: String) throws -> T {
        let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json")!
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    func getPaginatedUsersList() async throws -> [[User]] {
        return try getData(from: "users")
    }
    
    func getStories() async throws -> [[UserStories]] {
        return try getData(from: "stories")
    }
}
