import Foundation
import Photos

/// Protocol abstraction for PHPhotoLibrary to enable dependency injection and unit testing.
public protocol PhotoLibraryProtocol {
    func performChanges(_ changeBlock: @escaping @Sendable () -> Void, completionHandler: (@Sendable (Bool, Error?) -> Void)?)
}

extension PHPhotoLibrary: PhotoLibraryProtocol {}
