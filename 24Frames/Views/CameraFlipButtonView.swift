import SwiftUI

public struct CameraFlipButtonView: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel("Switch Camera")
        .accessibilityIdentifier("CameraFlipButton")
    }
}
