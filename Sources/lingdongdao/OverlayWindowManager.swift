import AppKit
import SwiftUI
import Combine

@MainActor
final class OverlayWindowManager {
    private var panels: [NSPanel] = []
    private var screenChangeCancellable: AnyCancellable?

    func installIfNeeded(state: LyricsOverlayState) {
        syncPanels(state: state)
        
        // Listen for screen changes
        if screenChangeCancellable == nil {
            screenChangeCancellable = NotificationCenter.default
                .publisher(for: NSApplication.didChangeScreenParametersNotification)
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.syncPanels(state: state)
                    self.position(using: state, animated: false)
                }
        }
    }

    private func syncPanels(state: LyricsOverlayState) {
        let screens = NSScreen.screens
        
        // If we have more panels than screens, remove excess
        while panels.count > screens.count {
            let panel = panels.removeLast()
            panel.orderOut(nil)
            panel.contentViewController = nil
        }
        
        // If we have fewer panels than screens, add missing
        while panels.count < screens.count {
            let panel = createPanel(state: state)
            panels.append(panel)
        }
        
        // Ensure all panels have the right collection behavior
        applyCollectionBehavior(hideInFullScreen: state.settings.hideInFullScreen)
    }

    private func createPanel(state: LyricsOverlayState) -> NSPanel {
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
        panel.hasShadow = false
        panel.isOpaque = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentViewController = hostingController
        
        return panel
    }

    func show() {
        for panel in panels {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        for panel in panels {
            panel.orderOut(nil)
        }
    }

    func applyCollectionBehavior(hideInFullScreen: Bool) {
        let base: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary]
        let behavior = hideInFullScreen ? base : base.union(.fullScreenAuxiliary)
        for panel in panels {
            panel.collectionBehavior = behavior
        }
    }

    func position(using state: LyricsOverlayState, animated: Bool) {
        let screens = NSScreen.screens
        guard panels.count == screens.count else {
            syncPanels(state: state)
            position(using: state, animated: animated)
            return
        }

        for (index, screen) in screens.enumerated() {
            let panel = panels[index]
            let layout = state.layout
            let targetSize = CGSize(width: layout.collapsedWidth, height: layout.collapsedHeight)
            let sf = screen.frame
            let vf = screen.visibleFrame  // excludes menu bar and dock

            // Horizontal
            let edgeInset: CGFloat = 20
            let x: CGFloat
            switch state.settings.horizontalAnchor {
            case .leading:
                x = sf.minX + edgeInset
            case .center:
                x = sf.minX + (sf.width - targetSize.width) / 2
            case .trailing:
                x = sf.maxX - targetSize.width - edgeInset
            }

            // Vertical
            let y: CGFloat
            switch state.settings.verticalAnchor {
            case .top:
                // Flush with the top of the screen to blend into the notch/Dynamic Island
                y = sf.maxY - targetSize.height
            case .center:
                y = sf.minY + (sf.height - targetSize.height) / 2
            case .bottom:
                // Right above the Dock (or screen edge on external monitors)
                y = vf.minY + edgeInset
            }

            let frame = NSRect(origin: CGPoint(x: x, y: y), size: targetSize)

            if animated {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = state.settings.reduceMotion ? 0.18 : 0.32
                NSAnimationContext.current.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.26, 1)
                panel.animator().setFrame(frame, display: true)
                NSAnimationContext.endGrouping()
            } else {
                panel.setFrame(frame, display: true)
            }
        }
    }
}
