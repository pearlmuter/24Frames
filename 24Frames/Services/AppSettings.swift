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
    
    // These @Published properties are the single source of truth for SwiftUI views.
    // Every mutation (whether from in-app toggles or system Settings) must go through
    // the setters below, which write-through to UserDefaults so that:
    //   (a) system Settings.bundle always reflects the current state, and
    //   (b) syncFromUserDefaults() reads back the same value we wrote.
    
    @Published public var isInfinitePicturesMode: Bool = false {
        didSet {
            if isInfinitePicturesMode != oldValue {
                UserDefaults.standard.set(isInfinitePicturesMode, forKey: "isInfinitePicturesMode")
                print("[AppSettings] isInfinitePicturesMode changed: \(oldValue) → \(isInfinitePicturesMode)")
            }
        }
    }
    
    @Published public var isBlackAndWhiteMode: Bool = false {
        didSet {
            if isBlackAndWhiteMode != oldValue {
                UserDefaults.standard.set(isBlackAndWhiteMode, forKey: "isBlackAndWhiteMode")
                print("[AppSettings] isBlackAndWhiteMode changed: \(oldValue) → \(isBlackAndWhiteMode)")
            }
        }
    }
    
    @Published public var isDevelopModeEnabled: Bool = false {
        didSet {
            if isDevelopModeEnabled != oldValue {
                UserDefaults.standard.set(isDevelopModeEnabled, forKey: "isDevelopModeEnabled")
                print("[AppSettings] isDevelopModeEnabled changed: \(oldValue) → \(isDevelopModeEnabled)")
                // Auto-export pending rolls when Develop Mode is turned OFF
                if oldValue == true && isDevelopModeEnabled == false {
                    FilmDevelopManager.shared.flushAllPendingAndActiveRollsToCameraRoll(photoSaver: PhotoSaver())
                }
            }
        }
    }
    
    @Published public var developmentSpeedRaw: String = DevelopmentSpeed.immediate.rawValue {
        didSet {
            if developmentSpeedRaw != oldValue {
                UserDefaults.standard.set(developmentSpeedRaw, forKey: "developmentSpeedRaw")
                print("[AppSettings] developmentSpeedRaw changed: \(oldValue) → \(developmentSpeedRaw)")
                if developmentSpeed == .immediate {
                    FilmDevelopManager.shared.checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver())
                }
            }
        }
    }
    
    @Published public var photosTakenToday: Int = 0
    @Published public var hasSubmittedRollToday: Bool = false
    
    public var developmentSpeed: DevelopmentSpeed {
        get { DevelopmentSpeed(rawValue: developmentSpeedRaw) ?? .immediate }
        set { developmentSpeedRaw = newValue.rawValue }
    }
    
    private var lastResetDateString: String {
        get { UserDefaults.standard.string(forKey: "lastResetDateString") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastResetDateString") }
    }
    
    private var cancellables = Set<AnyCancellable>()
    /// Guard against re-entrant sync cycles (didSet writes → notification → sync → didSet)
    private var isSyncing = false
    
    public init() {
        // register(defaults:) only provides fallback values when no value has been set.
        // It does NOT overwrite values already persisted by Settings.bundle or the app.
        UserDefaults.standard.register(defaults: [
            "isInfinitePicturesMode": false,
            "isBlackAndWhiteMode": false,
            "isDevelopModeEnabled": false,
            "developmentSpeedRaw": DevelopmentSpeed.immediate.rawValue,
            "photosTakenToday": 0,
            "hasSubmittedRollToday": false,
            "lastResetDateString": ""
        ])
        
        // Read whatever is on disk RIGHT NOW (from Settings.bundle or prior app sessions)
        syncFromUserDefaults()
        checkDailyReset()
        setupNotificationObservers()
        
        print("[AppSettings] INIT complete — BW=\(isBlackAndWhiteMode), infinite=\(isInfinitePicturesMode), develop=\(isDevelopModeEnabled), speed=\(developmentSpeedRaw)")
    }
    
    // MARK: - UserDefaults ↔ @Published Sync
    
    /// Reads raw values from UserDefaults.standard and updates @Published properties.
    /// Called on init, on UserDefaults.didChangeNotification, and on willEnterForeground.
    public func syncFromUserDefaults() {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        let defaults = UserDefaults.standard
        defaults.synchronize()
        
        let newInfinite = readBool(forKey: "isInfinitePicturesMode")
        let newBW = readBool(forKey: "isBlackAndWhiteMode")
        let newDevelop = readBool(forKey: "isDevelopModeEnabled")
        let newSpeed = defaults.string(forKey: "developmentSpeedRaw") ?? DevelopmentSpeed.immediate.rawValue
        let newPhotosTaken = defaults.integer(forKey: "photosTakenToday")
        let newHasSubmitted = readBool(forKey: "hasSubmittedRollToday")
        
        print("[AppSettings] syncFromUserDefaults — disk: BW=\(newBW), infinite=\(newInfinite), develop=\(newDevelop), speed=\(newSpeed) | memory: BW=\(isBlackAndWhiteMode), infinite=\(isInfinitePicturesMode), develop=\(isDevelopModeEnabled)")
        
        // Only update if different (the didSet guards against equal-value writes,
        // but skipping here avoids unnecessary objectWillChange publishes)
        if isInfinitePicturesMode != newInfinite { isInfinitePicturesMode = newInfinite }
        if isBlackAndWhiteMode != newBW { isBlackAndWhiteMode = newBW }
        if isDevelopModeEnabled != newDevelop { isDevelopModeEnabled = newDevelop }
        if developmentSpeedRaw != newSpeed { developmentSpeedRaw = newSpeed }
        if photosTakenToday != newPhotosTaken { photosTakenToday = newPhotosTaken }
        if hasSubmittedRollToday != newHasSubmitted { hasSubmittedRollToday = newHasSubmitted }
    }
    
    /// Reads a bool from UserDefaults, handling the various representations that
    /// Settings.bundle / older code may have written (Bool, Int 0/1, String "YES"/"NO").
    private func readBool(forKey key: String) -> Bool {
        let obj = UserDefaults.standard.object(forKey: key)
        if obj == nil {
            // No value stored at all — fall through to registered default
            return UserDefaults.standard.bool(forKey: key)
        }
        if let b = obj as? Bool { return b }
        if let n = obj as? NSNumber { return n.boolValue }
        if let s = obj as? String { return (s as NSString).boolValue }
        return false
    }
    
    private func setupNotificationObservers() {
        // didBecomeActive is the most reliable notification for detecting return from
        // the Settings app — it fires even on quick swipe-back gestures where
        // willEnterForeground may not fire.
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[AppSettings] didBecomeActive — syncing from UserDefaults")
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[AppSettings] willEnterForeground — syncing from UserDefaults")
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
        
        // Also listen for changes made while the app is in the foreground (e.g. via
        // the in-app SettingsView, or split-screen on iPad).
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Daily Reset
    
    public func checkDailyReset() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        if lastResetDateString != todayString {
            lastResetDateString = todayString
            photosTakenToday = 0
            hasSubmittedRollToday = false
            UserDefaults.standard.set(0, forKey: "photosTakenToday")
            UserDefaults.standard.set(false, forKey: "hasSubmittedRollToday")
        }
    }
    
    // MARK: - Computed State
    
    public var remainingPhotosToday: Int {
        checkDailyReset()
        // Always show remaining photos in the current 24-photo roll.
        // Toggling infinite mode on/off doesn't change the counter —
        // it only determines whether a new roll auto-starts when you hit 0.
        let photosInRoll = photosTakenToday % 24
        if photosInRoll == 0 && photosTakenToday > 0 {
            // Completed a full roll. In infinite mode a new roll starts (24);
            // without infinite mode, this roll is spent (0).
            return isInfinitePicturesMode ? 24 : 0
        }
        return 24 - photosInRoll
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
        UserDefaults.standard.set(photosTakenToday, forKey: "photosTakenToday")
    }
    
    public func resetPhotoCountForNewRoll() {
        photosTakenToday = 0
        hasSubmittedRollToday = false
        UserDefaults.standard.set(0, forKey: "photosTakenToday")
        UserDefaults.standard.set(false, forKey: "hasSubmittedRollToday")
    }
}
