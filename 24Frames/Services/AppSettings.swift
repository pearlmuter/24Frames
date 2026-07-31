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
    
    @Published public var isInfinitePicturesMode: Bool = false
    @Published public var isBlackAndWhiteMode: Bool = false
    @Published public var isDevelopModeEnabled: Bool = false
    @Published public var developmentSpeedRaw: String = DevelopmentSpeed.immediate.rawValue
    @Published public var photosTakenToday: Int = 0
    @Published public var hasSubmittedRollToday: Bool = false
    
    public var developmentSpeed: DevelopmentSpeed {
        get { DevelopmentSpeed(rawValue: developmentSpeedRaw) ?? .immediate }
        set {
            developmentSpeedRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "developmentSpeedRaw")
        }
    }
    
    private var lastResetDateString: String {
        get { UserDefaults.standard.string(forKey: "lastResetDateString") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastResetDateString") }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var previousDevelopState: Bool = false
    
    public init() {
        UserDefaults.standard.register(defaults: [
            "isInfinitePicturesMode": false,
            "isBlackAndWhiteMode": false,
            "isDevelopModeEnabled": false,
            "developmentSpeedRaw": DevelopmentSpeed.immediate.rawValue,
            "photosTakenToday": 0,
            "hasSubmittedRollToday": false,
            "lastResetDateString": ""
        ])
        
        syncFromUserDefaults()
        previousDevelopState = isDevelopModeEnabled
        checkDailyReset()
        setupUserDefaultsObservers()
    }
    
    private func readBool(forKey key: String) -> Bool {
        let obj = UserDefaults.standard.object(forKey: key)
        if let b = obj as? Bool { return b }
        if let i = obj as? Int { return i != 0 }
        if let s = obj as? String { return (s as NSString).boolValue }
        return false
    }
    
    public func syncFromUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.synchronize()
        
        let newInfinite = readBool(forKey: "isInfinitePicturesMode")
        let newBW = readBool(forKey: "isBlackAndWhiteMode")
        let newDevelop = readBool(forKey: "isDevelopModeEnabled")
        let newSpeed = defaults.string(forKey: "developmentSpeedRaw") ?? DevelopmentSpeed.immediate.rawValue
        let newPhotosTaken = defaults.integer(forKey: "photosTakenToday")
        let newHasSubmitted = readBool(forKey: "hasSubmittedRollToday")
        
        DispatchQueue.main.async {
            if self.isInfinitePicturesMode != newInfinite { self.isInfinitePicturesMode = newInfinite }
            if self.isBlackAndWhiteMode != newBW { self.isBlackAndWhiteMode = newBW }
            if self.isDevelopModeEnabled != newDevelop { self.isDevelopModeEnabled = newDevelop }
            if self.developmentSpeedRaw != newSpeed { self.developmentSpeedRaw = newSpeed }
            if self.photosTakenToday != newPhotosTaken { self.photosTakenToday = newPhotosTaken }
            if self.hasSubmittedRollToday != newHasSubmitted { self.hasSubmittedRollToday = newHasSubmitted }
            
            if self.previousDevelopState == true && self.isDevelopModeEnabled == false {
                FilmDevelopManager.shared.flushAllPendingAndActiveRollsToCameraRoll(photoSaver: PhotoSaver())
            }
            self.previousDevelopState = self.isDevelopModeEnabled
            
            if self.developmentSpeed == .immediate {
                FilmDevelopManager.shared.checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver())
            }
        }
    }
    
    private func setupUserDefaultsObservers() {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromUserDefaults()
            }
            .store(in: &cancellables)
    }
    
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
        UserDefaults.standard.set(photosTakenToday, forKey: "photosTakenToday")
    }
    
    public func resetPhotoCountForNewRoll() {
        photosTakenToday = 0
        hasSubmittedRollToday = false
        UserDefaults.standard.set(0, forKey: "photosTakenToday")
        UserDefaults.standard.set(false, forKey: "hasSubmittedRollToday")
    }
}
