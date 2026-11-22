import Darwin
import Foundation

public enum DownloadFile {
    public static func write(
        to destination: URL,
        expectedBytes: UInt64,
        transfer: (FileHandle) throws -> Void
    ) throws {
        let template = destination.deletingLastPathComponent()
            .appending(path: ".droidbridge.XXXXXX")
        var path = Array(template.path.utf8CString)
        let descriptor = mkstemp(&path)
        guard descriptor >= 0 else { throw posixError(errno) }
        var published = false
        defer {
            if !published { _ = unlink(path) }
        }

        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        try transfer(file)

        var info = stat()
        guard fstat(descriptor, &info) == 0 else { throw posixError(errno) }
        guard let actualBytes = UInt64(exactly: info.st_size), actualBytes == expectedBytes else {
            throw SizeMismatch(expectedBytes: expectedBytes, actualBytes: info.st_size)
        }

        try file.close()
        let status = destination.withUnsafeFileSystemRepresentation { destinationPath in
            renamex_np(path, destinationPath, UInt32(RENAME_EXCL))
        }
        guard status == 0 else { throw posixError(errno) }
        published = true
    }

    private static func posixError(_ code: Int32) -> POSIXError {
        POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
    }

    private struct SizeMismatch: LocalizedError {
        let expectedBytes: UInt64
        let actualBytes: Int64

        var errorDescription: String? {
            "Downloaded \(actualBytes) bytes. Expected \(expectedBytes) bytes."
        }
    }
}
