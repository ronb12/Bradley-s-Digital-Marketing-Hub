import SwiftUI

struct PostReviewContainerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var postToReview: ScheduledPost?
    @State private var isLoadingPost = false
    
    let postId: String
    
    var body: some View {
        Group {
            if isLoadingPost {
                ProgressView("Loading post...")
            } else if let post = postToReview {
                PostReviewView(post: post, service: appViewModel.socialMediaService)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Post Not Found")
                        .font(.headline)
                    Text("The scheduled post could not be found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .task {
            await loadPost()
        }
    }
    
    private func loadPost() async {
        isLoadingPost = true
        defer { isLoadingPost = false }
        
        guard let userId = appViewModel.userProfile?.userId else {
            return
        }
        
        do {
            let posts = try await appViewModel.socialMediaService.fetchScheduledPosts(userId: userId)
            postToReview = posts.first(where: { $0.id == postId })
        } catch {
            print("Error loading post: \(error.localizedDescription)")
        }
    }
}

