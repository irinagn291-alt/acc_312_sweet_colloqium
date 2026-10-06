import SwiftUI

/// Role: Arbor. Home mechanic. Ring row and day timeline never leave. Close and mend fuse here.
struct Rings: View {
    var store: RemontoireStore
    var onDashboard: () -> Void
    var onSettings: () -> Void
    var onLostBeat: () -> Void
    var onCommit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var revealed = false
    @State private var closing = false
    @State private var showSuccess = false
    @State private var notice: String?

    var body: some View {
        Group {
            if store.hasHabit == false {
                emptyPage
            } else {
                ScrollView {
                    populated
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RemontoireLook.Color.background.ignoresSafeArea())
        .onAppear {
            revealed = true
            store.settle()
        }
    }

    private var emptyPage: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            chrome
            Text(RemontoireVoice.noHabit)
                .font(mastheadFont)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Rectangle()
                .fill(RemontoireLook.Color.ink)
                .frame(height: RemontoireLook.Spacing.hairline)
            Text(RemontoireVoice.closeFirst)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
            if let notice {
                errorBand(notice)
            }
            Image("skf_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Button(action: { store.wind(ArborDraft.named()) }) {
                closeLabel(RemontoireVoice.closeFirst)
            }
            .buttonStyle(CloseStyle())
        }
        .padding(.horizontal, RemontoireLook.Spacing.n(3))
        .padding(.top, RemontoireLook.Spacing.n(2))
        .padding(.bottom, RemontoireLook.Spacing.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            chrome
            if !typeSize.isAccessibilitySize {
                headerArt
            }

            Text(store.habitName)
                .font(mastheadFont)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(RemontoireLook.Color.ink)
                .frame(height: RemontoireLook.Spacing.hairline)

            Text(jobLine)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            statLine

            if let notice {
                errorBand(notice)
            } else if let warning = store.warning {
                errorBand(warningLine(warning))
            } else if store.lastWriteError != nil {
                errorBand("The last save did not finish. Try again.")
            }

            Button(action: beat) {
                closeLabel("Close")
            }
            .buttonStyle(CloseStyle())
            .disabled(!store.canBeatToday || closing)
            .accessibilityLabel("Close today's ring")
            .accessibilityHint("Writes a closed mark for today.")

            capRow
            mendTarget
            weekChain
            weekHistory
            lostStrip
        }
        .padding(.horizontal, RemontoireLook.Spacing.n(3))
        .padding(.top, RemontoireLook.Spacing.n(2))
        .padding(.bottom, RemontoireLook.Spacing.n(2))
        .remontoireReadable(720)
        .overlay(alignment: .top) {
            if showSuccess {
                Image("skf_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: RemontoireLook.Spacing.n(8), height: RemontoireLook.Spacing.n(8))
                    .padding(RemontoireLook.Spacing.n(2))
                    .remontoireFill(RemontoireLook.Radius.chip)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
    }

    private var headerArt: some View {
        Image("skf_HeaderDecor")
            .resizable()
            .scaledToFit()
            .aspectRatio(2, contentMode: .fit)
            .frame(maxWidth: RemontoireLook.Measure.artBand)
            .frame(maxWidth: .infinity)
            .clipped()
            .accessibilityHidden(true)
    }

    private var weekChain: some View {
        WeekCanvas(
            store: store,
            reduceTravel: reduceMotion,
            onBeat: beat,
            onFold: { takeFold($0) }
        )
        .frame(maxWidth: .infinity)
        .frame(height: RemontoireLook.Measure.timeline)
        .clipShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous)
                .stroke(RemontoireLook.Color.muted.opacity(0.35), lineWidth: RemontoireLook.Spacing.hairline)
        )
        .background(
            RemontoireLook.Color.surface
                .clipShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.card, style: .continuous))
        )
        .opacity(revealed ? 1 : 0)
        .animation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade, value: revealed)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day chain")
    }

    private var mendTarget: some View {
        let folded = store.folded()
        let target = folded.mendable.first
        return Button {
            if let target {
                takeFold(WeekCanvas.mend(store, day: target.rawValue))
            } else {
                onLostBeat()
            }
        } label: {
            VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(1)) {
                Text("Mend target")
                    .font(RemontoireLook.Font.caption)
                    .foregroundStyle(RemontoireLook.Color.muted)
                    .lineLimit(1)
                if let target {
                    Text(RemontoireFigure.weekdayName(target))
                        .font(RemontoireLook.Font.headline)
                        .foregroundStyle(RemontoireLook.Color.ink)
                        .lineLimit(1)
                    Text(RemontoireVoice.lostHeld)
                        .font(RemontoireLook.Font.caption)
                        .foregroundStyle(RemontoireLook.Color.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else if store.lostBeat.remains {
                    Text(RemontoireVoice.noSilentDay)
                        .font(RemontoireLook.Font.headline)
                        .foregroundStyle(RemontoireLook.Color.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(RemontoireVoice.lostSpent)
                        .font(RemontoireLook.Font.headline)
                        .foregroundStyle(RemontoireLook.Color.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(RemontoireLook.Spacing.n(2))
            .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
            .remontoireFill()
        }
        .buttonStyle(ChromeStyle())
        .accessibilityLabel(target == nil ? "Lost beat" : "Mend that day")
    }

    private var weekHistory: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(1)) {
            Text("This week")
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(1)
            ForEach(store.folded().days, id: \.key.rawValue) { day in
                Button {
                    if day.isToday {
                        beat()
                    } else {
                        takeFold(WeekCanvas.mend(store, day: day.key.rawValue))
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: RemontoireLook.Spacing.n(2)) {
                        Text(RemontoireFigure.weekdayName(day.key))
                            .font(RemontoireLook.Font.headline)
                            .foregroundStyle(RemontoireLook.Color.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: RemontoireLook.Spacing.n(1))
                        Text(historyWord(day))
                            .font(RemontoireLook.Font.caption)
                            .foregroundStyle(RemontoireLook.Color.muted)
                            .lineLimit(1)
                    }
                    .padding(RemontoireLook.Spacing.n(2))
                    .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
                    .contentShape(Rectangle())
                    .remontoireFill()
                }
                .buttonStyle(ChromeStyle())
                .accessibilityLabel("\(RemontoireFigure.weekdayName(day.key)), \(historyWord(day))")
            }
        }
    }

    private func historyWord(_ day: FoldedPallet) -> String {
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

    private var chrome: some View {
        HStack(spacing: RemontoireLook.Spacing.n(1)) {
            Text("This week")
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(1)
            Spacer(minLength: RemontoireLook.Spacing.n(1))
            Button(action: onDashboard) {
                Image(systemName: "list.bullet")
                    .font(RemontoireLook.Font.headline)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
                    .contentShape(Rectangle())
                    .remontoireFill(RemontoireLook.Radius.chip)
            }
            .buttonStyle(ChromeStyle())
            .accessibilityLabel("Dashboard")
            Button(action: onLostBeat) {
                Image(systemName: "arrow.uturn.backward")
                    .font(RemontoireLook.Font.headline)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
                    .contentShape(Rectangle())
                    .remontoireFill(RemontoireLook.Radius.chip)
            }
            .buttonStyle(ChromeStyle())
            .accessibilityLabel("Lost beat")
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(RemontoireLook.Font.headline)
                    .foregroundStyle(RemontoireLook.Color.ink)
                    .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
                    .contentShape(Rectangle())
                    .remontoireFill(RemontoireLook.Radius.chip)
            }
            .buttonStyle(ChromeStyle())
            .accessibilityLabel("Settings")
        }
    }

    private var capRow: some View {
        HStack(alignment: .bottom, spacing: RemontoireLook.Spacing.n(1)) {
            ForEach(Array(store.folded().days.enumerated()), id: \.element.key.rawValue) { index, cap in
                ArborCap(day: cap, prominent: cap.isToday) {
                    if cap.isToday {
                        beat()
                    } else {
                        takeFold(WeekCanvas.mend(store, day: cap.key.rawValue))
                    }
                }
                .opacity(revealed ? 1 : 0)
                .animation(RemontoireMotion.stagger(index: index, reduceMotion: reduceMotion), value: revealed)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statLine: some View {
        let reading = store.reading()
        return HStack(alignment: .firstTextBaseline, spacing: RemontoireLook.Spacing.n(2)) {
            Text(RemontoireFigure.ratio(completed: reading.completed, scheduled: reading.scheduled))
                .font(RemontoireLook.Font.headline)
                .foregroundStyle(RemontoireLook.Color.ink)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
            Text("this week")
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: RemontoireLook.Spacing.n(1))
            Text(RemontoireFigure.streak(reading.streak))
                .font(RemontoireLook.Font.headline)
                .foregroundStyle(RemontoireLook.Color.ink)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var lostStrip: some View {
        Button(action: onLostBeat) {
            HStack(alignment: .center, spacing: RemontoireLook.Spacing.n(2)) {
                Image("skf_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: RemontoireLook.Spacing.n(6), height: RemontoireLook.Spacing.n(6))
                    .clipped()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(1)) {
                    Text(store.lostBeat.remains ? "Lost beat held" : "Lost beat spent")
                        .font(RemontoireLook.Font.headline)
                        .foregroundStyle(RemontoireLook.Color.ink)
                        .lineLimit(1)
                    Text(lostLine)
                        .font(RemontoireLook.Font.caption)
                        .foregroundStyle(RemontoireLook.Color.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(RemontoireLook.Font.caption)
                    .foregroundStyle(RemontoireLook.Color.muted)
                    .accessibilityHidden(true)
            }
            .padding(RemontoireLook.Spacing.n(2))
            .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
            .remontoireFill()
        }
        .buttonStyle(ChromeStyle())
        .accessibilityLabel("Lost beat")
        .accessibilityHint("Opens the mend page.")
    }

    private func closeLabel(_ title: String) -> some View {
        HStack(spacing: RemontoireLook.Spacing.n(2)) {
            Image("skf_ControlFace")
                .resizable()
                .scaledToFit()
                .frame(width: RemontoireLook.Spacing.n(4), height: RemontoireLook.Spacing.n(4))
                .clipped()
                .accessibilityHidden(true)
            Text(title)
        }
    }

    private var jobLine: String {
        if store.canBeatToday {
            return RemontoireVoice.jobCloseToday
        }
        if store.folded().days.contains(where: { $0.isToday && $0.remontoire == nil }) {
            return RemontoireVoice.jobRest
        }
        if store.lostBeat.remains, !store.folded().mendable.isEmpty {
            return RemontoireVoice.jobMendPast
        }
        if store.lostBeat.remains {
            return RemontoireVoice.jobHoldsBeat
        }
        return RemontoireVoice.jobSpent
    }

    private var lostLine: String {
        store.lostBeat.remains ? RemontoireVoice.lostHeld : RemontoireVoice.lostSpent
    }

    private var mastheadFont: Font {
        typeSize.isAccessibilitySize ? RemontoireLook.Font.title : RemontoireLook.Font.display
    }

    private func warningLine(_ warning: ArborWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "Restored from a backup on this device."
        case .startedEmpty:
            return "The week could not be read. Try again, or close a first ring."
        }
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
            .accessibilityLabel("Try again")
        }
        .padding(RemontoireLook.Spacing.n(2))
        .remontoireFill()
    }

    private func beat() {
        guard !closing else { return }
        closing = true
        takeFold(store.beatToday(), closingToday: true)
        closing = false
    }

    private func takeFold(_ outcome: RemontoireOutcome, closingToday: Bool = false) {
        notice = closingToday ? RemontoireVoice.afterBeat(outcome) : RemontoireVoice.afterMend(outcome)
        if RemontoireVoice.committed(outcome) {
            flashSuccess()
        }
    }

    private func flashSuccess() {
        onCommit()
        withAnimation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade) {
            showSuccess = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade) {
                showSuccess = false
            }
        }
    }
}
