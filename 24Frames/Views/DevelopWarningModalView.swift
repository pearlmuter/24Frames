import SwiftUI

public struct DevelopWarningModalView: View {
    let photoCount: Int
    let isInfiniteMode: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    public init(
        photoCount: Int,
        isInfiniteMode: Bool,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.photoCount = photoCount
        self.isInfiniteMode = isInfiniteMode
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.65)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // Creamy White Modal Card
            VStack(spacing: 0) {
                // Top Header: Watercolor Illustration with Faded Edges
                ZStack(alignment: .topTrailing) {
                    Image("japanese_tourist_watercolor")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color(red: 0.98, green: 0.97, blue: 0.94).opacity(0.3),
                                    Color(red: 0.98, green: 0.97, blue: 0.94)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Close button (top-right)
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(14)
                    }
                }
                
                VStack(spacing: 16) {
                    // Modal Title
                    Text("Develop Film Roll?")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.15, green: 0.12, blue: 0.1))
                        .multilineTextAlignment(.center)
                    
                    // Photo Count Badge
                    HStack(spacing: 6) {
                        Image(systemName: "film")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.25))
                        
                        Text("Roll of \(photoCount) \(photoCount == 1 ? "picture" : "pictures")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.25))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.85, green: 0.35, blue: 0.25).opacity(0.12))
                    .cornerRadius(20)
                    
                    // Explanation & Warning Text
                    VStack(spacing: 8) {
                        if isInfiniteMode {
                            Text("Ready to send your photos to the lab!")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.2))
                                .multilineTextAlignment(.center)
                            
                            Text("With Infinite Pictures Mode ON, your roll counter will reset to **24** so you can start taking another roll immediately.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.4))
                                .multilineTextAlignment(.center)
                        } else {
                            Text("You can only get **one roll** of pictures for today.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.2))
                                .multilineTextAlignment(.center)
                            
                            Text("Once submitted to development, your remaining roll count for today will be set to **0**. You won't be able to take any more photos until tomorrow.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.4))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: onConfirm) {
                            Text("Develop Roll")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.88, green: 0.35, blue: 0.25),
                                            Color(red: 0.78, green: 0.25, blue: 0.18)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color(red: 0.78, green: 0.25, blue: 0.18).opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.4))
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
                .background(Color(red: 1.0, green: 0.992, blue: 0.969)) // Creamy White (#FFFDF7)
            }
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: true)
    }
}
