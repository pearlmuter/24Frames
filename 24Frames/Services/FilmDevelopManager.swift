import Foundation
import SwiftUI
import Combine

public struct PendingPhotoRoll: Codable {
    public var id: String
    public var fileNames: [String]
    public var submissionDate: Date
    public var targetDevelopDate: Date
    public var isDeveloping: Bool
}

public class FilmDevelopManager: ObservableObject {
    public static let shared = FilmDevelopManager()
    
    @Published public var pendingRollCount: Int = 0
    @Published public var activeRollPhotoCount: Int = 0
    
    private let fileManager = FileManager.default
    private var pendingDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PendingFilmRolls", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var activeRollDirectory: URL {
        let dir = pendingDirectory.appendingPathComponent("ActiveRoll", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public init() {
        refreshActiveCount()
    }
    
    public func refreshActiveCount() {
        let files = (try? fileManager.contentsOfDirectory(atPath: activeRollDirectory.path)) ?? []
        let photoFiles = files.filter { $0.hasSuffix(".heic") || $0.hasSuffix(".jpg") }
        DispatchQueue.main.async {
            self.activeRollPhotoCount = photoFiles.count
        }
    }
    
    public func savePhotoToActiveRoll(data: Data) {
        let filename = "\(UUID().uuidString).heic"
        let fileURL = activeRollDirectory.appendingPathComponent(filename)
        try? data.write(to: fileURL)
        refreshActiveCount()
    }
    
    private func exportPhotosToLibrary(_ photoFiles: [String], from dir: URL, photoSaver: PhotoSaver) {
        for fileName in photoFiles {
            let url = dir.appendingPathComponent(fileName)
            if let data = try? Data(contentsOf: url) {
                photoSaver.savePhotoData(data) { _ in }
            }
            try? fileManager.removeItem(at: url)
        }
    }
    
    public func sendRollToDevelop(speed: DevelopmentSpeed, photoSaver: PhotoSaver, completion: @escaping (Int) -> Void) {
        let files = (try? fileManager.contentsOfDirectory(atPath: activeRollDirectory.path)) ?? []
        let photoFiles = files.filter { $0.hasSuffix(".heic") || $0.hasSuffix(".jpg") }
        guard !photoFiles.isEmpty else {
            completion(0)
            return
        }
        
        let count = photoFiles.count
        let now = Date()
        let targetDate: Date
        
        switch speed {
        case .immediate:
            targetDate = now
        case .twoHours:
            targetDate = now.addingTimeInterval(2 * 3600)
        case .overnight:
            let calendar = Calendar.current
            var nextMorning = calendar.nextDate(after: now, matching: DateComponents(hour: 7, minute: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(12 * 3600)
            if nextMorning <= now {
                nextMorning = nextMorning.addingTimeInterval(24 * 3600)
            }
            targetDate = nextMorning
        }
        
        if targetDate <= now {
            // Immediate export
            exportPhotosToLibrary(photoFiles, from: activeRollDirectory, photoSaver: photoSaver)
            refreshActiveCount()
            completion(count)
        } else {
            // Move to pending roll directory with manifest
            let rollId = UUID().uuidString
            let rollDir = pendingDirectory.appendingPathComponent(rollId, isDirectory: true)
            try? fileManager.createDirectory(at: rollDir, withIntermediateDirectories: true)
            
            var movedFiles: [String] = []
            for fileName in photoFiles {
                let src = activeRollDirectory.appendingPathComponent(fileName)
                let dst = rollDir.appendingPathComponent(fileName)
                try? fileManager.moveItem(at: src, to: dst)
                movedFiles.append(fileName)
            }
            
            let rollManifest = PendingPhotoRoll(id: rollId, fileNames: movedFiles, submissionDate: now, targetDevelopDate: targetDate, isDeveloping: true)
            let manifestURL = rollDir.appendingPathComponent("manifest.json")
            if let manifestData = try? JSONEncoder().encode(rollManifest) {
                try? manifestData.write(to: manifestURL)
            }
            
            refreshActiveCount()
            completion(count)
        }
    }
    
    public func checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver) {
        let contents = (try? fileManager.contentsOfDirectory(atPath: pendingDirectory.path)) ?? []
        let now = Date()
        
        for dirName in contents {
            if dirName == "ActiveRoll" { continue }
            let rollDir = pendingDirectory.appendingPathComponent(dirName)
            let manifestURL = rollDir.appendingPathComponent("manifest.json")
            guard let manifestData = try? Data(contentsOf: manifestURL),
                  let manifest = try? JSONDecoder().decode(PendingPhotoRoll.self, from: manifestData) else {
                continue
            }
            
            if manifest.targetDevelopDate <= now {
                exportPhotosToLibrary(manifest.fileNames, from: rollDir, photoSaver: photoSaver)
                try? fileManager.removeItem(at: rollDir)
            }
        }
    }
}
