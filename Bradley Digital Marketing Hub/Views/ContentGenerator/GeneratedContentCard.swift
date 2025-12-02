import SwiftUI

struct GeneratedContentCard: View {
    @Binding var item: ContentGeneratorViewModel.GeneratedContentItem
    let index: Int
    @State private var isEditing = false
    @State private var editedText: String
    let onContentUpdate: (String) -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onFavorite: () -> Void
    let onRegenerate: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    init(item: Binding<ContentGeneratorViewModel.GeneratedContentItem>, index: Int, onContentUpdate: @escaping (String) -> Void, onCopy: @escaping () -> Void, onSave: @escaping () -> Void, onFavorite: @escaping () -> Void, onRegenerate: @escaping () -> Void) {
        self._item = item
        self.index = index
        self.onContentUpdate = onContentUpdate
        self.onCopy = onCopy
        self.onSave = onSave
        self.onFavorite = onFavorite
        self.onRegenerate = onRegenerate
        self._editedText = State(initialValue: item.wrappedValue.content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Idea #\(index + 1)")
                    .font(.headline)
                Spacer()
                Text(item.platform.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.colors(for: colorScheme).primary.opacity(0.1))
                    .foregroundColor(themeManager.colors(for: colorScheme).primary)
                    .cornerRadius(6)
            }
            
            // Content
            if isEditing {
                TextEditor(text: $editedText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.colors(for: colorScheme).primary, lineWidth: 1)
                    )
                
                HStack {
                    Button("Cancel") {
                        editedText = item.content
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save") {
                        item.content = editedText
                        onContentUpdate(editedText)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.colors(for: colorScheme).primary)
                }
            } else {
                Text(item.content)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        isEditing = true
                        editedText = item.content
                    }
            }
            
            // Action Buttons
            if !isEditing {
                HStack(spacing: 8) {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { 
                        isEditing = true
                        editedText = item.content
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onFavorite) {
                        Label("Favorite", systemImage: "heart")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onRegenerate) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(action: onSave) {
                        Label("Save to Calendar", systemImage: "tray.and.arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.colors(for: colorScheme).primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
