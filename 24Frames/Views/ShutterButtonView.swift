import SwiftUI

public struct ShutterButtonView: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
        .accessibilityLabel("Shutter")
        .accessibilityIdentifier("ShutterButton")
    }
}
