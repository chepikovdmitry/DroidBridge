import DroidBridgeCore
import Testing

struct TransferNameTests {
    @Test func batchIndexRecognizesExistingAndNewNames() {
        var names = TransferName.Index(["photo.jpg", "PHOTO 2.JPG"])
        #expect(names.available("Photo.JPG") == "Photo 3.JPG")
        names.insert("Photo 3.JPG")
        #expect(names.available("PHOTO.jpg") == "PHOTO 4.jpg")
        #expect(names.available("other.jpg") == "other.jpg")
    }

    @Test func choosesAvailableNameWithoutOverwriting() {
        let name = TransferName.available("Photo.JPG", among: ["photo.jpg", "PHOTO 2.jpg"])
        #expect(name == "Photo 3.JPG")
    }

    @Test func keepsCompoundFileNameAndUnicode() {
        #expect(TransferName.available("архив.tar.gz", among: ["архив.tar.gz"]) == "архив.tar 2.gz")
    }

    @Test func rejectsNamesThatEscapeTargetFolder() {
        for name in ["", ".", "..", "../outside", "/tmp/file", "a/b", "a\0b"] {
            #expect(!TransferName.isComponent(name))
        }
        #expect(TransferName.isComponent("Отпуск 2026.jpg"))
    }
}
