import SwiftUI

public struct PermissionDeniedView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("24Frames requires camera access to capture Base Capture photos without AI processing.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
