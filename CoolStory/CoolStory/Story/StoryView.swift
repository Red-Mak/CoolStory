//
//  StoryView.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import SwiftUI
import Kingfisher

struct StoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StoryViewModel
    private let storyDuration = 5.0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    KFImage(self.viewModel.currentStory?.url)
                        .fade(duration: 0.3)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture { location in
                            self.viewModel.handle(action: .touch(location: location,
                                                                 surfaceWidth: proxy.size.width))
                        }
                    self.footerView
                }
                
                self.headerView
            }
            .overlay {
                self.stateView
            }
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        HStack(spacing: 15) {
            Button {
                print("send msg")
            } label: {
                Text("Envoyer un message...")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(9)
                    .overlay(Capsule(style: .continuous)
                        .stroke(Color.white,
                                style: StrokeStyle(lineWidth: 1)))
            }
            
            Spacer()
            
            Button {
                self.viewModel.handle(action: .likeTriggred)
            } label: {
                Image(systemName: (self.viewModel.liked ? "heart.fill" : "heart"))
                    .resizable()
                    .scaledToFit()
                    .padding(.vertical, 4)
                    .foregroundStyle(self.viewModel.liked ? .red : .white)
                    .symbolEffect(.bounce, value: self.viewModel.liked)
            }
            
            Button {
                print("send msg")
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .padding(.vertical, 4)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .frame(height: 40)
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 0) {
            
            HStack {
                ForEach(self.viewModel.stories, id:\.id) { story in
                    if let progressTimeInterval = self.viewModel.progressTimeInterval {
                        if story == self.viewModel.currentStory {
                            ProgressView(timerInterval: progressTimeInterval,
                                         countsDown: false,
                                         label: EmptyView.init,
                                         currentValueLabel: EmptyView.init)
                            .tint(Color.white)
                        } else {
                            ProgressView(timerInterval: Date.now...Date.now,
                                         countsDown: false,
                                         label: EmptyView.init,
                                         currentValueLabel: EmptyView.init)
                            .tint(Color.gray)
                        }
                    }
                }
            }
            .frame(height: 1)
            .padding(.top, 5)
            .padding(.bottom, 2)
            .padding(.horizontal, 5)
            
            HStack {
                KFImage(self.viewModel.user.profilePictureUrl)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                
                Group {
                    Text(self.viewModel.user.name)
                    
                    Spacer()
                    
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .padding(10)
                            .scaledToFit()
                    }
                }
                .font(.title3)
                .bold()
                .foregroundStyle(Color.white)
            }
            .frame(height: 40)
            .padding()
        }
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
            ProgressView()
            
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

import NetworkClient
#Preview {
    let networkClient = NetworkClientMock()
    let users: [[User]] = try! networkClient.getData(from: "users")
    let user = users.flatMap { $0 }.first!
    
    StoryView(viewModel: StoryViewModel(for: user, networkClient: networkClient))
}
