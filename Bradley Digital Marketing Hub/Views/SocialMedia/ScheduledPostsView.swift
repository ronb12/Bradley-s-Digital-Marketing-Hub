import SwiftUI

struct ScheduledPostsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ScheduledPostsViewModel
    @State private var selectedPost: ScheduledPost?
    
    init(service: SocialMediaService) {
        _viewModel = StateObject(wrappedValue: ScheduledPostsViewModel(service: service))
    }
    
    var body: some View {
        List {
            if viewModel.posts.isEmpty {
                Section {
                    Text("No scheduled posts")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            } else {
                ForEach(viewModel.posts) { post in
                    PostRow(post: post) {
                        selectedPost = post
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.deletePost(viewModel.posts[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Scheduled Posts")
        .task {
            if let userId = appViewModel.userProfile?.userId {
                await viewModel.loadPosts(userId: userId)
            }
        }
        .sheet(item: $selectedPost) { post in
            PostReviewView(post: post, service: appViewModel.socialMediaService)
        }
    }
}

struct PostRow: View {
    let post: ScheduledPost
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: SocialPlatform(rawValue: post.platform)?.iconName ?? "link")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.platform)
                        .font(.headline)
                    Text(post.content)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(post.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: post.status).opacity(0.2))
                            .foregroundColor(statusColor(for: post.status))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(post.scheduledDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func statusColor(for status: PostStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .readyForReview: return .orange
        case .shared: return .green
        case .cancelled: return .gray
        default: return .secondary
        }
    }
}

@MainActor
final class ScheduledPostsViewModel: ObservableObject {
    @Published var posts: [ScheduledPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: SocialMediaService
    
    init(service: SocialMediaService) {
        self.service = service
    }
    
    func loadPosts(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            posts = try await service.fetchScheduledPosts(userId: userId)
        } catch {
            errorMessage = "Error loading posts: \(error.localizedDescription)"
        }
    }
    
    func deletePost(_ post: ScheduledPost) async {
        // TODO: Implement delete in SocialMediaService
        await loadPosts(userId: post.userId)
    }
}

