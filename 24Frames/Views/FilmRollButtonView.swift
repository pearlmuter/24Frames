import SwiftUI

public struct FilmRollButtonView: View {
    public var rollCount: Int
    public var countdownString: String?
    public var action: () -> Void
    
    public init(rollCount: Int, countdownString: String? = nil, action: @escaping () -> Void) {
        self.rollCount = rollCount
        self.countdownString = countdownString
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let timerStr = countdownString {
                    Text(timerStr)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                }
                
                ZStack(alignment: .topTrailing) {
                    Image("FilmRollArrow")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .cornerRadius(6)
                    
                    if rollCount > 0 {
                        Text("\(rollCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.red))
                            .offset(x: 6, y: -4)
                    }
                }
            }
        }
    }
}
