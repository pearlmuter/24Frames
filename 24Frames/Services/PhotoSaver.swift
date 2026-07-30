import Foundation
import Photos

public enum PhotoSaverError: Error, Equatable {
    case unauthorized
    case saveFailed(String)
}

public class PhotoSaver {
    private let photoLibrary: PhotoLibraryProtocol
    
    public init(photoLibrary: PhotoLibraryProtocol = PHPhotoLibrary.shared()) {
        self.photoLibrary = photoLibrary
    }
    
    public func savePhotoData(_ data: Data, completion: @escaping (Result<Void, PhotoSaverError>) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            performSave(data: data, completion: completion)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self?.performSave(data: data, completion: completion)
                } else {
                    completion(.failure(.unauthorized))
                }
            }
        case .denied, .restricted:
            completion(.failure(.unauthorized))
        @unknown default:
            completion(.failure(.unauthorized))
        }
    }
    
    private func performSave(data: Data, completion: @escaping (Result<Void, PhotoSaverError>) -> Void) {
        photoLibrary.performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
        }) { success, error in
            if success {
                completion(.success(()))
            } else {
                let errorMessage = error?.localizedDescription ?? "Unknown save error"
                completion(.failure(.saveFailed(errorMessage)))
            }
        }
    }
}
