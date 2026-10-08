import SwiftUI

/// A custom symbol for a calisthenics exercise.
///
/// Each symbol has Ultralight, Regular and Black masters, so it follows the
/// font weight and Dynamic Type like an SF Symbol and sits beside text the
/// same way.
public enum CalisthenicsSymbol: String, CaseIterable, Sendable {
    case pullUp = "figure.pullup"
    case chinUp = "figure.chinup"
    case deadHang = "figure.deadhang"
    case invertedRow = "figure.invertedrow"
    case pushUp = "figure.pushup"
    case pikePushUp = "figure.pikepushup"
    case dip = "figure.dip"
    case squat = "figure.squat"
    case pistolSquat = "figure.pistolsquat"

    /// The symbol's name in the package's asset catalog.
    public var name: String { rawValue }

    /// The exercise the symbol shows, in English, for VoiceOver.
    public var accessibilityLabel: String {
        switch self {
        case .pullUp: "Pull-up"
        case .chinUp: "Chin-up"
        case .deadHang: "Dead hang"
        case .invertedRow: "Inverted row"
        case .pushUp: "Push-up"
        case .pikePushUp: "Pike push-up"
        case .dip: "Dip"
        case .squat: "Squat"
        case .pistolSquat: "Pistol squat"
        }
    }

    /// The bundle that holds the symbols, for loading them by name.
    public static var bundle: Bundle { .module }
}

extension Image {
    /// Creates an image of the symbol that VoiceOver reads as the exercise.
    public init(_ symbol: CalisthenicsSymbol) {
        self.init(symbol.name, bundle: .module, label: Text(symbol.accessibilityLabel))
    }

    /// Creates an image of the symbol that VoiceOver skips, for when the
    /// exercise name is already next to it.
    public init(decorative symbol: CalisthenicsSymbol) {
        self.init(decorative: symbol.name, bundle: .module)
    }
}

#if canImport(UIKit)
import UIKit

extension UIImage {
    /// Creates an image of the symbol.
    public convenience init?(
        _ symbol: CalisthenicsSymbol,
        withConfiguration configuration: UIImage.Configuration? = nil
    ) {
        self.init(named: symbol.name, in: .module, with: configuration)
    }
}
#elseif canImport(AppKit)
import AppKit

extension NSImage {
    /// Creates an image of the symbol, described as the exercise.
    @available(macOS 13, *)
    public convenience init?(_ symbol: CalisthenicsSymbol) {
        self.init(symbolName: symbol.name, bundle: .module, variableValue: 1)
        accessibilityDescription = symbol.accessibilityLabel
    }
}
#endif
