//
//  FeedViewModel.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation
import Combine
import NetworkClient
import Persistence

class FeedViewModel: ObservableObject {
    @Published private(set) var users = [User]()
    @Published var state = State.idle
    private(set) var networkClient: NetworkClientProtocol
    private let persistenceManager = PersistenceManager()
    private var cancellables = Set<AnyCancellable>()

    let placeHolderUsers = [
        User(id: 1, name: "user1", profilePictureUrl: URL(string: "beReal.com")!, storyAlreadySeen: false),
        User(id: 2, name: "user2", profilePictureUrl: URL(string: "beReal.com")!, storyAlreadySeen: false),
        User(id: 3, name: "user3", profilePictureUrl: URL(string: "beReal.com")!, storyAlreadySeen: false),
        User(id: 4, name: "user4", profilePictureUrl: URL(string: "beReal.com")!, storyAlreadySeen: false),
        User(id: 5, name: "user5", profilePictureUrl: URL(string: "beReal.com")!, storyAlreadySeen: false),
    ]
    
    init(networkClient: NetworkClientProtocol) {
        self.users = []
        //TODO: use networkCient
        self.networkClient = networkClient
        self.handle(action: .fetchUsersList)
        self.bindData()
    }
    
    func bindData() {
        self.persistenceManager.didUpdateUsers
            .sink { [weak self] updated in
                guard let self else { return }
                self.users = self.users
            }
            .store(in: &self.cancellables)
    }
    
    func handle(action: Action) {
        switch action {
        case .fetchUsersList:
            Task { @MainActor in
                do {
                    self.state = .loading
                    let users = try await self.networkClient.getPaginatedUsersList()
                    let flattenUsers = users.flatMap {$0}
                    let dicData = flattenUsers.filter{
                        $0.storyAlreadySeen == true
                    }.map {
                        return ["identifier": $0.id, "storyAlreadySeen": $0.storyAlreadySeen]
                    }
                    self.persistenceManager.batchUpdate(users: dicData)
                    self.users = flattenUsers
                    
                    self.state = self.users.isEmpty ? .noData : .dataFound
                } catch let error {
                    print("error \(#function): \(error.localizedDescription)")
                    self.state = .error(error.localizedDescription)
                }
            }
            
        case .userDidSeeStory(let user):
            self.persistenceManager.markAsSeen(userId: user.id)
            
        case .loadMore:
            self.users += Array(self.users.prefix(10))
            
        case .eraseAllLocalData:
            self.persistenceManager.eraseAllLocalData()
        }
    }
    
    func isStorySeen(for user: User) -> Bool {
        self.persistenceManager.alreadySeen(userId: user.id)
    }
}

extension FeedViewModel {
    enum Action {
        case fetchUsersList
        case userDidSeeStory(user: User)
        case loadMore
        case eraseAllLocalData
    }
}

extension FeedViewModel {
    enum State {
        case idle
        case loading
        case dataFound
        case noData
        case error(String)
    }
}
