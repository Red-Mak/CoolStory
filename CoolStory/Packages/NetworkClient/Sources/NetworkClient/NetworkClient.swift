import Foundation

enum NetworkClientError: Error {
    case unknown
}

public protocol NetworkClientProtocol {
    func getPaginatedUsersList() async throws -> [[User]]
    func getStories() async throws -> [[UserStories]]
}

public class NetworkClient: NetworkClientProtocol {
    var baseURL: String
    
    lazy var urlSession: URLSession = {
        return URLSession(configuration: .default)
    }()
    
    public init(with baseURL: String, activateCache: Bool) {
        self.baseURL = baseURL
        self.urlSession.configuration.requestCachePolicy = activateCache ? .returnCacheDataElseLoad : .reloadIgnoringLocalCacheData
    }
    
    private func url(from endPoint: EndPoint) -> URL? {
        var urlComponents = URLComponents(string: self.baseURL)
        urlComponents?.path = endPoint.path
        urlComponents?.queryItems = endPoint.queryParams
        return urlComponents?.url
    }
    
    public func getPaginatedUsersList() async throws -> [[User]] {
        guard let url = self.url(from: .users) else {
            throw NetworkClientError.unknown
        }
        
        return try await self.getData(from: url)
    }
    
    public func getStories() async throws -> [[UserStories]] {
        guard let url = self.url(from: .stories) else {
            throw NetworkClientError.unknown
        }
        
        return try await self.getData(from: url)
    }
    
    private func getData<T: Codable>(from url: URL) async throws -> T {
        let response = try await self.urlSession.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = response.0
        return try decoder.decode(T.self, from: data)
    }
}

private extension NetworkClient {
    enum EndPoint {
        case users
        case stories
        
        var path: String {
            switch self {
            case .users:
                return "/scl/fi/ynwui9y6rahgcmcljxxjv/users.json"
            case .stories:
                return "/scl/fi/f521mvn4fmm8av6lp3il4/stories.json"
            }
        }
        
        var queryParams: [URLQueryItem] {
            switch self {
            case .users:
                return [
                    .init(name: "rlkey", value: "4c89tl8we0j65la72oq582vwo"),
                    .init(name: "st", value: "c1xm04fo"),
                    .init(name: "dl", value: "1")
                ]
            case .stories:
                return [
                    .init(name: "rlkey", value: "7yw8pbc39lk7zpuhzymppkzft"),
                    .init(name: "st", value: "ce10xxwc"),
                    .init(name: "dl", value: "1")
                ]
            }
        }
    }
}
