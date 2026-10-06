import SwiftUI

/// Role: LostBeat. Twist page. Spend grace only on a day that already slipped. Surface also lives on Rings.
struct LostBeatPage: View {
    var store: RemontoireStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var mending = false
    @State private var notice: String?
    @State private var commits = 0

    var body: some View {
        NavigationStack {
            Group {
                if store.hasHabit == false {
                    emptyPage
                } else {
                    populated
                }
            }
            .background(RemontoireLook.Color.background.ignoresSafeArea())
            .navigationTitle("Lost beat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(RemontoireLook.Font.headline)
                            .foregroundStyle(RemontoireLook.Color.ink)
                            .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChromeStyle())
                    .accessibilityLabel("Close lost beat")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(RemontoireLook.Color.background)
        .sensoryFeedback(.impact(weight: .medium), trigger: commits)
    }

    private var emptyPage: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            Text(RemontoireVoice.noHabit)
                .font(mastheadFont)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
            Rectangle()
                .fill(RemontoireLook.Color.ink)
                .frame(height: RemontoireLook.Spacing.hairline)
            Text(RemontoireVoice.nameHabitFirst)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
            if store.lastWriteError != nil {
                errorBand("The last save did not finish. Try again.")
            }
            Image("skf_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Button("Close the first ring") {
                dismiss()
            }
            .buttonStyle(CloseStyle())
        }
        .padding(.horizontal, RemontoireLook.Spacing.n(3))
        .padding(.bottom, RemontoireLook.Spacing.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
                Image("skf_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: RemontoireLook.Spacing.n(22))
                    .clipped()
                    .accessibilityHidden(true)
                Text("Mend a silent day.")
                    .font(mastheadFont)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Rectangle()
                    .fill(RemontoireLook.Color.ink)
                    .frame(height: RemontoireLook.Spacing.hairline)
                Text(RemontoireVoice.twistHow)
                    .font(RemontoireLook.Font.body)
                    .foregroundStyle(RemontoireLook.Color.muted)
                statusCard
                if let notice {
                    errorBand(notice)
                } else if store.lastWriteError != nil {
                    errorBand("The last save did not finish. Try again.")
                }
                Button("Back to Rings") {
                    dismiss()
                }
                .buttonStyle(QuietStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, RemontoireLook.Spacing.n(3))
            .padding(.bottom, RemontoireLook.Spacing.n(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            Text(store.lostBeat.remains ? "This week still holds a lost beat." : "This week already spent its lost beat.")
                .font(RemontoireLook.Font.headline)
                .foregroundStyle(RemontoireLook.Color.ink)
            if silentDays.isEmpty {
                Text(store.lostBeat.remains ? RemontoireVoice.noSilentDay : "Wait for the week to turn. An unused lost beat drops then.")
                    .font(RemontoireLook.Font.body)
                    .foregroundStyle(RemontoireLook.Color.muted)
            } else {
                ForEach(silentDays, id: \.self) { day in
                    Button {
                        mendDay(day)
                    } label: {
                        HStack {
                            Text(WeekCanvas.dayName(day))
                                .font(RemontoireLook.Font.body)
                                .foregroundStyle(RemontoireLook.Color.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: RemontoireLook.Spacing.n(1))
                            Text("Mend")
                                .font(RemontoireLook.Font.headline)
                                .foregroundStyle(RemontoireLook.Color.ink)
                                .layoutPriority(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietStyle())
                    .disabled(mending || !store.lostBeat.remains)
                    .accessibilityLabel("Mend \(WeekCanvas.dayName(day))")
                }
            }
        }
        .padding(RemontoireLook.Spacing.n(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .remontoireFill()
    }

    private func errorBand(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: RemontoireLook.Spacing.n(2)) {
            Text(text)
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Try again") {
                Task { await store.load() }
            }
            .buttonStyle(QuietStyle())
        }
        .padding(RemontoireLook.Spacing.n(2))
        .remontoireFill()
    }

    private var silentDays: [Int] {
        store.folded().mendable.map(\.rawValue)
    }

    private var mastheadFont: Font {
        typeSize.isAccessibilitySize ? RemontoireLook.Font.title : RemontoireLook.Font.display
    }

    private func mendDay(_ day: Int) {
        guard !mending else { return }
        mending = true
        takeFold(WeekCanvas.mend(store, day: day))
        mending = false
    }

    private func takeFold(_ outcome: RemontoireOutcome) {
        notice = RemontoireVoice.afterMend(outcome)
        if RemontoireVoice.committed(outcome) {
            commits += 1
        }
    }
}
