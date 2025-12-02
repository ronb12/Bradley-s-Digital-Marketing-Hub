import SwiftUI

struct PostReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostReviewViewModel
    @State private var showShareSheet = false
    
    let post: ScheduledPost
    
    init(post: ScheduledPost, service: SocialMediaService) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostReviewViewModel(post: post, service: service))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review Your Post")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Review and share your scheduled post")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Post Preview Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Platform Badge
                        HStack {
                            Image(systemName: SocialPlatform(rawValue: post.platform)?.iconName ?? "link")
                                .foregroundColor(.blue)
                            Text(post.platform)
                                .font(.headline)
                            Spacer()
                            if let scheduledDate = post.scheduledDate {
                                Text(scheduledDate, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Post Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text(post.content)
                                .font(.body)
                                .lineSpacing(4)
                            
                            if let hashtags = post.hashtags, !hashtags.isEmpty {
                                Text(hashtags)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if let linkURL = post.linkURL, !linkURL.isEmpty {
                                Link(linkURL, destination: URL(string: linkURL)!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Media Preview (if any)
                        if !post.mediaURLs.isEmpty {
                            Text("\(post.mediaURLs.count) image(s) attached")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Info Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("How sharing works")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("ShareSheet shows all your installed social apps", systemImage: "square.and.arrow.up")
                            Label("Each app lets you choose which account if you have multiple", systemImage: "person.2.fill")
                            Label("You can share multiple times to post to different platforms", systemImage: "repeat")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Share button
                        Button {
                            showShareSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Share to \(post.platform) or Any Platform")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            Task {
                                await viewModel.markAsShared()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Mark as Shared")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isMarkingAsShared)
                        
                        Button(role: .destructive) {
                            Task {
                                await viewModel.cancelPost()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Cancel Post")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.red)
                        }
                        .disabled(viewModel.isCancelling)
                    }
                    .padding(.horizontal)
                    
                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Review Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(
                    items: shareItems,
                    excludedActivityTypes: nil
                )
            }
        }
    }
    
    private var shareItems: [Any] {
        var items: [Any] = []
        
        // Combine content with hashtags
        var fullContent = post.content
        if let hashtags = post.hashtags, !hashtags.isEmpty {
            fullContent += "\n\n\(hashtags)"
        }
        items.append(fullContent)
        
        // Add link if available
        if let linkURL = post.linkURL, !linkURL.isEmpty, let url = URL(string: linkURL) {
            items.append(url)
        }
        
        return items
    }
}

@MainActor
final class PostReviewViewModel: ObservableObject {
    @Published var statusMessage: String?
    @Published var isMarkingAsShared = false
    @Published var isCancelling = false
    
    private let post: ScheduledPost
    private let service: SocialMediaService
    
    init(post: ScheduledPost, service: SocialMediaService) {
        self.post = post
        self.service = service
    }
    
    func markAsShared() async {
        isMarkingAsShared = true
        defer { isMarkingAsShared = false }
        
        do {
            _ = try await service.updatePostStatus(post, status: .shared)
            // Cancel notification since post is now shared
            await NotificationService.shared.cancelPostReminder(postId: post.id)
            statusMessage = "Post marked as shared!"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    func cancelPost() async {
        isCancelling = true
        defer { isCancelling = false }
        
        do {
            _ = try await service.updatePostStatus(post, status: .cancelled)
            // Cancel notification since post is cancelled
            await NotificationService.shared.cancelPostReminder(postId: post.id)
            statusMessage = "Post cancelled"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}

