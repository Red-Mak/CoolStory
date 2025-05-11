//
//  StoryViewModel.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation
import Combine
import NetworkClient
import Persistence

class StoryViewModel: ObservableObject {
    private let networkClient: NetworkClientProtocol
    private let persistenceManager = PersistenceManager()
    private var cancellables = Set<AnyCancellable>()
    private(set) var user: User
    @Published var stories = [Story]()
    @Published var currentStory: Story?
    @Published var state = State.idle
    @Published var liked = false
    @Published var progressTimeInterval: ClosedRange<Date>?

    init(for user: User, networkClient: NetworkClientProtocol) {
        self.user = user
        self.networkClient = networkClient
        self.handle(action: .fetchStories)
        self.bindData()
    }
        
    func handle(action: Action) {
        switch action {
        case .fetchStories:
            Task { @MainActor in
                do {
                    self.state = .loading
                    
                    let userStories = try await self.networkClient.getStories()
                        .flatMap{$0}
                        .first {
                            $0.userId == self.user.id
                        }
                    self.stories = userStories?.stories ?? []
                    if let story = self.stories.first {
                        self.updateCurrentStory(story: story)
                    }
                    self.state = self.stories.isEmpty ? .noData : .dataFound
                    
                } catch let error {
                    self.state = .error(error.localizedDescription)
                }
            }
            
        case .likeTriggred:
            if let currentStory {
                self.persistenceManager.triggerLiked(storyId: currentStory.id)
            }
            
        case let .touch(location, surfaceWidth):
            guard let currentStory else { return }
            
            if location.x > surfaceWidth/2 {
                if let nextUserStory = self.stories.nextItem(after: currentStory) {
                    self.updateCurrentStory(story: nextUserStory)
                }
            } else {
                if let nextUserStory = self.stories.previous(item: currentStory) {
                    self.updateCurrentStory(story: nextUserStory)
                }
            }
        }
    }
    
    private func bindData() {
        self.persistenceManager.storyUpdated
            .sink { value in
                self.liked = value
            }
            .store(in: &self.cancellables)
    }

    private func updateCurrentStory(story: Story) {
        self.currentStory = story
        self.progressTimeInterval = Date.now...Date.now.addingTimeInterval(5)
        self.persistenceManager.listenToUpdates(for: story.id)
    }
}

extension StoryViewModel {
    enum Action {
        case fetchStories
        case likeTriggred
        case touch(location: CGPoint, surfaceWidth: CGFloat)
    }
}

extension StoryViewModel {
    enum State {
        case idle
        case loading
        case dataFound
        case noData
        case error(String)
    }
}
