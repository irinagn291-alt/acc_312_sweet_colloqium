import SpriteKit
import SwiftUI

/// Role: Pallet. The only SpriteView. Clay pallet nodes for this week. Taps call beatToday and mendPallet.
@MainActor
final class PalletTimelineScene: SKScene {
    private var folded = FoldedArbor(pallets: [], canBeatToday: false, mendable: [])

    override func didMove(to view: SKView) {
        view.allowsTransparency = false
        backgroundColor = UIColor(RemontoireLook.Color.surface)
        render()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        render()
    }

    func apply(_ folded: FoldedArbor) {
        self.folded = folded
        render()
    }

    private func render() {
        removeAllChildren()
        guard size.width > 1, size.height > 1 else { return }

        let rule = SKShapeNode(rectOf: CGSize(width: size.width - RemontoireLook.Spacing.n(4), height: RemontoireLook.Spacing.hairline))
        rule.fillColor = UIColor(RemontoireLook.Color.ink)
        rule.strokeColor = .clear
        rule.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rule.zPosition = 0
        addChild(rule)

        let pallets = folded.pallets
        guard !pallets.isEmpty else { return }
        let slot = size.width / CGFloat(pallets.count)
        let maxRadius = min(slot * 0.38, size.height * 0.28)

        for (index, pallet) in pallets.enumerated() {
            let radius = pallet.isToday ? maxRadius : maxRadius * 0.78
            let node = SKShapeNode(circleOfRadius: radius)
            node.position = CGPoint(x: slot * (CGFloat(index) + 0.5), y: size.height / 2)
            node.lineWidth = RemontoireLook.Spacing.hairline * (pallet.isToday ? 2 : 1)
            node.zPosition = 1
            paint(node, pallet: pallet)
            addChild(node)

            if pallet.remontoire == .mended {
                let seam = SKShapeNode(rectOf: CGSize(width: radius * 1.4, height: RemontoireLook.Spacing.n(1)))
                seam.fillColor = UIColor(RemontoireLook.Color.ink)
                seam.strokeColor = .clear
                seam.position = node.position
                seam.zPosition = 2
                addChild(seam)
            }

            if pallet.remontoire == .beaten {
                let stamp = SKShapeNode(circleOfRadius: radius * 0.28)
                stamp.fillColor = UIColor(RemontoireLook.Color.background)
                stamp.strokeColor = .clear
                stamp.position = node.position
                stamp.zPosition = 2
                addChild(stamp)
            }
        }
    }

    private func paint(_ node: SKShapeNode, pallet: FoldedPallet) {
        let ink = UIColor(RemontoireLook.Color.ink)
        let accent = UIColor(RemontoireLook.Color.accent)
        let surface = UIColor(RemontoireLook.Color.surface)
        let muted = UIColor(RemontoireLook.Color.muted)
        switch pallet.remontoire {
        case .beaten:
            node.fillColor = accent
            node.strokeColor = ink
        case .mended:
            node.fillColor = surface
            node.strokeColor = ink
        case .open:
            node.fillColor = surface
            node.strokeColor = pallet.isToday ? accent : ink
        case nil:
            node.fillColor = surface
            node.strokeColor = muted
            node.alpha = 0.45
        }
        if pallet.isFuture {
            node.alpha = min(node.alpha, 0.5)
        }
    }
}

/// Role: Pallet. SwiftUI host for the week timeline. SpriteKit does not travel when Reduce Motion is on.
struct PalletTimeline: View {
    var folded: FoldedArbor
    var reduceTravel: Bool
    var onBeat: () -> Void
    var onMend: (PalletKey) -> Void

    @State private var scene = PalletTimelineScene()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: scene)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transaction { transaction in
                        if reduceTravel {
                            transaction.disablesAnimations = true
                        }
                    }

                HStack(spacing: 0) {
                    ForEach(Array(folded.pallets.enumerated()), id: \.element.key.rawValue) { _, pallet in
                        Button {
                            act(pallet)
                        } label: {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(ChromeStyle())
                        .accessibilityLabel(label(for: pallet))
                        .accessibilityHint(hint(for: pallet))
                    }
                }
            }
            .onAppear {
                layout(geo.size)
            }
            .onChange(of: geo.size) { _, size in
                layout(size)
            }
            .onChange(of: folded) { _, next in
                scene.apply(next)
            }
        }
    }

    private func layout(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.apply(folded)
    }

    private func act(_ pallet: FoldedPallet) {
        if pallet.isToday {
            onBeat()
        } else {
            onMend(pallet.key)
        }
    }

    private func label(for pallet: FoldedPallet) -> String {
        let day = RemontoireFigure.weekdayName(pallet.key)
        let state = stateWord(pallet)
        return "\(day), \(state)"
    }

    private func hint(for pallet: FoldedPallet) -> String {
        if pallet.isToday, pallet.remontoire == .open {
            return "Closes today."
        }
        if pallet.isPast, pallet.remontoire == .open {
            return "Spends this week's lost beat."
        }
        if pallet.isFuture {
            return "Future days refuse."
        }
        return "That day is rest."
    }

    private func stateWord(_ pallet: FoldedPallet) -> String {
        switch pallet.remontoire {
        case .beaten:
            return "Closed"
        case .mended:
            return "Mended"
        case .open:
            return pallet.isFuture ? "Soon" : "Open"
        case nil:
            return "Rest"
        }
    }
}

/// Rings hosts this strip. PalletTimeline stays the SpriteKit surface and calls mendPallet.
struct WeekCanvas: View {
    var store: RemontoireStore
    var reduceTravel: Bool
    var onBeat: () -> Void
    var onFold: (RemontoireOutcome) -> Void

    var body: some View {
        PalletTimeline(
            folded: store.folded(),
            reduceTravel: reduceTravel,
            onBeat: onBeat,
            onMend: { key in
                onFold(store.mendPallet(key))
            }
        )
    }

    static func mend(_ store: RemontoireStore, day: Int, now: Date = Date()) -> RemontoireOutcome {
        store.mendPallet(PalletKey(rawValue: day), now: now)
    }

    static func dayName(_ day: Int, calendar: Calendar = .current) -> String {
        RemontoireFigure.weekdayName(PalletKey(rawValue: day), calendar: calendar)
    }
}
