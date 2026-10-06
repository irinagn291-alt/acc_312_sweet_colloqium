import SwiftUI

/// Role: Remontoire. Arbor-locked chrome. Rings stay. Dashboard and Settings arrive as sheets.
struct RemontoireChrome: View {
    var store: RemontoireStore

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presented: RemontoireGate.Leaf = .rings
    @State private var reviewLeaf: RemontoireGate.Leaf?
    @State private var reviewOnboarding = false
    @State private var consumedGate = false
    @State private var ready = false
    @State private var slow = false
    @State private var commits = 0

    var body: some View {
        Group {
            if !ready {
                loading
            } else if showOnboarding {
                Onboarding(store: store, onFinished: {
                    reviewOnboarding = false
                    consumeGate()
                })
            } else if let reviewLeaf, reviewLeaf != .rings {
                reviewSurface(reviewLeaf)
            } else {
                Rings(
                    store: store,
                    onDashboard: { presented = .dashboard },
                    onSettings: { presented = .settings },
                    onLostBeat: { presented = .lostBeat },
                    onCommit: { commits += 1 }
                )
            }
        }
        .animation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade, value: ready)
        .animation(reduceMotion ? RemontoireMotion.reduce : RemontoireMotion.fade, value: showOnboarding)
        .sensoryFeedback(.impact(weight: .medium), trigger: commits)
        .sheet(isPresented: sheet(.dashboard)) {
            Dashboard(store: store)
        }
        .sheet(isPresented: sheet(.settings)) {
            ArborSettings(store: store)
        }
        .sheet(isPresented: sheet(.lostBeat)) {
            LostBeatPage(store: store)
        }
        .task {
            await boot()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.settle()
            }
            if phase == .inactive || phase == .background {
                Task { await store.flush() }
            }
        }
        .onChange(of: store.onboardingComplete) { _, done in
            if done {
                consumeGate()
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                store.settle()
            }
        }
    }

    private var showOnboarding: Bool {
        !store.onboardingComplete || reviewOnboarding
    }

    private var loading: some View {
        VStack(spacing: RemontoireLook.Spacing.n(2)) {
            Spacer()
            ProgressView()
                .tint(RemontoireLook.Color.accent)
                .opacity(slow ? 1 : 0)
                .frame(width: RemontoireLook.Spacing.tap, height: RemontoireLook.Spacing.tap)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RemontoireLook.Color.background.ignoresSafeArea())
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !ready {
                slow = true
            }
        }
    }

    private func sheet(_ leaf: RemontoireGate.Leaf) -> Binding<Bool> {
        Binding(
            get: { presented == leaf && ready && !showOnboarding },
            set: { shown in
                presented = shown ? leaf : .rings
            }
        )
    }

    @ViewBuilder
    private func reviewSurface(_ leaf: RemontoireGate.Leaf) -> some View {
        switch leaf {
        case .dashboard:
            Dashboard(store: store)
        case .settings:
            ArborSettings(store: store)
        case .lostBeat:
            LostBeatPage(store: store)
        case .onboarding:
            Onboarding(store: store, onFinished: {
                reviewOnboarding = false
            })
        case .rings:
            Rings(
                store: store,
                onDashboard: { presented = .dashboard },
                onSettings: { presented = .settings },
                onLostBeat: { presented = .lostBeat },
                onCommit: { commits += 1 }
            )
        }
    }

    private func boot() async {
        let spin = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled, !ready {
                slow = true
            }
        }
        await store.load()
        await store.seedDemoIfNeeded()
        store.settle()
        spin.cancel()
        ready = true
        consumeGate()
    }

    private func consumeGate() {
        guard !consumedGate, store.onboardingComplete else { return }
        consumedGate = true
        let leaf = RemontoireGate.consume()
        switch leaf {
        case .rings:
            presented = .rings
            reviewLeaf = nil
        case .dashboard, .settings, .lostBeat:
            reviewLeaf = leaf
            presented = .rings
        case .onboarding:
            reviewOnboarding = true
            reviewLeaf = nil
        }
    }
}
