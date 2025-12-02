import SwiftUI

struct PlatformToggleButton: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let isShared: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 14, weight: .medium))
                Text(platform.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if isShared {
            return Color.green.opacity(0.2)
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else {
            return Color(UIColor.secondarySystemBackground)
        }
    }
    
    private var foregroundColor: Color {
        if isShared {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isShared {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

