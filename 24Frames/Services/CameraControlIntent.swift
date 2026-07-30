import AppIntents
import SwiftUI

@available(iOS 16.0, *)
public struct CapturePhotoIntent: AppIntent {
    public static var title: LocalizedStringResource = "Take Photo with 24Frames"
    public static var description = IntentDescription("Launches 24Frames and captures an unenhanced Base Capture photo.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        if #available(iOS 18.0, *) {
            return .result(opensIntent: OpenURLIntent(URL(string: "twentyfourframes://snap")!))
        } else {
            return .result()
        }
    }
}
