import SwiftUI

/// Role: BeatMark. Sheet of BeatMarks plus LostMarks, week ratio, and streak. Stock List.
struct Dashboard: View {
    var store: RemontoireStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if store.hasHabit == false {
                    emptyPage(
                        image: "skf_EmptyList",
                        title: "No habit yet.",
                        line: "Close the first ring, then the week will gather here."
                    )
                } else if rows.isEmpty {
                    emptyPage(
                        image: "skf_EmptyList",
                        title: "No closed days yet.",
                        line: "Close today's ring. Marks will land here."
                    )
                } else {
                    populated
                }
            }
            .background(RemontoireLook.Color.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(RemontoireLook.Color.background)
    }

    private var populated: some View {
        List {
            Section {
                hero
                    .listRowInsets(
                        EdgeInsets(
                            top: RemontoireLook.Spacing.n(2),
                            leading: RemontoireLook.Spacing.n(3),
                            bottom: RemontoireLook.Spacing.n(1),
                            trailing: RemontoireLook.Spacing.n(3)
                        )
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            if let warning = store.warning {
                Section {
                    errorRow(warningLine(warning))
                }
            } else if store.lastWriteError != nil {
                Section {
                    errorRow("The last save did not finish. Try again.")
                }
            }
            Section {
                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: RemontoireLook.Spacing.n(2)) {
                        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(1)) {
                            Text(row.title)
                                .font(RemontoireLook.Font.headline)
                                .foregroundStyle(RemontoireLook.Color.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(row.subtitle)
                                .font(RemontoireLook.Font.caption)
                                .foregroundStyle(RemontoireLook.Color.muted)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: RemontoireLook.Spacing.n(1))
                        VStack(alignment: .trailing, spacing: RemontoireLook.Spacing.n(1)) {
                            Text(row.mark)
                                .font(RemontoireLook.Font.headline)
                                .foregroundStyle(RemontoireLook.Color.ink)
                                .lineLimit(1)
                            Text(row.when)
                                .font(RemontoireLook.Font.caption)
                                .foregroundStyle(RemontoireLook.Color.muted)
                                .lineLimit(1)
                        }
                        .layoutPriority(1)
                    }
                    .padding(RemontoireLook.Spacing.n(2))
                    .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.tap, alignment: .leading)
                    .contentShape(Rectangle())
                    .remontoireFill()
                    .accessibilityElement(children: .combine)
                    .listRowInsets(
                        EdgeInsets(
                            top: RemontoireLook.Spacing.n(1),
                            leading: RemontoireLook.Spacing.n(3),
                            bottom: RemontoireLook.Spacing.n(1),
                            trailing: RemontoireLook.Spacing.n(3)
                        )
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } header: {
                Text("Closed days")
                    .font(RemontoireLook.Font.caption)
                    .foregroundStyle(RemontoireLook.Color.muted)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, RemontoireLook.Spacing.n(2), for: .scrollContent)
        .remontoireReadable()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(1)) {
            Text(RemontoireFigure.ratio(completed: reading.completed, scheduled: reading.scheduled))
                .font(typeSize.isAccessibilitySize ? RemontoireLook.Font.title : RemontoireLook.Font.display)
                .foregroundStyle(RemontoireLook.Color.ink)
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
            Text("closed of scheduled")
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(1)
            Text(RemontoireFigure.streak(reading.streak))
                .font(RemontoireLook.Font.headline)
                .foregroundStyle(RemontoireLook.Color.ink)
                .monospacedDigit()
                .lineLimit(1)
            Text(hueLine)
                .font(RemontoireLook.Font.caption)
                .foregroundStyle(RemontoireLook.Color.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(RemontoireLook.Spacing.n(3))
        .frame(maxWidth: .infinity, minHeight: RemontoireLook.Spacing.n(16), alignment: .leading)
        .background {
            Image("skf_CardBackdrop")
                .resizable()
                .scaledToFill()
                .clipped()
                .accessibilityHidden(true)
        }
        .clipped()
        .remontoireFill()
    }

    private func emptyPage(image: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: RemontoireLook.Spacing.n(2)) {
            Text(title)
                .font(RemontoireLook.Font.title)
                .foregroundStyle(RemontoireLook.Color.ink)
                .lineLimit(2)
            Rectangle()
                .fill(RemontoireLook.Color.ink)
                .frame(height: RemontoireLook.Spacing.hairline)
            Text(line)
                .font(RemontoireLook.Font.body)
                .foregroundStyle(RemontoireLook.Color.muted)
            if store.lastWriteError != nil {
                errorRow("The last save did not finish. Try again.")
            }
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Button("Close today's ring") {
                dismiss()
            }
            .buttonStyle(CloseStyle())
        }
        .padding(.horizontal, RemontoireLook.Spacing.n(3))
        .padding(.bottom, RemontoireLook.Spacing.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func errorRow(_ text: String) -> some View {
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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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
            .accessibilityLabel("Close dashboard")
        }
    }

    private var reading: ArborReading {
        store.reading()
    }

    private var hueLine: String {
        switch store.hue() {
        case .sparse:
            return "Ended weeks: sparse. This week does not color until it ends."
        case .steady:
            return "Ended weeks: steady. This week does not color until it ends."
        case .solid:
            return "Ended weeks: solid. This week does not color until it ends."
        }
    }

    private func warningLine(_ warning: ArborWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "Restored from a backup on this device."
        case .startedEmpty:
            return "The week could not be read. Try again."
        }
    }

    private var rows: [MarkRow] {
        var items: [MarkRow] = []
        items.append(contentsOf: store.beatMarks.map { MarkRow(key: $0.palletKey, kind: .beat) })
        items.append(contentsOf: store.lostMarks.map { MarkRow(key: $0.palletKey, kind: .lost) })
        items.sort { $0.key > $1.key }
        return items
    }
}

private struct MarkRow: Identifiable {
    enum Kind {
        case beat
        case lost
    }

    var key: PalletKey
    var kind: Kind
    var id: String { "\(kind)-\(key.rawValue)" }

    var title: String {
        RemontoireFigure.weekdayName(key)
    }

    var subtitle: String {
        switch kind {
        case .beat:
            return "Closed that day."
        case .lost:
            return "Mended miss. Still counts."
        }
    }

    var mark: String {
        RemontoireFigure.markWord(closed: kind == .beat)
    }

    var when: String {
        RemontoireFigure.relativeDay(key)
    }
}
