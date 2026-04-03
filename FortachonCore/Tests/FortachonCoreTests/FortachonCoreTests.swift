import Testing
@testable import FortachonCore

struct FortachonCoreTests {
    @Test func testSmoke() async throws {
        #expect(FortachonCore.version() == "0.1.0")
    }
}