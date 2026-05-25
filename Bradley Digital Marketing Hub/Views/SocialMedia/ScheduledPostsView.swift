import SwiftUI

struct ScheduledPostsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ScheduledPostsViewModel
    @State private var selectedPost: ScheduledPost?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(service: SocialMediaService) {
        _viewModel = StateObject(wrappedValue: ScheduledPostsViewModel(service: service))
    }

    var body: some View {
        Group {
            if viewModel.posts.isEmpty {
                HubEmptyState(
                    icon: "clock.badge.checkmark",
                    title: "No scheduled posts",
                    message: "Schedule content from your calendar. When it's due, you'll get a reminder to share manually."
                )
                .padding()
            } else {
                List {
                    Section {
                        HubDataDisclaimer(
                            title: "Manual sharing",
                            message: "Tap a post when it's due, then use Share to publish through your platform apps."
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    ForEach(viewModel.posts) { post in
                        PostRow(post: post, themePrimary: colors.primary) {
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
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
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
    var themePrimary: Color = .accentColor
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: SocialPlatform(rawValue: post.platform)?.iconName ?? "link")
                    .foregroundColor(HubPlatformColors.accent(for: post.platform, themePrimary: themePrimary))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.platform)
                        .font(.headline)
                    Text(post.content)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(statusLabel(for: post.status))
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

    private func statusLabel(for status: PostStatus) -> String {
        switch status {
        case .readyForReview: return "Ready to share"
        case .shared: return "Shared"
        case .posted: return "Posted"
        default: return status.rawValue.capitalized
        }
    }

    private func statusColor(for status: PostStatus) -> Color {
        switch status {
        case .scheduled: return themePrimary
        case .readyForReview: return .orange
        case .shared, .posted: return .green
        case .cancelled, .failed: return .gray
        case .posting: return .purple
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
        do {
            try await service.deleteScheduledPost(post)
            await NotificationService.shared.cancelPostReminder(postId: post.id)
            posts.removeAll { $0.id == post.id }
            HapticFeedback.success()
        } catch {
            errorMessage = "Could not delete post: \(error.localizedDescription)"
            HapticFeedback.warning()
        }
    }
}
