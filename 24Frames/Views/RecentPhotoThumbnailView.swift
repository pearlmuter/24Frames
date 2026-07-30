import SwiftUI

public struct RecentPhotoThumbnailView: View {
    public let image: UIImage?
    public let action: () -> Void
    
    public init(image: UIImage?, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .accessibilityLabel("Open Photo Library")
        .accessibilityIdentifier("RecentPhotoThumbnailButton")
    }
}
