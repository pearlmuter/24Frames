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
    
    @AppStorage("isInfinitePicturesMode") public var isInfinitePicturesMode: Bool = false
    @AppStorage("isBlackAndWhiteMode") public var isBlackAndWhiteMode: Bool = false
    @AppStorage("isDevelopModeEnabled") public var isDevelopModeEnabled: Bool = false
    @AppStorage("developmentSpeedRaw") public var developmentSpeedRaw: String = DevelopmentSpeed.immediate.rawValue
    
    public var developmentSpeed: DevelopmentSpeed {
        get { DevelopmentSpeed(rawValue: developmentSpeedRaw) ?? .immediate }
        set { developmentSpeedRaw = newValue.rawValue }
    }
    
    @AppStorage("photosTakenToday") public var photosTakenToday: Int = 0
    @AppStorage("hasSubmittedRollToday") public var hasSubmittedRollToday: Bool = false
    @AppStorage("lastResetDateString") private var lastResetDateString: String = ""
    
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
    
    private func setupUserDefaultsObservers() {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleNotification()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UserDefaults.standard.synchronize()
                self?.handleNotification()
            }
            .store(in: &cancellables)
    }
    
    private func handleNotification() {
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
