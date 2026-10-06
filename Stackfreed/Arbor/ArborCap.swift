import SwiftUI

/// Role: Arbor. One week cap in the ring row. Shape plus word. Colour is never the only signal.
struct ArborCap: View {
    var day: FoldedPallet
    var prominent: Bool = false
    var action: () -> Void

    @ScaledMetric(relativeTo: .body) private var baseCap: CGFloat = 44

    var body: some View {
        Button(action: action) {
            VStack(spacing: RemontoireLook.Spacing.n(1)) {
                ZStack {
                    Circle()
                        .fill(fill)
                    Circle()
                        .stroke(stroke, lineWidth: day.isToday ? RemontoireLook.Spacing.hairline * 2 : RemontoireLook.Spacing.hairline)
                    if day.remontoire == .beaten {
                        Circle()
                            .fill(RemontoireLook.Color.background)
                            .frame(width: cap * 0.28, height: cap * 0.28)
                    }
                    if day.remontoire == .mended {
                        Capsule()
                            .fill(RemontoireLook.Color.ink)
                            .frame(width: cap * 0.62, height: RemontoireLook.Spacing.n(1))
                    }
                }
                .frame(width: cap, height: cap)

                Text(RemontoireFigure.weekdayLetter(day.key))
                    .font(RemontoireLook.Font.micro)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(stateWord)
                    .font(RemontoireLook.Font.micro)
                    .foregroundStyle(RemontoireLook.Color.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .opacity(day.isFuture || day.remontoire == nil ? 0.5 : 1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: RemontoireLook.Spacing.tap)
            .contentShape(Rectangle())
        }
        .buttonStyle(ChromeStyle())
        .accessibilityLabel(accessibilityName)
        .accessibilityHint(hint)
    }

    private var cap: CGFloat {
        prominent ? baseCap + RemontoireLook.Spacing.n(2) : baseCap
    }

    private var fill: Color {
        switch day.remontoire {
        case .beaten:
            return RemontoireLook.Color.accent
        case .mended, .open:
            return RemontoireLook.Color.surface
        case nil:
            return RemontoireLook.Color.surface
        }
    }

    private var stroke: Color {
        if day.remontoire == nil {
            return RemontoireLook.Color.muted
        }
        if day.isToday, day.remontoire == .open {
            return RemontoireLook.Color.accent
        }
        return RemontoireLook.Color.ink
    }

    private var stateWord: String {
        switch day.remontoire {
        case .beaten:
            return "Closed"
        case .mended:
            return "Mended"
        case .open:
            return day.isFuture ? "Soon" : "Open"
        case nil:
            return "Rest"
        }
    }

    private var accessibilityName: String {
        "\(RemontoireFigure.weekdayName(day.key)), \(stateWord)"
    }

    private var hint: String {
        if day.isToday, day.remontoire == .open {
            return "Closes today."
        }
        if day.isPast, day.remontoire == .open {
            return "Spends this week's lost beat."
        }
        if day.isFuture {
            return "Future days refuse."
        }
        return "That day is rest."
    }
}
