import SwiftUI

struct ContentPreviewView: View {
    let content: String
    let platform: MarketingPlatform
    let title: String?
    let scheduledDate: Date?
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedPreview: PreviewStyle = .feed
    
    enum PreviewStyle: String, CaseIterable {
        case feed = "Feed"
        case story = "Story"
        case reel = "Reel"
        case carousel = "Carousel"
        
        var iconName: String {
            switch self {
            case .feed: return "square.text.square"
            case .story: return "circle.grid.cross"
            case .reel: return "play.rectangle"
            case .carousel: return "square.stack"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview Style Picker
            if platform == .instagram {
                Picker("Preview Style", selection: $selectedPreview) {
                    ForEach(PreviewStyle.allCases, id: \.self) { style in
                        Label(style.rawValue, systemImage: style.iconName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            // Platform Preview
            ScrollView {
                VStack(spacing: 20) {
                    platformPreview
                    
                    Divider()
                    
                    // Content Details
                    contentDetails
                }
                .padding()
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var platformPreview: some View {
        switch platform {
        case .instagram:
            instagramPreview
        case .facebook:
            facebookPreview
        case .linkedin:
            linkedInPreview
        case .twitter:
            twitterPreview
        case .tiktok:
            tiktokPreview
        case .youtube:
            youtubePreview
        case .pinterest:
            pinterestPreview
        case .email:
            emailPreview
        }
    }
    
    private var instagramPreview: some View {
        VStack(spacing: 0) {
            switch selectedPreview {
            case .feed:
                InstagramFeedPreview(content: content, title: title)
            case .story:
                InstagramStoryPreview(content: content, title: title)
            case .reel:
                InstagramReelPreview(content: content, title: title)
            case .carousel:
                InstagramCarouselPreview(content: content, title: title)
            }
        }
    }
    
    private var facebookPreview: some View {
        FacebookPreview(content: content, title: title)
    }
    
    private var linkedInPreview: some View {
        LinkedInPreview(content: content, title: title)
    }
    
    private var twitterPreview: some View {
        TwitterPreview(content: content, title: title)
    }
    
    private var tiktokPreview: some View {
        TikTokPreview(content: content, title: title)
    }
    
    private var youtubePreview: some View {
        YouTubePreview(content: content, title: title)
    }
    
    private var pinterestPreview: some View {
        PinterestPreview(content: content, title: title)
    }
    
    private var emailPreview: some View {
        EmailPreview(content: content, title: title)
    }
    
    private var contentDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Details")
                .font(.headline)
            
            if let title = title {
                DetailRow(label: "Title", value: title)
            }
            
            DetailRow(label: "Platform", value: platform.rawValue)
            
            if let date = scheduledDate {
                DetailRow(label: "Scheduled", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            
            DetailRow(label: "Character Count", value: "\(content.count)")
            
            DetailRow(label: "Word Count", value: "\(content.split(separator: " ").count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Platform-Specific Previews

struct InstagramFeedPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title ?? "Username")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Location")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Text(content)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                HStack {
                    Image(systemName: "heart")
                    Image(systemName: "message")
                    Image(systemName: "paperplane")
                    Spacer()
                    Image(systemName: "bookmark")
                }
                .font(.system(size: 24))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(maxWidth: 375)
    }
}

struct InstagramStoryPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [.purple, .pink, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 216, height: 384)
            .overlay(
                VStack(spacing: 12) {
                    Text(title ?? "Your Story")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(content)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            )
    }
}

struct InstagramReelPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black)
            .frame(width: 216, height: 384)
            .overlay(
                VStack(spacing: 8) {
                    Text(title ?? "Reel Title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    Text(content)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                        Text("1.2K")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom)
                }
            )
    }
}

struct InstagramCarouselPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
            }
            .tabViewStyle(.page)
            .frame(height: 300)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(maxWidth: 375)
    }
}

struct FacebookPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "Page Name")
                        .font(.system(size: 15, weight: .semibold))
                    Text("2h")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            
            Text(content)
                .font(.system(size: 15))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .frame(maxWidth: 500)
    }
}

struct LinkedInPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "Your Name")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Software Developer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("2h")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(content)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .frame(maxWidth: 600)
    }
}

struct TwitterPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "Username")
                        .font(.system(size: 15, weight: .bold))
                    Text("@username · 2h")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(content)
                .font(.system(size: 15))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .frame(maxWidth: 550)
    }
}

struct TikTokPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black)
            .frame(width: 270, height: 480)
            .overlay(
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("@username")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(content)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .lineLimit(3)
                        }
                        .padding()
                        Spacer()
                    }
                }
            )
    }
}

struct YouTubePreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red)
                .frame(height: 202)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                )
            
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "Video Title")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                    Text("Channel Name · 1.2K views")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: 360)
    }
}

struct PinterestPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            if let title = title {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .lineLimit(2)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 236)
    }
}

struct EmailPreview: View {
    let content: String
    let title: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
            }
            
            Divider()
            
            Text(content)
                .font(.system(size: 16))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .frame(maxWidth: 600)
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

