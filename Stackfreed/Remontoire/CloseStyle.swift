import SwiftUI

/// Role: Remontoire. Primary close control. Default, pressed, disabled, and loading. Mend never uses this accent.
struct CloseStyle: ButtonStyle {
    var isLoading: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled && !isLoading
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(RemontoireLook.Color.background)
            }
            configuration.label
                .opacity(isLoading ? 0 : 1)
        }
        .font(RemontoireLook.Font.title.weight(.heavy))
        .foregroundStyle(labelColor)
        .frame(maxWidth: .infinity)
        .frame(minHeight: RemontoireLook.Spacing.tap)
        .padding(.horizontal, RemontoireLook.Spacing.n(2))
        .background(fillColor(pressed: pressed))
        .clipShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous)
                .stroke(borderColor, lineWidth: RemontoireLook.Spacing.hairline)
        )
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(RemontoireMotion.press, value: pressed)
        .contentShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous))
    }

    private var labelColor: Color {
        if isEnabled {
            return RemontoireLook.Color.background
        }
        return RemontoireLook.Color.muted
    }

    private var borderColor: Color {
        if isEnabled {
            return RemontoireLook.Color.accent
        }
        return RemontoireLook.Color.muted.opacity(0.35)
    }

    private func fillColor(pressed: Bool) -> Color {
        if !isEnabled {
            return RemontoireLook.Color.muted.opacity(0.2)
        }
        if pressed {
            return RemontoireLook.Color.accent.opacity(0.82)
        }
        return RemontoireLook.Color.accent
    }
}

/// Role: Remontoire. Quiet chip for Dashboard, Settings, and mend. Not the live-verb accent.
struct QuietStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RemontoireLook.Font.headline)
            .foregroundStyle(isEnabled ? RemontoireLook.Color.ink : RemontoireLook.Color.muted)
            .frame(minWidth: RemontoireLook.Spacing.tap, minHeight: RemontoireLook.Spacing.tap)
            .padding(.horizontal, RemontoireLook.Spacing.n(2))
            .background(
                isEnabled
                    ? (configuration.isPressed ? RemontoireLook.Color.surface.opacity(0.7) : RemontoireLook.Color.surface)
                    : RemontoireLook.Color.surface.opacity(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RemontoireLook.Radius.chip, style: .continuous)
                    .stroke(RemontoireLook.Color.muted.opacity(0.35), lineWidth: RemontoireLook.Spacing.hairline)
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1)
            .animation(RemontoireMotion.press, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.chip, style: .continuous))
    }
}

/// Role: Remontoire. Pressed state for chrome, caps, and icon-only controls.
struct ChromeStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(RemontoireMotion.press, value: configuration.isPressed)
    }
}
