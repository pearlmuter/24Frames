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
    
    public var isInfinitePicturesMode: Bool {
        get { UserDefaults.standard.bool(forKey: "isInfinitePicturesMode") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isInfinitePicturesMode")
            objectWillChange.send()
        }
    }
    
    public var isBlackAndWhiteMode: Bool {
        get { UserDefaults.standard.bool(forKey: "isBlackAndWhiteMode") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isBlackAndWhiteMode")
            objectWillChange.send()
        }
    }
    
    public var isDevelopModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isDevelopModeEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isDevelopModeEnabled")
            objectWillChange.send()
        }
    }
    
    @AppStorage("developmentSpeedRaw") public var developmentSpeedRaw: String = DevelopmentSpeed.immediate.rawValue
    
    public var developmentSpeed: DevelopmentSpeed {
        get {
            let raw = UserDefaults.standard.string(forKey: "developmentSpeedRaw") ?? developmentSpeedRaw
            return DevelopmentSpeed(rawValue: raw) ?? .immediate
        }
        set {
            developmentSpeedRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "developmentSpeedRaw")
            objectWillChange.send()
        }
    }
    
    @AppStorage("photosTakenToday") public var photosTakenToday: Int = 0
    @AppStorage("hasSubmittedRollToday") public var hasSubmittedRollToday: Bool = false
    @AppStorage("lastResetDateString") private var lastResetDateString: String = ""
    
    private var observer: AnyCancellable?
    private var previousDevelopState: Bool = false
    
    public init() {
        previousDevelopState = isDevelopModeEnabled
        checkDailyReset()
        setupUserDefaultsObserver()
    }
    
    private func setupUserDefaultsObserver() {
        observer = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.objectWillChange.send()
                
                let currentDevelopState = self.isDevelopModeEnabled
                if self.previousDevelopState == true && currentDevelopState == false {
                    FilmDevelopManager.shared.flushAllPendingAndActiveRollsToCameraRoll(photoSaver: PhotoSaver())
                }
                self.previousDevelopState = currentDevelopState
                
                if self.developmentSpeed == .immediate {
                    FilmDevelopManager.shared.checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver())
                }
            }
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
        if photosTakenToday >= 24 && !isInfinitePicturesMode {
            return 0
        }
        let photosInRoll = photosTakenToday % 24
        return max(0, 24 - photosInRoll)
    }
    
    public var canTakePhoto: Bool {
        checkDailyReset()
        if isInfinitePicturesMode { return true }
        if isDevelopModeEnabled && hasSubmittedRollToday { return false }
        return photosTakenToday < 24
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
