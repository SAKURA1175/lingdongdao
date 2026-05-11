import AppKit
import Combine

@MainActor
final class LyricsOverlayController: NSResponder {
    let state: LyricsOverlayState

    private let coordinator: OverlayCoordinator
    private let windowManager: OverlayWindowManager
    private var cancellables: Set<AnyCancellable> = []
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    init(
        state: LyricsOverlayState,
        coordinator: OverlayCoordinator,
        windowManager: OverlayWindowManager = OverlayWindowManager()
    ) {
        self.state = state
        self.coordinator = coordinator
        self.windowManager = windowManager
    }

    func showWindow() {
        windowManager.installIfNeeded(state: state)
        coordinator.start()
        wireState()
        updateVisibility()
        windowManager.position(using: state, animated: false)
        startHoverMonitoring()
    }

    func stop() {
        coordinator.stop()
    }

    private func wireState() {
        guard cancellables.isEmpty else { return }

        state.presentation.$isExpanded
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.windowManager.position(using: self.state, animated: true)
            }
            .store(in: &cancellables)

        state.settings.$showIsland
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)

        state.settings.$hideInFullScreen
            .removeDuplicates()
            .sink { [weak self] hideInFullScreen in
                self?.windowManager.applyCollectionBehavior(hideInFullScreen: hideInFullScreen)
            }
            .store(in: &cancellables)

        state.objectWillChange
            .sink { [weak self] _ in
                guard let self, self.state.settings.showIsland else { return }
                self.windowManager.position(using: self.state, animated: true)
            }
            .store(in: &cancellables)
    }

    private func updateVisibility() {
        if state.settings.showIsland {
            windowManager.show()
            windowManager.position(using: state, animated: false)
        } else {
            windowManager.hide()
        }
    }

    private func startHoverMonitoring() {
        guard globalMouseMonitor == nil, localMouseMonitor == nil else { return }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.checkMousePosition()
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition()
            return event
        }
    }

    private func checkMousePosition() {
        guard state.settings.showIsland else { return }
        state.handleHoverChange(isInside: windowManager.containsMouseLocation())
    }
}
