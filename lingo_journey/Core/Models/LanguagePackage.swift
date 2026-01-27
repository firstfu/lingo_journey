import Foundation
import SwiftData

@Model
final class LanguagePackage {
    var languageCode: String
    var displayName: String
    var isDownloaded: Bool
    var downloadedAt: Date?
    var fileSize: Int64

    init(languageCode: String, displayName: String, fileSize: Int64 = 0) {
        self.languageCode = languageCode
        self.displayName = displayName
        self.isDownloaded = false
        self.fileSize = fileSize
    }
}
