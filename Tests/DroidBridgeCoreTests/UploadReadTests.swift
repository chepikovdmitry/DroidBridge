import CLibMTP
import Foundation
import Testing

struct UploadReadTests {
    @Test func earlyEOFStopsUpload() throws {
        let source = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data([1]).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        let handle = try FileHandle(forReadingFrom: source)
        var descriptor = handle.fileDescriptor
        var received: UInt32 = 0
        var buffer = [UInt8](repeating: 0, count: 2)

        let firstRead = droidbridge_read_upload(nil, &descriptor, 2, &buffer, &received)
        #expect(firstRead == LIBMTP_HANDLER_RETURN_OK)
        #expect(received == 1)
        #expect(buffer[0] == 1)

        let eof = droidbridge_read_upload(nil, &descriptor, 1, &buffer, &received)
        #expect(eof == LIBMTP_HANDLER_RETURN_ERROR)
        #expect(received == 0)
    }
}
