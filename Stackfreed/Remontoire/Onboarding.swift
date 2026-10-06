import SwiftUI

/// Role: Remontoire. Three pages. Skip writes a first week. Re-runnable from Settings.
struct Onboarding: View {
    var store: RemontoireStore
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var page = 0
    @State private var name = ArborDraft.name
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            HStack {
                Spacer(minLength: 0)
                Button("Skip") {
                    finish(skipped: true)
                }
                .buttonStyle(QuietStyle())
                .accessibilityLabel("Skip onboarding")
            }

            pageBody
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: RemontoireLook.Spacing.n(1)) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? RemontoireLook.Color.ink : RemontoireLook.Color.muted.opacity(0.35))
                        .frame(width: index == page ? RemontoireLook.Spacing.n(3) : RemontoireLook.Spacing.n(1), height: RemontoireLook.Spacing.n(1))
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(RemontoireFigure.whole(page + 1)) of \(RemontoireFigure.whole(3))")

            Button(page == 2 ? "Close the first ring" : "Continue") {
                nameFocused = false
                if page < 2 {
                    withAnimation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade) {
                        page += 1
                    }
                } else {
                    finish(skipped: false)
                }
            }
            .buttonStyle(CloseStyle())
        }
        .padding(.horizontal, RemontoireLook.Spacing.n(3))
        .padding(.top, RemontoireLook.Spacing.n(2))
        .padding(.bottom, RemontoireLook.Spacing.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RemontoireLook.Color.background.ignoresSafeArea())
        .onAppear {
            name = store.habitName
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var pageBody: some View {
        switch page {
        case 0:
            pageOne
        case 1:
            pageTwo
        default:
            pageThree
        }
    }

    private var pageOne: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
                art("skf_Onboarding1", bounded: true)
                Text("The week still holds.")
                    .font(mastheadFont)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("Close today first. A miss does not have to zero the week.")
                    .font(RemontoireLook.Font.body)
                    .foregroundStyle(RemontoireLook.Color.muted)
                TextField("Habit name", text: $name)
                    .font(RemontoireLook.Font.body)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .padding(RemontoireLook.Spacing.n(2))
                    .frame(minHeight: RemontoireLook.Spacing.tap)
                    .remontoireFill(RemontoireLook.Radius.chip)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { nameFocused = false }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var pageTwo: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            art("skf_Onboarding2")
            Text("Tap today's ring.")
                .font(mastheadFont)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("One press closes today and fills that day's ring.")
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
        }
    }

    private var pageThree: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            art("skf_Onboarding3")
            Text("Mend a day that slipped.")
                .font(mastheadFont)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Text(RemontoireVoice.onboardingMend)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
        }
    }

    private func art(_ name: String, bounded: Bool = false) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(minHeight: RemontoireLook.Spacing.n(22), maxHeight: bounded ? RemontoireLook.Spacing.n(36) : .infinity)
            .clipped()
            .accessibilityHidden(true)
    }

    private var mastheadFont: Font {
        typeSize.isAccessibilitySize ? RemontoireLook.Font.title : RemontoireLook.Font.display
    }

    private func finish(skipped: Bool) {
        nameFocused = false
        if store.hasHabit == false {
            store.wind(ArborDraft.named(skipped ? ArborDraft.name : name))
        } else if !skipped {
            store.renameHabit(name)
        }
        store.markOnboardingComplete()
        onFinished()
    }
}
