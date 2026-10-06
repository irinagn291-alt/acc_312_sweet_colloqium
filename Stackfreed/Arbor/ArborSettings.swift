import SwiftUI

/// Role: Arbor. Edit the habit and scheduled weekdays. Contact, re-run, reset.
struct ArborSettings: View {
    var store: RemontoireStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var name = ""
    @State private var days: Set<Int> = ArborDraft.weekdays()
    @State private var confirmReset = false
    @State private var skipPersist = false
    @State private var saves = 0
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let wide = sizeClass == .regular && geo.size.width >= 700
                ScrollView {
                    Group {
                        if wide {
                            HStack(alignment: .top, spacing: RemontoireLook.Spacing.n(3)) {
                                formColumn
                                    .frame(maxWidth: 440)
                                previewColumn
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            formColumn
                                .remontoireReadable()
                        }
                    }
                    .padding(.horizontal, RemontoireLook.Spacing.n(3))
                    .padding(.top, RemontoireLook.Spacing.n(2))
                    .padding(.bottom, RemontoireLook.Spacing.n(3))
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(RemontoireLook.Color.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        persistIfNeeded()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(RemontoireLook.Font.headline)
                            .foregroundStyle(RemontoireLook.Color.ink)
                            .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChromeStyle())
                    .accessibilityLabel("Close settings")
                }
            }
            .onAppear {
                name = store.habitName
                days = store.habitWeekdays
            }
            .onDisappear {
                guard !skipPersist else { return }
                persistIfNeeded()
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: saves)
            .confirmationDialog(
                "Reset all local marks?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    skipPersist = true
                    Task { await store.resetAllData() }
                }
                Button("Keep marks", role: .cancel) {}
            } message: {
                Text("Closed days, mended days, and the habit leave this device.")
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(RemontoireLook.Color.background)
    }

    private var formColumn: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            if store.hasHabit == false {
                Text("No habit yet. Name it, pick the weekdays, then save.")
                    .font(RemontoireLook.Font.body)
                    .foregroundStyle(RemontoireLook.Color.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(RemontoireLook.Spacing.n(2))
                    .remontoireFill()
            }

            fieldLabel("Habit")
            TextField("Habit name", text: $name)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.ink)
                .focused($nameFocused)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit { nameFocused = false }
                .padding(RemontoireLook.Spacing.n(2))
                .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
                .remontoireFill()

            fieldLabel("Scheduled weekdays")
            weekdayGrid

            if store.lastWriteError != nil {
                HStack(alignment: .firstTextBaseline, spacing: RemontoireLook.Spacing.n(2)) {
                    Text("The last save did not finish. Try again.")
                        .font(RemontoireLook.Font.caption)
                        .foregroundStyle(RemontoireLook.Color.ink)
                    Button("Try again") {
                        Task { await store.flush() }
                    }
                    .buttonStyle(QuietStyle())
                }
                .padding(RemontoireLook.Spacing.n(2))
                .remontoireFill()
            }

            Button("Save habit") {
                save()
            }
            .buttonStyle(CloseStyle())
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || days.isEmpty)

            Button("Contact Stackfreed") {
                openURL(RemontoireClient.contactURL)
            }
            .font(RemontoireLook.Font.body)
            .foregroundStyle(RemontoireLook.Color.accent)
            .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, RemontoireLook.Spacing.n(2))
            .remontoireFill()
            .accessibilityLabel("Contact Stackfreed")
            .accessibilityHint("Opens the contact page.")

            Text(RemontoireClient.contactURL.absoluteString)
                .font(RemontoireLook.Font.micro)
                .foregroundStyle(RemontoireLook.Color.muted)

            Button("Re-run onboarding") {
                persistIfNeeded()
                skipPersist = true
                store.reopenOnboarding()
                dismiss()
            }
            .font(RemontoireLook.Font.body)
            .foregroundStyle(RemontoireLook.Color.ink)
            .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, RemontoireLook.Spacing.n(2))
            .remontoireFill()

            Button("Reset all data", role: .destructive) {
                confirmReset = true
            }
            .font(RemontoireLook.Font.body)
            .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, RemontoireLook.Spacing.n(2))
            .remontoireFill()
        }
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            Text("What Save habit will change")
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(1)

            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? store.habitName : name)
                .font(RemontoireLook.Font.title)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("Week rings stay on the home screen. Days you leave off become rest.")
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            capPreview

            fieldLabel("Scheduled weekdays")
            weekdayGrid

            Text(previewLine)
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(RemontoireLook.Spacing.n(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .remontoireFill()
        }
        .padding(RemontoireLook.Spacing.n(3))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .remontoireFill()
    }

    private var capPreview: some View {
        HStack(alignment: .bottom, spacing: RemontoireLook.Spacing.n(1)) {
            ForEach(Array(store.folded().days.enumerated()), id: \.element.key.rawValue) { _, cap in
                ArborCap(day: cap, prominent: cap.isToday) {
                    if cap.isToday {
                        _ = store.beatToday()
                    } else {
                        _ = WeekCanvas.mend(store, day: cap.key.rawValue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weekdayGrid: some View {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let ordered = (0 ..< 7).map { offset in
            ((calendar.firstWeekday - 1 + offset) % 7) + 1
        }
        return HStack(spacing: RemontoireLook.Spacing.n(1)) {
            ForEach(ordered, id: \.self) { day in
                let selected = days.contains(day)
                let title = symbols.indices.contains(day - 1)
                    ? String(symbols[day - 1].prefix(2))
                    : RemontoireFigure.whole(day)
                Button {
                    toggle(day)
                } label: {
                    VStack(spacing: RemontoireLook.Spacing.n(1)) {
                        Image(systemName: selected ? "checkmark" : "circle")
                            .font(RemontoireLook.Font.micro.weight(.semibold))
                            .foregroundStyle(selected ? RemontoireLook.Color.background : RemontoireLook.Color.ink)
                        Text(title)
                            .font(RemontoireLook.Font.micro)
                            .foregroundStyle(selected ? RemontoireLook.Color.background : RemontoireLook.Color.ink)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: RemontoireLook.Spacing.tap)
                    .contentShape(Rectangle())
                    .background(selected ? RemontoireLook.Color.ink : RemontoireLook.Color.background)
                    .clipShape(RoundedRectangle(cornerRadius: RemontoireLook.Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: RemontoireLook.Radius.chip, style: .continuous)
                            .stroke(
                                selected ? RemontoireLook.Color.ink : RemontoireLook.Color.ink,
                                lineWidth: selected ? RemontoireLook.Spacing.hairline * 2 : RemontoireLook.Spacing.hairline
                            )
                    )
                }
                .buttonStyle(ChromeStyle())
                .accessibilityLabel(symbols.indices.contains(day - 1) ? symbols[day - 1] : RemontoireFigure.whole(day))
                .accessibilityValue(selected ? "Scheduled" : "Off")
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(RemontoireLook.Font.caption)
            .foregroundStyle(RemontoireLook.Color.muted)
    }

    private var previewLine: String {
        let count = days.count
        return RemontoireFigure.whole(count) + " weekdays stay scheduled after Save habit."
    }

    private func toggle(_ day: Int) {
        if days.contains(day) {
            if days.count > 1 {
                days.remove(day)
            }
        } else {
            days.insert(day)
        }
    }

    private func persistIfNeeded() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !days.isEmpty else { return }
        if !store.hasHabit || trimmed != store.habitName || days != store.habitWeekdays {
            save()
        }
    }

    private func save() {
        nameFocused = false
        store.saveHabit(name: name, weekdays: days)
        store.markOnboardingComplete()
        saves += 1
    }
}
