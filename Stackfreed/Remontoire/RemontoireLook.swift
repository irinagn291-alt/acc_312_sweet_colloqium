import SwiftUI

/// Role: Remontoire. The only Color, Font, and Spacing accessors. Named catalog colours. Hex is recorded here once.
enum RemontoireLook {
    enum Color {
        /// Screen background #FCFCFC
        static let background = SwiftUI.Color("background")
        /// Cards, rows, sheets #F5F5F5
        static let surface = SwiftUI.Color("surface")
        /// Primary text and icons #121212
        static let ink = SwiftUI.Color("ink")
        /// Primary action, key figure, progress fill #2753B9
        static let accent = SwiftUI.Color("accent")
        /// Secondary text, dividers, disabled #575757
        static let muted = SwiftUI.Color("muted")
    }

    /// SF Pro Rounded via Font.system. Six steps. No Font.custom and no bundled NouvelR.
    /// Display is Semibold. Extra-bold is only the Close verb, applied in CloseStyle.
    enum Font {
        static let face = "SF Pro"

        static var display: SwiftUI.Font {
            .system(.largeTitle, design: .rounded).weight(.semibold)
        }

        static var title: SwiftUI.Font {
            .system(.title2, design: .rounded).weight(.semibold)
        }

        static var headline: SwiftUI.Font {
            .system(.headline, design: .rounded).weight(.semibold)
        }

        static var body: SwiftUI.Font {
            .system(.body, design: .rounded)
        }

        static var caption: SwiftUI.Font {
            .system(.subheadline, design: .rounded)
        }

        static var micro: SwiftUI.Font {
            .system(.caption, design: .rounded)
        }
    }

    enum Spacing {
        static let unit: CGFloat = 8
        static let tap: CGFloat = 44
        static let hairline: CGFloat = 1

        static func n(_ count: Int) -> CGFloat {
            unit * CGFloat(count)
        }
    }

    enum Radius {
        static let card: CGFloat = 28
        static let chip: CGFloat = 14
    }

    enum Measure {
        static let readable: CGFloat = 560
        static let artBand: CGFloat = 420
        static let timeline: CGFloat = 88
    }
}

extension View {
    func remontoireFill(_ radius: CGFloat = RemontoireLook.Radius.card) -> some View {
        background(RemontoireLook.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(RemontoireLook.Color.muted.opacity(0.35), lineWidth: RemontoireLook.Spacing.hairline)
            )
    }

    func remontoireReadable(_ width: CGFloat = RemontoireLook.Measure.readable) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
