import DroidBridgeCore
import Foundation
import Testing

struct DownloadFileTests {
    @Test func publishesCompleteDownload() throws {
        try withDestination { destination in
            try DownloadFile.write(to: destination, expectedBytes: 3) { file in
                try file.write(contentsOf: Data([1, 2, 3]))
            }
            let contents = try Data(contentsOf: destination)
            let entries = try names(beside: destination)
            #expect(contents == Data([1, 2, 3]))
            #expect(entries == ["report.bin"])
        }
    }

    @Test func validatesDownloadSizeAboveFourGiB() throws {
        try withDestination { destination in
            let size: UInt64 = 4_294_967_313
            try DownloadFile.write(to: destination, expectedBytes: size) { file in
                try file.truncate(atOffset: size)
            }
            let file = try FileHandle(forReadingFrom: destination)
            let length = try file.seekToEnd()
            #expect(length == size)
        }
    }

    @Test func rejectsShortDownloadAndRemovesTemporaryFile() throws {
        try withDestination { destination in
            #expect(throws: (any Error).self) {
                try DownloadFile.write(to: destination, expectedBytes: 3) { file in
                    try file.write(contentsOf: Data([1]))
                }
            }
            let entries = try names(beside: destination)
            #expect(entries.isEmpty)
        }
    }

    @Test func removesPartialDownloadWhenTransferThrows() throws {
        try withDestination { destination in
            #expect(throws: Disconnected.self) {
                try DownloadFile.write(to: destination, expectedBytes: 3) { file in
                    try file.write(contentsOf: Data([1]))
                    throw Disconnected()
                }
            }
            let entries = try names(beside: destination)
            #expect(entries.isEmpty)
        }
    }

    @Test func preservesDestinationCreatedDuringTransfer() throws {
        try withDestination { destination in
            #expect(throws: (any Error).self) {
                try DownloadFile.write(to: destination, expectedBytes: 3) { file in
                    try file.write(contentsOf: Data([1, 2, 3]))
                    try Data([4, 5]).write(to: destination)
                }
            }
            let contents = try Data(contentsOf: destination)
            let entries = try names(beside: destination)
            #expect(contents == Data([4, 5]))
            #expect(entries == ["report.bin"])
        }
    }

    private struct Disconnected: Error {}

    private func withDestination(_ test: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        try test(directory.appending(path: "report.bin"))
    }

    private func names(beside destination: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: destination.deletingLastPathComponent().path)
    }
}
