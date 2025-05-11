//
//  FeedView.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import SwiftUI
import NetworkClient
import Kingfisher

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Namespace var nameSpace
    @State private var selectedUser: User?
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 20) {
                    ForEach(self.viewModel.users, id: \.id) { user in
                        UserAvatar(for: user)
                            .task {
                                if user == self.viewModel.users.last {
                                    self.viewModel.handle(action: .loadMore)
                                }
                            }
                    }
                }
                .padding(.leading, 10)
            }
            .scrollIndicators(.hidden)
            .frame(height: 100)
            .overlay {
                self.stateView
            }
            Spacer()
#if DEBUG
            Button {
                self.viewModel.handle(action: .eraseAllLocalData)
            } label: {
                Text("Erase all local data")
            }
#endif
        }
        .sheet(item: $selectedUser) { user in
            StoryView(viewModel: StoryViewModel(for: user,
                                                networkClient: self.viewModel.networkClient))
            .navigationTransition(.zoom(sourceID: user.id, in: nameSpace))
        }
    }
    
    @ViewBuilder
    func UserAvatar(for user: User) -> some View {
        ZStack(alignment: .center) {
            Circle()
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: self.viewModel.isStorySeen(for: user) ? [.gray] : [.red, .yellow,.purple, .red]), center: .center, startAngle: .zero, endAngle: .degrees(360)), lineWidth: 3
                )
            
            KFImage(user.profilePictureUrl)
                .fade(duration: 0.3)
                .resizable()
                .frame(width: 90, height: 90)
                .clipShape(Circle())
        }
        .background(Color.black)
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .onTapGesture {
            self.selectedUser = user
            self.viewModel.handle(action: .userDidSeeStory(user: user))
        }
        .matchedTransitionSource(id: user.id, in: self.nameSpace)
    }
    
    @ViewBuilder
    private var stateView: some View {
        switch self.viewModel.state {
        case .dataFound:
            EmptyView()
            
        case .noData:
            ContentUnavailableView {
                Label("No stories found",
                      systemImage: "rectangle.badge.xmark")
                .symbolEffect(.bounce, value: true)
                .font(.largeTitle)
            }
            
        case .idle, .loading:
            VStack(alignment: .leading, spacing: 0) {
                LazyHStack(spacing: 20) {
                    ForEach(self.viewModel.placeHolderUsers, id: \.id) { user in
                        UserAvatar(for: user)
                            .redacted(reason: .placeholder)
                    }
                }
            }
            .frame(height: 100)
            .padding(.leading, 10)
            
        case .error(let error):
            ContentUnavailableView {
                Label(error,
                      systemImage: "rectangle.badge.xmark")
                .symbolEffect(.bounce, value: true)
                .font(.largeTitle)
            }
        }
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel(networkClient: NetworkClientMock()))
}
