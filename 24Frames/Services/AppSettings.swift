import SwiftUI
import Combine

public enum DevelopmentSpeed: String, CaseIterable, Identifiable, Codable {
    case immediate = "Develop immediately"
    case twoHours = "Fast development: 2 Hours"
    case overnight = "Overnight development"
    
    public var id: String { self.rawValue }
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @AppStorage("isInfinitePicturesMode") public var isInfinitePicturesMode: Bool = false {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("isBlackAndWhiteMode") public var isBlackAndWhiteMode: Bool = false {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("isDevelopModeEnabled") public var isDevelopModeEnabled: Bool = false {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("developmentSpeedRaw") private var developmentSpeedRaw: String = DevelopmentSpeed.immediate.rawValue {
        willSet { objectWillChange.send() }
    }
    
    public var developmentSpeed: DevelopmentSpeed {
        get { DevelopmentSpeed(rawValue: developmentSpeedRaw) ?? .immediate }
        set { developmentSpeedRaw = newValue.rawValue }
    }
    
    @AppStorage("photosTakenToday") public var photosTakenToday: Int = 0 {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("hasSubmittedRollToday") public var hasSubmittedRollToday: Bool = false {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("lastResetDateString") private var lastResetDateString: String = "" {
        willSet { objectWillChange.send() }
    }
    
    public init() {
        checkDailyReset()
    }
    
    public func checkDailyReset() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        if lastResetDateString != todayString {
            lastResetDateString = todayString
            photosTakenToday = 0
            hasSubmittedRollToday = false
        }
    }
    
    public var remainingPhotosToday: Int {
        checkDailyReset()
        if isInfinitePicturesMode {
            return 999
        }
        return max(0, 24 - photosTakenToday)
    }
    
    public var canTakePhoto: Bool {
        checkDailyReset()
        if isInfinitePicturesMode { return true }
        if isDevelopModeEnabled && hasSubmittedRollToday { return false }
        return remainingPhotosToday > 0
    }
    
    public func incrementPhotoCount() {
        checkDailyReset()
        photosTakenToday += 1
    }
    
    public func resetPhotoCountForNewRoll() {
        photosTakenToday = 0
        hasSubmittedRollToday = false
    }
}
