import Foundation

enum TartLocatorError: LocalizedError {
    case notFound
    case invalidExecutable(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Tart could not be found"
        case let .invalidExecutable(path):
            return "The selected Tart executable is missing or cannot be executed: \(path)"
        }
    }
}

struct TartLocator {
    func locate(executableURL: URL? = nil) throws -> String {
        if let executableURL {
            let path = executableURL.path(percentEncoded: false)
            guard executableURL.isFileURL, isExecutableFile(atPath: path) else {
                throw TartLocatorError.invalidExecutable(path)
            }
            return path
        }
        let candidates = ["/opt/homebrew/bin/tart", "/Applications/tart.app/Contents/MacOS/tart"]
        guard let filePath = candidates.first(where: { isExecutableFile(atPath: $0) }) else {
            throw TartLocatorError.notFound
        }
        return filePath
    }

    private func isExecutableFile(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
            && fileManager.isExecutableFile(atPath: path)
    }
}
