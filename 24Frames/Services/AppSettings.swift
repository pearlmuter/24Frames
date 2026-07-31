import SwiftUI
import Combine
import UIKit

public enum DevelopmentSpeed: String, CaseIterable, Identifiable, Codable {
    case immediate = "Develop immediately"
    case twoHours = "Fast development: 2 Hours"
    case overnight = "Overnight development"
    
    public var id: String { self.rawValue }
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private var cancellables = Set<AnyCancellable>()
    private var previousDevelopState: Bool = false
    
    public init() {
        UserDefaults.standard.register(defaults: [
            "isInfinitePicturesMode": false,
            "isBlackAndWhiteMode": false,
            "isDevelopModeEnabled": false,
            "developmentSpeedRaw": DevelopmentSpeed.immediate.rawValue
        ])
        
        previousDevelopState = isDevelopModeEnabled
        checkDailyReset()
        setupUserDefaultsObservers()
    }
    
    public var isInfinitePicturesMode: Bool {
        get { readBool(forKey: "isInfinitePicturesMode") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isInfinitePicturesMode")
            objectWillChange.send()
        }
    }
    
    public var isBlackAndWhiteMode: Bool {
        get { readBool(forKey: "isBlackAndWhiteMode") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isBlackAndWhiteMode")
            objectWillChange.send()
        }
    }
    
    public var isDevelopModeEnabled: Bool {
        get { readBool(forKey: "isDevelopModeEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "isDevelopModeEnabled")
            objectWillChange.send()
        }
    }
    
    public var developmentSpeedRaw: String {
        get { UserDefaults.standard.string(forKey: "developmentSpeedRaw") ?? DevelopmentSpeed.immediate.rawValue }
        set {
            UserDefaults.standard.set(newValue, forKey: "developmentSpeedRaw")
            objectWillChange.send()
        }
    }
    
    public var developmentSpeed: DevelopmentSpeed {
        get { DevelopmentSpeed(rawValue: developmentSpeedRaw) ?? .immediate }
        set { developmentSpeedRaw = newValue.rawValue }
    }
    
    @AppStorage("photosTakenToday") public var photosTakenToday: Int = 0
    @AppStorage("hasSubmittedRollToday") public var hasSubmittedRollToday: Bool = false
    @AppStorage("lastResetDateString") private var lastResetDateString: String = ""
    
    private func readBool(forKey key: String) -> Bool {
        let obj = UserDefaults.standard.object(forKey: key)
        if let b = obj as? Bool { return b }
        if let i = obj as? Int { return i != 0 }
        if let s = obj as? String { return (s as NSString).boolValue }
        return false
    }
    
    private func setupUserDefaultsObservers() {
        // Observe UserDefaults change notifications
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSettingsChange()
            }
            .store(in: &cancellables)
        
        // Observe app entering foreground to synchronize system Settings changes
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UserDefaults.standard.synchronize()
                self?.handleSettingsChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleSettingsChange() {
        objectWillChange.send()
        
        let currentDevelopState = isDevelopModeEnabled
        if previousDevelopState == true && currentDevelopState == false {
            FilmDevelopManager.shared.flushAllPendingAndActiveRollsToCameraRoll(photoSaver: PhotoSaver())
        }
        previousDevelopState = currentDevelopState
        
        if developmentSpeed == .immediate {
            FilmDevelopManager.shared.checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver())
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
