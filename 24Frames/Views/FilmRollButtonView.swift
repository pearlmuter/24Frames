import SwiftUI

public struct FilmRollButtonView: View {
    public var rollCount: Int
    public var action: () -> Void
    
    public init(rollCount: Int, action: @escaping () -> Void) {
        self.rollCount = rollCount
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image("FilmRollArrow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                    .colorMultiply(.white)
                
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
