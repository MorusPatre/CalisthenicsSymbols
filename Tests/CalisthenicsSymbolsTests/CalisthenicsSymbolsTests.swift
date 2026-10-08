import XCTest
@testable import CalisthenicsSymbols

final class CalisthenicsSymbolsTests: XCTestCase {
    func testEverySymbolLoadsAsASymbolImage() throws {
        for symbol in CalisthenicsSymbol.allCases {
            #if canImport(UIKit)
            let image = try XCTUnwrap(UIImage(symbol), symbol.name)
            XCTAssertTrue(image.isSymbolImage, symbol.name)
            #else
            guard #available(macOS 13, *) else { throw XCTSkip("Needs macOS 13") }
            XCTAssertNotNil(NSImage(symbol), symbol.name)
            #endif
        }
    }

    func testEverySymbolSetHasACase() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../Sources/CalisthenicsSymbols/Resources/Symbols.xcassets")
            .standardized
        let symbolSets = try FileManager.default.contentsOfDirectory(atPath: catalog.path)
            .filter { $0.hasSuffix(".symbolset") }
            .map { String($0.dropLast(".symbolset".count)) }
        XCTAssertEqual(Set(symbolSets), Set(CalisthenicsSymbol.allCases.map(\.name)))
    }
}
