import AppKit
import SwiftUI

@MainActor
final class OverlayWindowManager {
    private(set) var panel: NSPanel?

    func installIfNeeded(state: LyricsOverlayState) {
        guard panel == nil else { return }

        let rootView = LyricsOverlayRootView(state: state)
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 286, height: 76),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.contentViewController = hostingController

        self.panel = panel
        applyCollectionBehavior(hideInFullScreen: state.settings.hideInFullScreen)
    }

    func show() {
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func applyCollectionBehavior(hideInFullScreen: Bool) {
        let base: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary]
        panel?.collectionBehavior = hideInFullScreen ? base : base.union(.fullScreenAuxiliary)
    }

    func position(using state: LyricsOverlayState, animated: Bool) {
        guard let panel, let screen = NSScreen.main else { return }

        let layout = state.layout
        let targetSize = state.isExpanded ? layout.expandedSize : CGSize(width: layout.collapsedWidth, height: layout.collapsedHeight)
        let x = screen.frame.midX - targetSize.width / 2
        let y = screen.frame.maxY - targetSize.height
        let frame = NSRect(origin: CGPoint(x: x, y: y), size: targetSize)

        if animated {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = state.settings.reduceMotion ? 0.18 : 0.42
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.26, 1)
            panel.animator().setFrame(frame, display: true)
            NSAnimationContext.endGrouping()
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    func containsMouseLocation() -> Bool {
        guard let panel else { return false }
        return panel.frame.contains(NSEvent.mouseLocation)
    }
}
