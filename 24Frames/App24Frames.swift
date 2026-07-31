import SwiftUI

@main
struct App24Frames: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("[App24Frames] scenePhase → .active — forcing settings sync")
                AppSettings.shared.syncFromUserDefaults()
            }
        }
    }
}
