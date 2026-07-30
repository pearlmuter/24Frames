import SwiftUI

public struct FlyToCornerAnimationView: View {
    public let image: UIImage
    public let onComplete: () -> Void
    
    @State private var isFlying = false
    
    public init(image: UIImage, onComplete: @escaping () -> Void) {
        self.image = image
        self.onComplete = onComplete
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: isFlying ? 80 : geometry.size.width * 0.9,
                           height: isFlying ? 106 : geometry.size.height * 0.65)
                    .cornerRadius(isFlying ? 12 : 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: isFlying ? 12 : 16)
                            .stroke(Color.white.opacity(0.8), lineWidth: isFlying ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: isFlying ? 4 : 16, x: 0, y: isFlying ? 2 : 8)
                    .scaleEffect(isFlying ? 0.35 : 1.0)
                    .offset(x: isFlying ? -geometry.size.width * 0.35 : 0,
                            y: isFlying ? geometry.size.height * 0.42 : 0)
                    .opacity(isFlying ? 0.0 : 1.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onAppear {
            // Hang around in place for 200ms before starting flight
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                // Ease in, ease out animation curve lasting 250ms
                withAnimation(.easeInOut(duration: 0.25)) {
                    isFlying = true
                }
            }
            
            // Clean up after 200ms hold + 250ms flight
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                onComplete()
            }
        }
    }
}
